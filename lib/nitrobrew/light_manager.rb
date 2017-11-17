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

  def symbolize_keys(hash)
    hash.inject({}) do | memo, (k,v) |
      memo[k.to_sym] = v
      memo
    end
  end

  def all_on
    lights.each do | light |
      light[1][:pin].digital_write(:HIGH)
    end
  end

  def on_program_change(program)
    program_lights_off
    light_on(program)
  end

  def ready_mode
    light_off(:run)
    light_on(:ready)
  end

  def run_mode
    light_off(:ready)
    light_on(:run)
  end

  def light_on(light)
    lights[light][:pin].digital_write(:HIGH)
  end

  def light_off(light)
    lights[light][:pin].digital_write(:LOW)
  end

  def program_lights_off
    lights[:brew][:pin].digital_write(:LOW)
    lights[:clean][:pin].digital_write(:LOW)
    lights[:load][:pin].digital_write(:LOW)
  end
end