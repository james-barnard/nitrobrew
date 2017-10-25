require_relative 'configuration.rb'

class Machine
  attr_reader :config, :status

  def initialize
    @config = Configuration.new
    @status = "offline"
    activate_valves
  end

  def id
    1001
  end

  def set_busy
    @status = "busy"
  end

  def set_ready
    @status = "ready"
  end

  private
  def activate_valves
    config.valves.each do | valve |
      valves[valve["id"]] = Valve.new(valve)
    end
  end

  def valves
    @valves ||= {}
  end
end
