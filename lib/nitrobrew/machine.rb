require_relative 'configuration.rb'

class Machine
  attr_reader :config, :status

  def initialize
    @config = Configuration.new
    @status = "offline"
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
end
