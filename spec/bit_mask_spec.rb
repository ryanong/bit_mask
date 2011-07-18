require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BitMask do

  it "should have values set at 2" do
    CarSearch.fields.assoc(:segment_1)[1][:values].should == 2
  end

  it "should have bits set to 1" do
    CarSearch.fields.assoc(:segment_1)[1][:bits].should == 1
  end

  it "should have bits set to 4" do
    CarSearch.fields.assoc(:min_price_cents)[1][:bits].should == 4
  end

  it "should raise an error if config lacks name" do
    CarSearch.new.should_not be_nil
  end

  it "should be able to get keys" do
    CarSearch.keys.should be_a Array
  end

  it "should have load same config" do
    CarSearch.load(CarSearch.new.dump).inspect.should == CarSearch.new.inspect
  end

  it "should equal itself" do
    CarSearch.load(CarSearch.new.dump).should == CarSearch.new
  end

  it "should output equal it self after being converted and parsed" do
    str = CarSearch.new.dump
    bin = CarSearch.new.to_bin
    CarSearch.load(str).to_bin.should eql(bin)
  end

  it "settings should change" do
    old = CarSearch.new
    new = old.dup
    new[:body_style]= 'wagon'
    new[:color].should eql('red')
  end

  it "should replace setting" do
    config = CarSearch.new
    config.replace({:air=>1})
    config[:air].should eql(1)
  end

  let(:modified_conf) {
    config = CarSearch.new
    config.color= 'red'
    config.body_style= 'suv'
    config.air= 1
    config
  }

  it "should have binary conversion working" do
    new = CarSearch.from_bin(modified_conf.to_bin)
    new.attributes.should == modified_conf.attributes
  end

  it "should have integer conversion working" do
    new = CarSearch.from_i(modified_conf.to_i)
    new.attributes.should == modified_conf.attributes
  end

  it "should have string conversion working" do
    modified_conf.to_s(10).should == modified_conf.to_i.to_s(10)
  end

  it "should have string conversion working" do
    modified_conf.to_bin == CarSearch.from_s(modified_conf.to_i.to_s(36),36).to_bin
  end

  it "should have string conversion working" do
    new = CarSearch.from_s(modified_conf.to_s)
    new.attributes.should == modified_conf.attributes
  end

  it "should have string conversion working" do
    new = CarSearch.from_s(modified_conf.to_s('qwerty'),'qwerty')
    new.attributes.should == modified_conf.attributes
  end

  it "should allow for infinite values" do
    search = DealershipSearch.new
    search.distance = 9999999999999
    loaded = DealershipSearch.from_bin(search.to_bin)
    loaded.distance.should == search.distance
  end
end
