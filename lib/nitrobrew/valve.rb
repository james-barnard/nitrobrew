class Valve
	attr_accessor :id, :name, :action, :open, :close, :sense_open, :sense_closed

	VALID_VALUES =  ["NC", "powered"]

	def initialize(params)
		raise("Invalid type") unless VALID_VALUES.include?(params["type"])
		#@id = id
		#@name = name
		#@action = action
		#@open = open
		#@close = close
		#@sense_open = sense_open
		#@sense_closed = sense_closed
	end
end