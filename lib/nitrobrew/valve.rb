require 'beaglebone'
include Beaglebone

class Valve
	attr_accessor :status, :set_time
	attr_reader :type

	VALID_TYPES 		= ["NC", "powered"]
	VALID_PINS  		= { "NC" 		 => ["open"],
								 		 "powered" => ["open", "close", "sense_open", "sense_closed"] }
	REQUIRED_PARAMS = ["name", "id"]
	TIMEOUT = 3 # seconds

	def initialize(params)
		validate!(params)

		@id     = params["id"]
		@name   = params["name"]
		@type   = params["type"]
		@status = :closed

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
		return true if @type == "NC"
		get_pin("sense_#{current_status}") == :HIGH or timed_out!
	end

	private
	def validate!(params)
		raise("Invalid type") unless VALID_TYPES.include?(params["type"])

		(VALID_PINS[params["type"]] + REQUIRED_PARAMS).each do | param |
			raise("Invalid #{param}") if params[param].nil?
		end

		return true
	end

	def activate_pins(params)
		VALID_PINS[type].each do | key |
			mode = pin_mode(key)
			pins[key] = GPIOPin.new(params[key].to_sym, mode, pullmode(mode))
		end
	end

	def timed_out!
    (Time.now - set_time) > TIMEOUT ? raise("Valve (#{@name}) has timed out: #{Time.now - set_time} seconds") : false 
	end

	def nc_open
		set_pin("open", :HIGH)
	end

	def nc_close
		set_pin("open", :LOW)
	end

	def powered_open
		set_pin("close", :LOW)
		set_pin("open", :HIGH)
	end

	def powered_close
		set_pin("open", :LOW)
		set_pin("close", :HIGH)
	end

	def set_pin(key, value)
		pins[key].digital_write(value)
	end

	def get_pin(key)
		pins[key].digital_read
	end

	def open
		type == "NC" ? nc_open : powered_open
	end

	def closed
		type == "NC" ? nc_close : powered_close
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
		mode == :IN ? :PULLDOWN : nil
	end
end
