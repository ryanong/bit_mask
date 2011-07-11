require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BitHash do

  it "should raise an error if config lacks name" do
    CarSearch.new.should_not be_nil
  end

  it "should be able to get keys" do
    CarSearch.keys.should be_a Array
  end

  it "should have load same config" do
    CarSearch.load(CarSearch.new.dump).should eql(CarSearch.new)
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

  it "should have different string if settings change" do
    config = CarSearch.new
    config[:color]= 'red'
    config[:body_style]= 'suv'
    config[:air]= 1
    new = CarSearch.load(config.dump)
    new[:body_style].should eql('suv')
    new[:air].should eql(1)
    new[:color].should eql('red')
  end

end
