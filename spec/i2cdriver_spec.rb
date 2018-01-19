RSpec.describe I2CDriver do
  let(:driver) { I2CDriver.new("A", 0) }
  let(:pin_params) { ["I.A.7", :OUT, nil] }
  let(:device) { double("i2cdevice", write: nil, read: nil) }
  let(:iodir_address) { 0x4902 }


  it "knows its ID" do
    expect(driver.id).to eq("A")
  end
  
  it "knows its buss" do
    expect(driver.buss).to eq(0)
  end

  it "knows its IODIR register" do
    expect(driver.iodir).to eq(0)
  end

  it "knows its GPPU register" do
    expect(driver.gppu).to eq(0)
  end

  it "knows the values in the GPIO register" do
    expect(driver.gpio).to eq(0)
  end

  it "returns a pin when you initialize a pin" do
    allow(driver).to receive(:i2cdevice).and_return(device)
    expect(driver.pin(*pin_params)).to be_a_kind_of(I2CPin)
  end

  it "sets the proper IODIR values when you initialize a pin" do
    allow(driver).to receive(:i2cdevice).and_return(device)
    driver.pin(*pin_params)
    expect(device).to have_received(:write).with(iodir_address, 0)
  end

  it "sets or unsets the appropriate GPIO pin when you write to it" do
    allow(driver).to receive(:i2cdevice).and_return(device)
    expect(driver.gpio).to eq(0)
    driver.write(7, 1)
    expect(driver.gpio).to eq(128)
    driver.write(7, 0)
    expect(driver.gpio).to eq(0)
  end

  it "only changes the written pin"  do
    allow(driver).to receive(:i2cdevice).and_return(device)
    expect(driver.gpio).to eq(0)
    driver.write(7, 1)
    expect(driver.gpio).to eq(128)
    driver.write(6, 1)
    expect(driver.gpio).to eq(192)
    driver.write(7, 0)
    expect(driver.gpio).to eq(64)
  end

end