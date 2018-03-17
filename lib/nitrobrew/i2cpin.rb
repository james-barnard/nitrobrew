class I2CPin

  attr_reader :pin, :driver

  def initialize(pin, driver)
    @pin = pin
    @driver = driver
  end

  def digital_write(value)
    puts "i2cpin: b4 driver.write"
    driver.write(pin, value == :HIGH ? 1 : 0)
  end

  def digital_read
   puts "I2CPin does not implement digital read"
   # driver.read(pin) == 1 ? :HIGH : :LOW
  end
end
