describe LightManager do

  let (:manager) { LightManager.new(params) }
  let (:params) { [{"name" => "brew", "pin_id" => "P8_26"}, {"name" => "clean", "pin_id" => "P8_27"}, {"name" => "load", "pin_id" => "P8_28"}, {"name" => "ready", "pin_id" => "P8_29"}, {"name" => "run", "pin_id" => "P8_30" }] }
  describe "#initialize" do
    it "activates the GPIOPins for the lights" do
      expect(manager.send(:lights).first[1][:pin]).to be_an_instance_of(GPIOPin)
    end

    it "turns on all the lights for testing"
  end
  
  it "has a hash containing its lights" do
    expect(manager.send(:lights).keys.sort).to eq([:brew, :clean, :load, :ready, :run])
  end

  it "indicates which program is selected"

  it "indicates the state of the machine"
end