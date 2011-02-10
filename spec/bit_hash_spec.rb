require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BitHash do

  before(:each) do
    @config_map = [
      {
      :name => :air,    # name of option
      :options => 2,    # number of options must be 2 or greater
    },
    {
      :name => :color, 
      :options => ['blue','green','red']    # bit_hash can map arrays of data, the default setting will be the first value in the array
    },
      {
      :name => :body_style, 
      :options => [:sedan,:mini_van,:suv],  # Array values can be anything that can be found using the Array#index function
      :default => :mini_van                 # for arrays the default is any array value
    },
      {
      :name => :transmission,     # name of option
      :options => 6,
      :default => 5               # for numbers the default must be between 0 and the options value
    },
      {
      :name => :min_price,
      :options => (50..100).to_a, # ( just a way to store ranges of numbers)
      :default => 60              # basically any default can be used as long as it is a valid option
    },
      {
      :name => :max_price,

      # intervals of 20 starting at 10000 (just a way to store ranges of numbers)
      :options => (1..5).to_a.map {|n| 10000+(n*20)},

      # you can use :default_index option to reference something in the option arrays but it really isn't suggested, :default take precedence
      :default_index =>  2
    }
    ]
    @config = bit_hash.new(@config_map)
  end

  it "should raise an error if config lacks name" do
    bit_hash.new(@config_map).should_not be_nil
  end

  it "should raise an error if config lacks name" do
    @config_map[0].delete(:name)
    lambda { bit_hash.new(@config_map) }.should raise_error(ArgumentError)
  end

  it "should be able to get keys" do
    @config.keys.should be_a Array
  end

  it "should have load same config" do
    @config.parse_string(@config.to_s).should eql(@config.to_hash)
  end

  it "should output equal it self after being converted and parsed" do
    str = @config.to_s
    @config.save_string(str)
    str.should eql(@config.to_s)
  end

end
