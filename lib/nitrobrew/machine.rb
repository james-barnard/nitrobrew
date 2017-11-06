require_relative 'configuration.rb'
require 'logger'

class Machine
  ID = 1001
  attr_reader :config, :status, :program
  attr_writer :program

  def initialize
    logger.level = Logger::DEBUG
    @config = Configuration.new
    #activate_valves
    activate_switches
  end

  def start
    @status = "offline"
    prog = nil
    while prog.nil? do
      prog = check_set_program
      sleep 1
    end
    @program = prog
    log("stepper:start", "program selected", program)
    ready
  end

  def ready
    @status = "ready"
    action = nil
    while !action do
      action = :run if check_action(:run)
      action ||= :reset if check_action(:reset)
      sleep 1
    end
    send action
  end

  # stepper verifies that we have a program to run, for now
  # if halted, run resumes by starting at current step
  # select pgm increments run counter, so run naturally starts with step one
  # therefore, press halt/reset to start over and halt/run to resume
  def run
    @status = "busy"
    last_status = nil
    action = nil
    while !action do
      action = :halt if check_action(:halt)
      step_status = stepper.step
      log("stepper:run", "step_status", step_status) if step_status != last_status
      last_status = step_status
      action = :done if step_status == :done
      sleep 1
    end
    send action
  end

  def id
    ID
  end

  def database
    "test.db"
  end

  def halt
    # todo log halt first
    ready
  end

  def done
    # todo log that the test_run is done
    # todo deletes the stepper
    start
  end

  def reset
    # todo log that the test_run has been reset
    # todo deletes the stepper
    # check the switch to return to "offline" mode
    #     both the clean and brew buttons should be off
    start
  end


  def check_set_program
  end

  # should this go away?
  def verify_program
  end

  def log(method, label, value)
    logger.info { "#{method}:#{label}: #{value}" }
  end

  def stepper
    @stepper ||= Stepper.new(database, program, self)
  end

  def set_component_state(id, state)
    valves[id].set_state(state)
  end

  def check_component_state(id)
    valves[id].in_position?
  end

  private
  def check_action(button)
    result = check_button(button)
    if @last_button_check == result
      @last_button_check = nil
      return true
    else
      @last_button_check = result
    end
    false
  end

  # checks the button and returns the name of the button if it is pressed, or nil.
  def check_button(button)
  end

  def activate_switches
    config.switches.each do | switch |
      temp_hsh = { "pin_obj" => GPIOPin.new(switch["pin"].to_sym, :IN, :PULLDOWN) }
      switch.merge!(temp_hsh)
      switches[switch["id"]] = symbolize_keys(switch)
    end
  end

  def activate_valves
    config.valves.each do | valve |
      valves[valve["id"]] = Valve.new(valve)
    end
  end

  def switches
    @switches ||= {}
  end

  def valves
    @valves ||= {}
  end

  def logger
    @logger ||= Logger.new('log/run.log', 10, 1024)
  end

  def symbolize_keys(hash)
    hash.inject({}) do | memo, (k,v) |
      memo[k.to_sym] = v
      memo
    end
  end
end
