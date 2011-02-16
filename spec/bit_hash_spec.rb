require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BitHash do

  before(:each) do
    @config_map = [
      { :name=> 'min_price_cents', :options => [1000000,1500000,2000000,3000000,3500000,4000000,4500000,5000000,5500000,6000000,6500000,7000000] },
      { :name=> 'max_price_cents', :options => [1500000,2000000,3000000,3500000,4000000,4500000,5000000,5500000,6000000,6500000,7000000,8000000] },
      { :name=> 'segment_1', :options => 2},
      { :name=> 'segment_2', :options => 2},
      { :name=> 'segment_3', :options => 2},
      { :name=> 'segment_4', :options => 2},
      { :name=> 'segment_5', :options => 2},
      { :name=> 'segment_6', :options => 2},
      { :name=> 'segment_7', :options => 2},
      { :name=> 'segment_8', :options => 2},
      { :name=> 'segment_9', :options => 2},
      { :name=> 'brand_pref_acura', :options => 3},
      { :name=> 'brand_pref_aston_martin', :options => 3},
      { :name=> 'brand_pref_audi', :options => 3},
      { :name=> 'brand_pref_bentley', :options => 3},
      { :name=> 'brand_pref_bmw', :options => 3},
      { :name=> 'brand_pref_buick', :options => 3},
      { :name=> 'brand_pref_cadillac', :options => 3},
      { :name=> 'brand_pref_chevrolet', :options => 3},
      { :name=> 'brand_pref_chrysler', :options => 3},
      { :name=> 'brand_pref_dodge', :options => 3},
      { :name=> 'brand_pref_ferrari', :options => 3},
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
    @config = BitHash.new(@config_map)
  end

  it "should raise an error if config lacks name" do
    BitHash.new(@config_map).should_not be_nil
  end

  it "should raise an error if config lacks name" do
    @config_map[0].delete(:name)
    lambda { BitHash.new(@config_map) }.should raise_error(ArgumentError)
  end

  it "should be able to get keys" do
    @config.keys.should be_a Array
  end

  it "should have load same config" do
    @config.parse(@config.to_s).should eql(@config.to_hash)
  end

  it "should output equal it self after being converted and parsed" do
    str = @config.to_s
    bin = @config.to_bin
    @config.save(str)
    bin.should eql(@config.to_bin)
  end

  it "settings should change" do
    old = @config.to_s
    @config.set!(:color,'red')
    @config[:color].should eql('red')
  end

  it "should have different string if settings change" do
    @new = BitHash.new(@config_map)
    @config[:color]= 'red'
    @config[:body_style]= :suv
    @config[:air]= 1
    @new.save(@config.to_s)
    @new[:body_style].should eql(:suv)
    @new[:air].should eql(1)
    @new[:color].should eql('red')
  end

end
