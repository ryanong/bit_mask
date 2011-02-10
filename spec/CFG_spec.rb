require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CFG do

  before(:each) do
      @config_map = [
    {
      :name => :air,
      :options => 2,
    },
    {
      :name => :color,
      :options => ['blue','green','red'],
      :default => 'green'
    },
    {
      :name => :price,
      :options => (1..5).to_a.map {|n| 10000+(n*20)}, #intervals of 20 starting at 10000
      :default => 10080
    }
  ]
  @config = CFG.new(@config_map)
  end

  it "should raise an error if config lacks name" do
    CFG.new(@config_map).should be_a Hash
  end

  it "should raise an error if config lacks name" do
    @config_map[0].delete(:name)
    CFG.new(@config_map).should raise_exception(ArgumentError)
  end

  it "should be able to get keys" do
    @config.keys.should be_a Array
  end

  it "should output a string" do
    @config.to_s.should eql("e")
  end
  
end
