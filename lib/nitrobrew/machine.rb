require_relative 'configuration.rb'
require_relative 'utilities.rb'
require 'logger'
include Utilities

class Machine
  ID = 1001
  attr_reader :config, :program
  attr_writer :program

  def initialize
    log("machine:initialize", "start", nil)
    logger.level = Logger::DEBUG
    @config = Configuration.new
    light_manager.all_on
    activate_valves
    activate_switches
  end

  def ready(status = :start)
    log("machine:ready", status, nil)
    light_manager.ready_mode(status)

    action = nil
    while !action do
      check_set_program
      action = :run if check_action(:run)
      sleep 1
    end
    send action
  end

  def run
    log("machine:run", "program starting", @program)
    light_manager.run_mode

    action = nil
    while !action do
      action = :halt if check_action(:halt)
      step_status = stepper.step
      on_change(:step_status, step_status) { log("machine:run", "status", step_status) }
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
    ready(:paused)
  end

  def done
    log("machine:done", "done", nil)
    delete_stepper
    ready
  end

  def delete_stepper
    @stepper = nil
  end

  def program_selector
    if check_button(:clean)
      :clean
    elsif check_button(:brew)
      :brew
    else
      :load
    end
  end

  def check_set_program
    temp_program = program_selector
    debounce(:program, temp_program) { change_program(temp_program) }
  end

  def debounce(key, value, &block)
    @debounce_these ||= {}
    if @debounce_these[key] == value
      on_change(key, value, &block)
    else
      @debounce_these[key] = value
    end
  end

  def on_change(key, value, &block)
    @remember_these ||= {}
    if @remember_these[key] != value
      @remember_these[key] = value
      block.call
    end
  end

  def change_program(program)
    delete_stepper
    log("machine:change_program", "program selected", program)
    light_manager.on_program_change(program)
    @program = program
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
    begin
      valves[id].in_position?
    rescue RuntimeError => e
      log("machine:run", "#{e.message}", nil)
      raise
    end
  end

  private
  def check_action(button)
    result = check_button(button)
    return false unless result

    debounce(:button, result) { return true }
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
    @logger ||= Logger.new('log/run.log', 10, 10240)
  end

  def light_manager
    @light_manager ||= LightManager.new(config.lights)
  end
end