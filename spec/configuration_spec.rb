  RSpec.describe Configuration do
    
    let(:config) {Configuration.new}
    let(:invalid_config) do
      "notvalves:
         -  id: v1
            name: Brew Vacuum
            action: powered
            open: p8-3
            close: p8-4
            sense_open: p8-5
            sense_closed: p8-6"
    end

    it "#new loads valve definitions into an array" do
      expect(config.valves).to be_a_kind_of(Array)
    end
  
    it "raises an exception if there are no valves" do
      allow(File).to receive(:open).and_return(invalid_config)
      expect{Configuration.new}.to raise_error("Config file doesn't have valves")
    end

    #could not create an invalid yaml string...
    #it "raises an exception if the yaml is invalid" do
    #  allow(File).to receive(:open).and_return("invalid\n\t :yaml")
    #  expect{Configuration.new}.to raise_error(ArgumentError)
    #end

  end
