describe Valve do

  let (:i2cdriver_a) { double("i2cdriver_a", i2cpin: double("fake_i2cpin1")) }
  let (:i2cdriver_b) { double("i2cdriver_b", i2cpin: double("fake_i2cpin2", :digital_write => nil)) }
  let (:i2cs) { {"A" => i2cdriver_a, "B" => i2cdriver_b} }
  let (:nc_params) {    {"name" => "ncName", "id" => "v1", "type" => "NC", "open" => "P8_7", "trigger" => "high", "drivers" => i2cs} }
  let (:nc_params_low)  { {"name" => "ncName", "id" => "v1", "type" => "NC", "open" => "P8_7", "trigger" => "low", "drivers" => i2cs} }
  let (:powered_params) { {"name" => "poweredName", "id" => "v2", "type" => "powered", "open" => "I.B.4", "close" => "P8_8",
                           "sense_open" => "P8_9", "sense_closed" => "P8_10", "trigger" => "high", "drivers" => i2cs} }
  let (:fake_pin)       { double("GPIOPin") }
  let (:nc_valve)     { Valve.new(nc_params) }
  let (:nc_valve_low) { Valve.new(nc_params_low) }

  context "is a NC valve" do
    
    it "validates its parameters" do
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      expect {nc_valve}.not_to raise_error
    end

    it "verifies its required parameters" do
      (Valve::VALID_PINS[nc_params["type"]] + Valve::REQUIRED_PARAMS).each do | param |
        expect {Valve.new(nc_params.merge(param => nil))}.to raise_error("Invalid #{param}")
      end
    end

    context "it has a GPIOPin" do
      it "activates its pin" do
        allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
        expect(nc_valve.send(:pins)["open"]).to be_an_instance_of(GPIOPin)
      end
    end

    context "it has an I2CPin" do
      let (:nc_params) { {"name" => "ncName", "id" => "v1", "type" => "NC", "open" => "I.B.4", "trigger" => "high", "drivers" => i2cs} }
      it "activates its pin" do
        expect(nc_valve.send(:pins)["open"]).to_not be_nil
      end
    end

    it "sets its state" do
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      nc_valve.set_state(:open)
      expect(nc_valve.current_status).to eq(:open)
    end

    it "returns true if its position is checked" do
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      expect(nc_valve.in_position?).to be true
    end

    it "writes :LOW to open when trigger is set to low" do
      allow(GPIOPin).to receive(:new).and_return(fake_pin)
      allow(nc_valve_low).to receive(:set_pin)
      nc_valve_low.send(:nc_open)
      expect(nc_valve_low).to have_received(:set_pin).with("open", :LOW)
    end

    it "writes :HIGH to open when trigger is set to high" do
      allow(GPIOPin).to receive(:new).and_return(fake_pin)
      allow(nc_valve).to receive(:set_pin)
      nc_valve.send(:nc_open)
      expect(nc_valve).to have_received(:set_pin).with("open", :HIGH)
    end

    it "sets the proper pullmode when trigger is high" do
      allow(GPIOPin).to receive(:new).and_return(fake_pin)
      Valve.new(nc_params)
      expect(GPIOPin).to have_received(:new).with(:P8_7, :OUT, nil)
    end

    it "sets the proper pullmode when trigger is low" do
      allow(GPIOPin).to receive(:new).and_return(fake_pin)
      Valve.new(nc_params_low)
      expect(GPIOPin).to have_received(:new).with(:P8_7, :OUT, nil)
    end
  end

  context "it is a powered valve" do
    let (:powered_valve) { Valve.new(powered_params) }

    it "it validates its parameters" do
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      expect {powered_valve}.not_to raise_error
    end

    it "verifies its required parameters" do
      allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
      (Valve::VALID_PINS[powered_params["type"]] + Valve::REQUIRED_PARAMS).each do | param |
        expect {Valve.new(powered_params.merge(param => nil))}.to raise_error("Invalid #{param}")
      end
    end
    
    it "activates its pins" do
      allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
      Valve::VALID_PINS["powered"][1..2].each do | pin |
        expect(powered_valve.send(:pins)[pin]).to be_an_instance_of(GPIOPin)
      end
      expect(powered_valve.send(:pins)["open"]).to_not be_nil
    end

    context "when checking position" do
      it "returns nil if state is not achieved" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:LOW)
        powered_valve.set_time = Time.now
        expect(powered_valve.in_position?).to be nil
      end

      it "returns true if state is achieved" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:HIGH)
        allow(powered_valve).to receive(:neutralize)
        expect(powered_valve.in_position?).to be true
      end

      it "raises an error if the time elapsed has been too long" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:LOW)
        powered_valve.set_time = Time.now - Valve::TIMEOUT
        expect {powered_valve.in_position?}.to output(/^Valve \(\w+\) has timed out: \d+\.\d+ seconds$/).to_stdout
      end

      it "does not raise an error if the time elapsed isn't too long" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:LOW)
        powered_valve.set_time = Time.now
        expect {powered_valve.in_position?}.to_not raise_error
      end
    end

    it "can read an input pin" do
      allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
      expect(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read)
      powered_valve.set_time = Time.now
      powered_valve.in_position?
    end

    it "can write to an output pin" do
      allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
      expect(powered_valve.send(:pins)["open"]).to receive(:digital_write).with(:HIGH)
      powered_valve.set_state("open")
    end
  end

  context "with invalid type" do
    it "raises an error" do
      expect {Valve.new(nc_params.merge("type" => "wrong"))}.to raise_error("Invalid type")
    end
  end

  context "when activating I2CPins" do
    it "selects the right I2CDriver" do
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      expect(nc_valve.send(:select_driver, "I.B.4")).to eq(i2cdriver_b)
    end
  end
end
