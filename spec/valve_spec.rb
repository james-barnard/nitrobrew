
describe Valve do

  let (:nc_params) { {"name" => "ncName", "id" => "v1", "type" => "NC", "open" => "P8_7"} }
  let (:powered_params) { {"name" => "poweredName", "id" => "v2", "type" => "powered", "open" => "P8_7", "close" => "P8_8",
                        "sense_open" => "P8_9", "sense_closed" => "P8_10"} }

  context "is a NC valve" do
    let (:nc_valve) { Valve.new(nc_params) }

    it "validates its parameters" do
      expect {nc_valve}.not_to raise_error
    end
  
    it "verifies its required parameters" do
      nc_params.keys.each do | param |
        expect {Valve.new(nc_params.merge(param => nil))}.to raise_error("Invalid #{param}")
      end
    end

    it "activates its pin" do
      expect(nc_valve.send(:pins)["open"]).to be_an_instance_of(GPIOPin)
    end

    it "sets its state" do
      nc_valve.set_state(:open)
      expect(nc_valve.current_status).to eq(:open)
    end
  end
    
  context "it is a powered valve" do 
    let (:powered_valve) { Valve.new(powered_params) }

    it "it validates its parameters" do
      expect {powered_valve}.not_to raise_error
    end

    it "verifies its required parameters" do
      powered_params.keys.each do | param |
        expect {Valve.new(powered_params.merge(param => nil))}.to raise_error("Invalid #{param}")
      end
    end

    it "activates its pins" do
      Valve::VALID_PINS["powered"].each do | pin |
        expect(powered_valve.send(:pins)[pin]).to be_an_instance_of(GPIOPin)
      end
    end

    context "when checking position" do
      it "returns false if state is not achieved" do
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:LOW)
        powered_valve.set_time = Time.now
        expect(powered_valve.in_position?).to be false
      end

      it "returns true if state is achieved" do
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:HIGH)
        expect(powered_valve.in_position?).to be true
      end

      it "raises an error if the time elapsed has been too long" do
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:LOW)
        powered_valve.set_time = Time.now - Valve::TIMEOUT
        expect {powered_valve.in_position?}.to raise_error(/^Valve \(\w+\) has timed out: \d+\.\d+ seconds$/)
      end

      it "does not raise an error if the time elapsed isn't too long" do
        allow(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read).and_return(:LOW)
        powered_valve.set_time = Time.now
        expect {powered_valve.in_position?}.to_not raise_error
      end
    end

    it "can read an input pin" do
      expect(powered_valve.send(:pins)["sense_closed"]).to receive(:digital_read)
      powered_valve.set_time = Time.now
      powered_valve.in_position?
    end

    it "can write to an output pin" do
      expect(powered_valve.send(:pins)["open"]).to receive(:digital_write).with(:HIGH)
      powered_valve.set_state("open")
    end
  end  

  context "with invalid type" do
    it "raises an error" do
      expect {Valve.new(nc_params.merge("type" => "wrong"))}.to raise_error("Invalid type")
    end
  end
end