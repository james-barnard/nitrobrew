require_relative 'configuration'
require_relative 'utilities'
require_relative 'validator'
require_relative 'i2cdriver'
require 'logger'
include Utilities


class Machine
  ID = 1001
  attr_reader :config, :program
  attr_writer :program

  def initialize(config_file = "config.yml")
    log("machine:initialize", "start", nil)
    logger.level = Logger::DEBUG
    @config = Configuration.new(config_file)
    light_manager.all_off
    sleep 1
    light_manager.all_on
    sleep 1

    # activate_control_pins
    # disable_control_pins

    activate_i2cs
    activate_valves
    activate_switches
  end

  def ready(status = :start)
    on_change(:run, nil) {}
    log("machine:ready", status, nil)
    light_manager.ready_mode(status)

    action = nil
    while !action do
      check_set_program
      action = :run if check_action(:run) && @valid
      light_manager.blink
      sleep 0.333
    end
    sleep 1
    send action
  end

  def run
    on_change(:halt, nil) {}
    log("machine:run", "program starting", program)
    puts "STARTING"
    light_manager.run_mode
    # enable_control_pins

    action = nil
    while !action do
      step_status = stepper.step
      on_change(:step_status, step_status) { log("machine:run", "status", step_status) }
      blink(step_status)
      action = :done if step_status =~ /done$/
      sleep 0.333
      action = :halt if check_action(:halt)
    end
    # disable_control_pins
    send action
  end

  def base_status(status)
    status.split('|').first
  end

  def blink(step_status)
    light_manager.add_blink(:run) if step_status == :pending
    light_manager.remove_blink if step_status == :soaking
    light_manager.blink
  end

  def id
    ID
  end

  def database
    "test.db"
  end

  def halt
    sleep 1
    ready(:paused)
  end

  def done
    log("machine:done", "done", nil)
    puts "DONE\n\n"
    light_manager.add_blink(:done)
    delete_stepper
    neutralize_valves
    ready(:done)
  end

  def neutralize_valves
    valves.each { |id, valve| valve.neutralize }
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
    neutralize_valves

    @valid = Validator.new(program, database, @config.valves).validate
    if @valid == true
      log("machine:change_program", "program selected", program)
      light_manager.on_program_change(program)
      @program = program
    else
      log("machine:change_program", "program invalid", program)
      light_manager.add_blink(program)
    end
  end

  def log(method, label, value)
    logger.info { "#{method}:#{label}: #{value}" }
  end

  def stepper
    @stepper ||= Stepper.new(database, program, self)
  end

  def set_component_state(id, state)
    log("machine:set_component_state", "component_id: #{id.to_s}", state.to_s)
    begin
      valves[id].set_state(state) unless valves[id].nil?
    rescue => e
      log("machine:set_component_state", "#{e.message}", nil)
      raise
    end
  end

  def check_component_state(id)
    return false if valves[id].nil?
    rtn_value = valves[id].in_position?
    if rtn_value == nil
      on_change("component_#{id}".to_sym, rtn_value) { log("machine:check_component_state", "component_id: #{id.to_s}", rtn_value) }
    elsif rtn_value == false
      on_change("component_#{id}".to_sym, rtn_value) { log("machine:check_component_state", "component_id: #{id.to_s}", "has timed out while #{valves[id].current_status}") }
    end
    rtn_value
  end

  private
  def activate_i2cs
    config.i2cs.each do | driver |
      i2cs[driver["id"]] = I2CDriver.new(driver)
    end
  end

  def enable_control_pins
    control_pins.each do | name, gpio |
      trigger = gpio[:trigger].upcase.to_sym
      gpio[:pin].digital_write(trigger)
    end
  end

  def disable_control_pins
    control_pins.each do | name, gpio |
      trigger = gpio[:trigger] == 'low' ? :HIGH : :LOW
      gpio[:pin].digital_write(trigger)
    end
  end

  def check_action(button)
    result = check_button(button)
    return false unless result

    debounce(button, result) { return true }
    false
  end

  def check_button(button)
    return button if switches[button][:pin].digital_read == :HIGH

    false
  end

  def activate_control_pins
    config.control.each do | gpio |
      puts "activating gpio pin: #{gpio['name']}: #{gpio['pin_id']}"
      gpio["pin"] = Beaglebone::GPIOPin.new(gpio["pin_id"].to_sym, :OUT, nil)
      control_pins[gpio["name"].to_sym] = symbolize_keys(gpio)
    end
  end

  def activate_valves
    config.valves.each do | valve |
      id = valve["id"]
      valves[id] = Valve.new(valve.merge("drivers" => i2cs))
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
    #puts "activating switch: #{switch['pin_id']}"
    Beaglebone::GPIOPin.new(switch["pin_id"].to_sym, :IN, :PULLDOWN)
  end

  def control_pins
    @control_pins ||= {}
  end

  def switches
    @switches ||= {}
  end

  def valves
    @valves ||= {}
  end

  def i2cs
    @i2cs ||= {}
  end

  def logger
    @logger ||= Logger.new('log/run.log', 2, 502400)
  end

  def light_manager
    @light_manager ||= LightManager.new(config.lights)
  end
end
