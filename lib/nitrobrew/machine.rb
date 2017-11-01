require_relative 'configuration.rb'
require 'logger'

class Machine
  ID = 1001
  attr_reader :config, :status
  attr_accessor :program

  def initialize
    logger.level = Logger::DEBUG
    @config = Configuration.new
    #activate_valves
  end

  def start
    @status = "offline"
    program = nil
    while !program do
      program = check_set_program
      sleep 1
    end
    ready
  end

  def ready
    @status = "ready"
    action = nil
    while !action do
      action = :run if check_action(:run)
      #action ||= :resume if check_action(:resume)
      action ||= :reset if check_action(:reset)
      sleep 1
    end
    send action
  end

  # verifies that we have a program to run,
  # if halted, run resumes by starting at current step
  # select pgm increments run counter, so run naturally starts with step one
  # therefore, press halt/reset to start over and halt/run to resume
  def run
    @status = "busy"
    verify_program
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
    start
  end


  def check_set_program
  end

  def verify_program
  end

  def log(method, label, value)
    logger.info { "#{method}:#{label}: #{value}" }
  end

  def stepper
    @stepper ||= Stepper.new(database, program, self)
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

  def activate_valves
    config.valves.each do | valve |
      valves[valve["id"]] = Valve.new(valve)
    end
  end

  def valves
    @valves ||= {}
  end
   def logger
     @logger ||= Logger.new('log/run.log', 10, 1024)
   end
end
