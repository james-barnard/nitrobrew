describe LightManager do
  GPIOPin = Beaglebone::GPIOPin

  let (:real_config) { Configuration.new }
  let (:real_manager) { LightManager.new(real_config.lights) }
  let (:test_manager) { LightManager.new(test_params) }
  let (:test_params) do
    [ {"name" => "brew",  "pin_id" => "P8_26"},
      {"name" => "clean", "pin_id" => "P8_27"},
      {"name" => "load",  "pin_id" => "P8_28"},
      {"name" => "ready", "pin_id" => "P8_29"},
      {"name" => "run",   "pin_id" => "P8_30"},
      {"name" => "done",  "pin_id" => "P8_31"} ]
  end

  describe "#initialize" do
    it "uses the config file" do
      allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
      expect(real_manager.send(:lights)[:brew][:pin]).to be_an_instance_of(GPIOPin)
      expect(real_manager.send(:lights).keys.sort).to eq([:brew, :clean, :done, :load, :ready, :run])
    end

    it "activates the GPIOPins for the lights" do
      allow(Beaglebone::GPIO).to receive(:pin_mode).and_return(nil)
      expect(test_manager.send(:lights)[:brew][:pin]).to be_an_instance_of(GPIOPin)
    end
  end

  context "with fake pin" do
    before(:each) {
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
    }

    it "turns on all the lights for testing" do
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:ready][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:run][:pin]).to receive(:digital_write)

      test_manager.all_on

      expect(test_manager.lights[:brew][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
      expect(test_manager.lights[:clean][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
      expect(test_manager.lights[:load][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
      expect(test_manager.lights[:ready][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
      expect(test_manager.lights[:run][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
    end

    it "can turn off all the lights" do
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:ready][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:run][:pin]).to receive(:digital_write)

      test_manager.all_off

      expect(test_manager.lights[:brew][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:clean][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:load][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:ready][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:run][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
    end

    it "has a hash containing its lights" do
      expect(test_manager.send(:lights).keys.sort).to eq([:brew, :clean, :done, :load, :ready, :run])
    end
  end

  describe "#on_program_change" do
    before(:each) {
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
    }

    it "turns all the program lights off" do
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)

      test_manager.program_lights_off

      expect(test_manager.lights[:brew][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:clean][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:load][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
    end

    it "lights up only the brew light" do
      allow(test_manager).to receive(:program_lights_off)
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)

      test_manager.on_program_change(:brew)

      expect(test_manager).to have_received(:program_lights_off)
      expect(test_manager.lights[:brew][:pin]).to have_received(:digital_write).with(:HIGH).once
    end

    it "lights up only the clean light" do
      allow(test_manager).to receive(:program_lights_off)
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)

      test_manager.on_program_change(:clean)

      expect(test_manager).to have_received(:program_lights_off)
      expect(test_manager.lights[:clean][:pin]).to have_received(:digital_write).with(:HIGH).once
    end

    it "lights up only the load light" do
      allow(test_manager).to receive(:program_lights_off)
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)

      test_manager.on_program_change(:load)

      expect(test_manager).to have_received(:program_lights_off)
      expect(test_manager.lights[:load][:pin]).to have_received(:digital_write).with(:HIGH).once
    end

    it "stops program selection lights from blinking" do
      allow(test_manager).to receive(:program_lights_off)
      allow(test_manager).to receive(:remove_blink)
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:clean][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:load][:pin]).to receive(:digital_write)
      

      test_manager.on_program_change(:brew)

      expect(test_manager).to have_received(:remove_blink)
    end
  end

  describe "indicates the state of the machine" do
    before(:each) {
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
    }

    it "lights up the ready light when ready" do
      allow(test_manager.lights[:ready][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:run][:pin]).to receive(:digital_write)

      test_manager.ready_mode(:start)

      expect(test_manager.lights[:ready][:pin]).to have_received(:digital_write).with(:HIGH).once
      expect(test_manager.lights[:run][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
    end

    it "lights up the run light when running" do
      allow(test_manager.lights[:ready][:pin]).to receive(:digital_write)
      allow(test_manager.lights[:run][:pin]).to receive(:digital_write)

      test_manager.run_mode

      expect(test_manager.lights[:ready][:pin]).to have_received(:digital_write).with(:LOW).at_least(:once)
      expect(test_manager.lights[:run][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
    end

    it "lights up the ready light when we are paused" do
      allow(test_manager.lights[:ready][:pin]).to receive(:digital_write)
      
      test_manager.ready_mode(:paused)

      expect(test_manager.lights[:ready][:pin]).to have_received(:digital_write).with(:HIGH).at_least(:once)
    end

    it "blinks the run light when we are paused" do
        allow(test_manager).to receive(:add_blink).with(:run)

        test_manager.ready_mode(:paused)

        expect(test_manager).to have_received(:add_blink).with(:run)
      end
    
    it "can blink a light" do
      allow(test_manager.lights[:brew][:pin]).to receive(:digital_write)

      test_manager.blink
      test_manager.add_blink(:brew)
      test_manager.blink
      sleep 2
      test_manager.blink

      expect(test_manager.lights[:brew][:pin]).to have_received(:digital_write).with(:HIGH).once
      expect(test_manager.lights[:brew][:pin]).to have_received(:digital_write).with(:LOW).once
    end
  end
end
