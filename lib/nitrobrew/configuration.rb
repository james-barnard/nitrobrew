require 'debugger'
require 'yaml'

class Configuration 
	attr_reader :valves

	def initialize
		begin 
			data = YAML.load(File.open("config.yml"))
		rescue ArgumentError => e
			puts "Could not parse YAML: #{e.message}"
		end
		@valves = data['valves'] || raise("Config file doesn't have valves")
	end
end