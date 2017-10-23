
describe Valve do

  let (:nc_params) { {"name" => "ncName", "id" => "v1", "type" => "NC", "open" => ":P8_7"} }
  let (:powered_params) { {"name" => "poweredName", "id" => "v2", "type" => "powered", "open" => ":P8_7", "closed" => ":P8_8",
                        "sense_open" => ":P8_9", "sense_closed" => ":P8_10"} }

  context "is a NC valve" do
    it "validates its parameters" do
      expect {Valve.new(nc_params)}.not_to raise_error
    end
  
    it "verifies its required parameters" do
      nc_params.keys.each do | param |
        expect {Valve.new(nc_params.merge(param => nil))}.to raise_error("Invalid #{param}")
      end
    end
  end
    
  context "it is a powered valve" do 
    it "it validates its parameters" do
      expect {Valve.new(powered_params)}.not_to raise_error
    end

    it "verifies its required parameters" do
      powered_params.keys.each do | param |
        expect {Valve.new(powered_params.merge(param => nil))}.to raise_error("Invalid #{param}")
      end
    end
  end
    
  context "with invalid type" do
    it "raises an error" do
      expect {Valve.new(nc_params.merge("type" => "wrong"))}.to raise_error("Invalid type")
    end
  end
end