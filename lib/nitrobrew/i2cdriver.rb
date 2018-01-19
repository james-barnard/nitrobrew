class I2CDriver

  attr_reader :id, :buss, :iodir, :gppu, :gpio

  def initialize(id, buss)
    @id = id
    @buss = buss
    @iodir = 0
    @gppu = 0
    @gpio = 0
  end

  def pin(address, mode, pullmode)
    bit = address.split('.')[2].to_i
    set_iodir(bit, mode)
    I2CPin.new(bit, self)
  end

  def set_iodir(bit, mode)
    addr = device_address(:IODIR)
    value = mode == :IN ? 1 : 0
    data = twiddle_bit(iodir, bit, value)
    i2cdevice.write(addr, data)
    @iodir = data
  end

  def i2cdevice
    @i2cdevice ||= I2CDevice.new(:I2C2)
  end

  def device_address(register)
    0x4902
  end

  def twiddle_bit(byte, bit, value)
    if value == 1
      byte | (1 << bit)
    else
      byte & ~(1 << bit)
    end
  end

  def write(bit, value)
    addr = device_address(:GPIO)
    data = twiddle_bit(gpio, bit, value)
    i2cdevice.write(addr, data)
    @gpio = data
  end

end