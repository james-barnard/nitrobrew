require 'beaglebone'
require_relative 'i2cpin'

class I2CDriver
  IODIR = 0x00
  GPIO  = 0x09

  attr_reader :id, :bus, :addr, :iodir, :gppu, :gpio

  def initialize(params)
    @id    = params["id"]
    @bus   = params["bus"].to_sym
    @addr  = params["addr"]
    @gpio  = @gpio_default = params["gpio_default"]
    @iodir = 0
    @gppu  = 0
  end

  def pin(address, mode, pullmode)
    bit = address.split('.')[2].to_i
    set_iodir(bit, mode)
    I2CPin.new(bit, self)
  end

  def set_iodir(bit, mode)
    value = mode == :IN ? 1 : 0
    @iodir = twiddle_bit(iodir, bit, value)
    puts "set_iodir: b4 i2cdevice.write"
    i2cdevice.write(addr, [IODIR, iodir].pack("C*"))
  rescue Errno::EREMOTEIO, Errno::EAGAIN, Errno::ETIMEDOUT => e
    puts "I2CDriver: set_iodir: retry: ERROR: #{e.inspect}"
    sleep(0.2); print('.')
    retry unless (tries -= 1).zero?
    raise "I2CDriver write error"
  end

  def i2cdevice
    @i2cdevice ||= Beaglebone::I2CDevice.new(bus)
  end

  def twiddle_bit(byte, bit, value)
    if value == 1
      byte | (1 << bit)
    else
      byte & ~(1 << bit)
    end
  end

  def write(bit, value)
    tries ||= 6
    @gpio = twiddle_bit(gpio, bit, value)
    puts "I2CDriver:write: b4 i2cdevice.write"
    i2cdevice.write(addr, [GPIO, gpio].pack("C*"))
  rescue Errno::EREMOTEIO, Errno::EAGAIN, Errno::ETIMEDOUT => e
    puts "I2CDriver: retry: write: ERROR: #{e.inspect}"
    sleep(0.2); print('.')
    retry unless (tries -= 1).zero?
    raise "I2CDriver write error"
  end
end
