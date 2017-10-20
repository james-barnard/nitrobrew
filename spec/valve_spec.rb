
describe Valve do

  let (:nc_valve) {{:type => "NC"}}
  let (:powered) {{:type => "powered"}}


  context "with valid type" do
    
    it "is a NC valve"
    it "is a powered valve"

  end

  context "with invalid type" do

    it "raises an error" do
      expect {Valve.new("type" => "wrong")}.to raise_error("Invalid type")
    end

  end
end