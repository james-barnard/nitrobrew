require_relative 'configuration.rb'

class Machine
  ID = 1001
  attr_reader :config, :status
  attr_accessor :program

  def initialize
    @config = Configuration.new
    activate_valves
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
      action ||= :start if check_action(:reset)
      sleep 1
    end
    send action
  end

  #verifies that we have a program to run,
  def run
    @status = "busy"
    verify_program
    stepper = Stepper.new(program)
    last_status = nil
    action = nil
    while !action do
      action = :halt if check_action(:halt)
      step_status = stepper.step
      log("run", "step_status", step_status) if step_status != last_status
      last_status = step_status
      action = :done if step_status == :done
      sleep 1
    end
    send action
  end

  def id
    ID
  end

  private
  def check_action(button)
    result = check_action(button)
    if @last_button_check == result
      @last_button_check = nil
      return true
    else
    @last_button_check = result
    end
  end

  def activate_valves
    config.valves.each do | valve |
      valves[valve["id"]] = Valve.new(valve)
    end
  end

  def valves
    @valves ||= {}
  end
end
