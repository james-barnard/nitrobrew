RSpec.describe I2CPin do
  let (:driver) { double("i2cdriver_b", write: nil, read: nil) }
  let (:i2cpin) { I2CPin.new(4, driver) }

  describe "#new" do
    it "knows its pin number" do
      expect(i2cpin.pin).to eq(4)
    end
    
    it "knows its driver" do
      expect(i2cpin.driver).to eq(driver)
    end
  end
  
  describe "#digital_write" do
    it "calls write on its driver" do
      i2cpin.digital_write(:HIGH)

      expect(driver).to have_received(:write).with(4, 1)
    end
  end
end