require_relative 'utilities.rb'
include Utilities

class LightManager

  def initialize(params)
    activate_lights(params)
  end

  def lights
    @lights ||= {}
  end

  def activate_lights(params)
    params.each do | light |
      light["pin"] = activate_light_pin(light)
      lights[light["name"].to_sym] = symbolize_keys(light)
    end
  end

  def activate_light_pin(light)
    GPIOPin.new(light["pin_id"].to_sym, :OUT)
  end 

  def all_on
    lights.keys.each do | light_key |
      light_on(light_key)
    end
  end

  def on_program_change(program)
    program_lights_off
    light_on(program)
  end

  def ready_mode(status)
    status == :paused ? light_on(:run) : light_off(:run)
    light_on(:ready)
  end

  def run_mode
    light_off(:ready)
    light_on(:run)
  end

  def light_on(light_key)
    lights[light_key][:pin].digital_write(:HIGH)
  end

  def light_off(light_key)
   lights[light_key][:pin].digital_write(:LOW)
  end

  def program_lights_off
    [:brew, :clean, :load].each { | light_key | light_off(light_key) }
  end
end