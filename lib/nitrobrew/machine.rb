require_relative 'configuration.rb'
require 'logger'

class Machine
  ID = 1001
  attr_reader :config, :status, :program
  attr_writer :program

  def initialize
    log("machine:initialize", "start", nil)
    logger.level = Logger::DEBUG
    @config = Configuration.new
    activate_valves
    activate_switches
  end

  def ready
    log("machine:ready", "start", nil)
    @status = "ready"
    action = nil
    while !action do
      @program = check_set_program
      action = :run if check_action(:run)
      sleep 1
    end
    send action
  end

  def run
    log("machine:run", "program starting", @program)
    @status = "busy"
    last_status = nil
    action = nil
    while !action do
      action = :halt if check_action(:halt)
      step_status = stepper.step
      log("machine:run", "status", step_status) if step_status != last_status
      last_status = step_status
      action = :done if step_status =~ /done$/
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
    log("machine:run", "halted", nil)
    ready
  end

  def done
    # todo log that the test_run is done
    # todo deletes the stepper
    ready
  end

  def check_set_program
    temp_program = if check_button(:clean)
      :clean
    elsif check_button(:brew)
      :brew
    else
      :load
    end

    if temp_program == @last_prog
      temp_program
    else
      @last_prog = temp_program
      @program
    end
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
    return false unless result

    if @last_button_check == result
      @last_button_check = nil
      return true
    else
      @last_button_check = result
    end
    false
  end

  def check_button(button)
    return button if switches[button][:pin].digital_read == :HIGH

    false
  end

  def activate_valves
    config.valves.each do | valve |
      valves[valve["id"]] = Valve.new(valve)
    end
  end

  def activate_switches
    config.switches.each do | switch |
      switch["pin"] = activate_switch_pin(switch)
      switches[switch["name"].to_sym] = symbolize_keys(switch)
    end
  end

  def activate_switch_pin(switch)
    switches.each do | k, v |
      if v[:pin] == switch["pin_id"]
        return v[:pin_obj]
      end
    end
    GPIOPin.new(switch["pin_id"].to_sym, :IN, :PULLDOWN)
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
