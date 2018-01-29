require 'beaglebone'
require_relative 'i2cpin'
require_relative 'i2cdriver'

class Valve
  attr_accessor :status, :set_time
  attr_reader :type, :trigger

  VALID_TYPES     = ["NC", "powered"]
  VALID_PINS      = { "NC"     => ["open"],
                     "powered" => ["open", "close", "sense_open", "sense_closed"] }
  REQUIRED_PARAMS = ["name", "id", "trigger"]
  TIMEOUT = 10 # seconds
  TRIGGER = {:high => {:open => :HIGH, :close => :LOW},
             :low  => {:open => :LOW,  :close => :HIGH}}

  def initialize(params)
    validate!(params)

    @id      = params["id"]
    @name    = params["name"]
    @type    = params["type"]
    @trigger = params["trigger"].to_sym
    @status  = :closed
    @i2cs    = params["drivers"]

    activate_pins(params)
  end

  # legal states are :open and :closed
  def set_state(state)
    send(state)
    @status   = state
    @set_time = Time.now
  end

  def current_status
    status
  end

  def in_position?
    return true if nc?
    if (get_pin("sense_#{current_status}") == :HIGH)
      neutralize
      true
    elsif timed_out
      neutralize
      false
    end
  end

  private
  def validate!(params)
    raise("Invalid type") unless VALID_TYPES.include?(params["type"])

    (VALID_PINS[params["type"]] + REQUIRED_PARAMS).each do | param |
      raise("Invalid #{param}") if params[param].nil?
    end

    if i2c_pins?(params) && !params["drivers"]
      raise("Missing i2c drivers: valve id: #{params['id']}")
    end

    return true
  end

  def i2c_pins?(params)
    VALID_PINS[params["type"]].any? { |pin| params[pin][0].upcase == "I" }
  end

  def activate_pins(params)
    VALID_PINS[type].each do | key |
      mode = pin_mode(key)
      pins[key] = create_pin(params, key, mode)
    end
  end

  def create_pin(params, key, mode)
    if params[key][0].upcase == "P"
      Beaglebone::GPIOPin.new(params[key].to_sym, mode, pullmode(mode))
    else
      driver = select_driver(params[key])
      driver.pin(params[key], mode, pullmode(mode))
    end
  end

  def select_driver(address)
    key = address.split('.')[1]
    @i2cs[key]
  end

  def neutralize
    set_pin("close", trigger_value(:close))
    set_pin("open", trigger_value(:close))
  end

  def timed_out
    if (Time.now - set_time) > TIMEOUT
      puts("Valve (#{@name}) has timed out: #{Time.now - set_time} seconds")
      return true
    end
    false
  end

  def trigger_value(state)
    TRIGGER[trigger][state]
  end

  def nc_open
    set_pin("open", trigger_value(:open))
  end

  def nc_close
    set_pin("open", trigger_value(:close))
  end

  def powered_open
    set_pin("open", trigger_value(:open))
  end

  def powered_close
    set_pin("close", trigger_value(:close))
  end

  def set_pin(key, value)
    puts "valve:(#{@id},#{@name}-#{@trigger}):set_pin:(#{key},#{value})"
    pins[key].digital_write(value)
  end

  def get_pin(key)
    pins[key].digital_read
  end

  def powered?
    type == 'powered'
  end

  def nc?
    type == 'NC'
  end

  def open
    nc? ? nc_open : powered_open
  end

  def closed
    nc? ? nc_close : powered_close
  end

  def is_open?
    get_pin("sense_open") == :HIGH ? :open : nil
  end

  def pins
    @pins ||= {}
  end

  def pin_mode(pin)
    case pin
    when "open", "close"
      :OUT
    when "sense_open", "sense_closed"
      :IN
    end
  end

  def pullmode(mode)
    puts "mode: #{mode}"
    mode == :IN ? :PULLDOWN : nil
  end
end
