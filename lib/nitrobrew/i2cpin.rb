class I2CPin

  attr_reader :pin, :driver

  def initialize(pin, driver)
    @pin = pin
    @driver = driver
  end

  def digital_write(value)
    driver.write(pin, value)
  end

  def digital_read
    driver.read(pin)
  end
end