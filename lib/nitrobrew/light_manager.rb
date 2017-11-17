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
end