require 'to_insane'

class BitHash

  attr_accessor :base, :char_set
  # look below at load_config_map for config_map schema
  # base is the base value you want to use. Defaults to a URL safe character base which is 63
  # character set can also be changed but not really necessary. read to_insane doc for more details
  def initialize(config_map=nil, base = :url_safe, char_set = nil)
    @base = base
    @char_set = char_set
    @config = Hash.new
    #validate mapping
    load_config_map(config_map) if config_map.kind_of? Array
    @config
  end

  #Example config_map
  #
  #  config_map = [
  #  {
  #    :name => :air,    # name of option
  #    :options => 2,    # number of options must be 2 or greater
  #  },
  #  {
  #    :name => :color, 
  #    :options => ['blue','green','red']    # bit_hash can map arrays of data, the default setting will be the first value in the array
  #  },
  #  {
  #    :name => :body_style, 
  #    :options => [:sedan,:mini_van,:suv],  # Array values can be anything that can be found using the Array#index function
  #    :default => :mini_van                 # for arrays the default is any array value
  #  },
  #  {
  #    :name => :transmission,     # name of option
  #    :options => 6,
  #    :default => 5               # for numbers the default must be between 0 and the options value
  #  },
  #  {
  #    :name => :min_price,
  #    :options => (50..100).to_a, # ( just a way to store ranges of numbers)
  #    :default => 60              # basically any default can be used as long as it is a valid option
  #  },
  #  {
  #    :name => :max_price,

  #    # intervals of 20 starting at 10000 (just a way to store ranges of numbers)
  #    :options => (1..5).to_a.map {|n| 10000+(n*20)},

  #    # you can use :default_index option to reference something in the option arrays but it really isn't suggested, :default take precedence
  #    :default_index =>  2
  #    }
  #  ]
  def load_config_map(config_map)
    raise ArgumentError, "Config Map must be an Array" unless config_map.kind_of? Array
    config_array = []
    new_config = {}
    config_map.each_index do |index|
      conf = config_map[index]
      raise ArgumentError, "config is not a Hash" unless conf.kind_of? Hash
      raise ArgumentError, ":name cannot be nil for [#{index}]" if conf[:name].nil?
      raise ArgumentError, "#{conf[:name]} is a duplicate" if new_config.keys.index(conf[:name])
      raise ArgumentError, ":options cannot be nil for [#{index}]" if conf[:options].nil?
      if conf[:options].kind_of? Integer
        conf[:size] = conf[:options]
      elsif conf[:options].kind_of? Array
        conf[:size] = conf[:options].size
      else
        raise ArgumentError, ":options needs to be an Array or Integer for [#{conf[:name]}]" 
      end
      if !conf[:default].nil?
        raise ArgumentError, "default value of (#{conf[:default]}) is not valid for #{conf[:name]}" unless check_value(conf,conf[:default])
        new_config[conf[:name]] = conf[:default]
      elsif !conf[:default_index].nil?
        raise ArgumentError, ":default_index must be an integer #{conf[:name]}" unless conf[:default_index].kind_of? Integer
        raise ArgumentError, ":default_index must be a valid option array index #{conf[:name]}" unless new_config[conf[:name]] = conf[:options][conf[:default_index]]
      end
      new_config[conf[:name]] ||= (conf[:options].kind_of? Integer) ? 0 : conf[:options][0]
      conf[:size] = conf[:size].to_s(2).size
      config_array[index] = conf 
    end
    @config = new_config
    @config_map = config_array
  end

  # Just get a list of keys
  def keys
    @config_map.map{ |c| c[:name]}
  end

  # Set default key
  def set_default(key)
    conf = get_options(key)
    @config[conf[:name]] = 0
    if !conf[:default].nil?
      new_config[conf[:name]] = conf[:default]
    elsif !conf[:default_index].nil?
      new_config[conf[:name]] = conf[:options][conf.default_index]
    end
  end

  # see set
  def []=(key,value)
    set(key,value)
  end

  # sets a key value, returns nil if value is invalid
  def set(key,value)
    conf = get_options(key)
    if conf && check_value(conf,value)
      @config[key] = value
    else
      nil
    end
  end

  # sets with critical failure
  def set!(key,value)
    conf = get_options(key)
    if conf && check_value!(conf,value)
      @config[key] = value
    else
      raise ArgumentError, "Key: '#{key}' not found in config"
    end
  end

  # fetches values for given key
  def [](key)
    @config[key]
  end

  # replaces internal settings with  any given hash and overwrites values and returns hash. On failure returns nil
  def replace(hash)
    cache = @config.dup
    hash.each do |key, value|
      if set(key,value).nil?
        @config = cache
        return nil
      end
    end
    @config
  end

  # returns option settings for given key
  def get_options(key)
    index = @config_map.index{|x|x[:name]==key}
    (index) ? @config_map[index].merge({:index => index}) : nil
  end

  # replaces given option with name of key and replaces with options
  def replace_options(key, options)
    @config_map.map! do |conf|
      if conf[:name] == key
        options
      else
        conf
      end
    end
  end

  # takes a given config string and returns a mapped hash
  # please read to_insane doc for info on base and char_set
  def parse_string(config_string, base = nil, char_set=nil)
    base ||= @base
    char_set ||= @char_set
    config_array = config_string.from_insane(base,char_set).to_s(2).split('').reverse
    new_config = @config.dup
    @config_map.each do |conf|
      break if conf[:size]
      value = config_array.drop(conf[:size]).join('').to_i(2)
      new_config[conf[:name]] = (conf[:options].kind_of? Array ) ? conf[:options][value] : value
    end
    new_config
  end

  alias_method :save_string, :load
  # pareses and saves string into internal hash
  def save_string(config_string, base = nil, char_set=nil)
    @config = parse_string(config_string, base, char_set)
  end

  # turns hash into a small compact string.
  # see to_insane rdoc for base, and char_set definitions
  def to_s(base = nil, char_set = nil)
    base ||= @base
    char_set ||= @char_set
    bin_config = ''
    @config_map.reverse_each do |conf|
      val = @config[conf[:name]]
      val = conf[:options].index(val) if conf[:options].kind_of? Array
      bin_config << val.to_s(2)
    end
    bin_config.to_i(2).to_insane(base, char_set)
  end

  #checks key to see if value given is valid
  def valid_value?(key,val)
    check_value(get_options(key),val)
  end

  alias_method :to_hash, :inspect 

  # returns as a hash (alias: inspect)
  def to_hash
    @config
  end

  #  Get Settings
  #  {
  #    :config => @config,
  #    :config_map => @config_map,
  #    :base => @base,
  #    :char_set => @charset
  #  }
  def settings
    {
      :config => @config,
      :config_map => @config_map,
      :base => @base,
      :char_set => @charset
    }
  end

  private

  # checks value against given config
  def check_value(conf,val)
    if conf[:options].kind_of? Array
      return false if conf[:options].index(val).nil?
    elsif conf[:options].kind_of? Integer
      return false if val < 0 or val > conf[:options]
    else
      return false
    end
    true
  end

  # checks values with a bang
  def check_value!(conf,val)
    if conf[:options].kind_of? Array
      raise ArgumentError, "#{conf[:name]} is #{val} and is not a valid value within the stored array. #{conf[:options].to_s}" if conf[:options].index(val).nil?
    elsif conf[:options].kind_of? Integer
      raise ArgumentError, "#{conf[:name]} is #{val} and should not be less than 0" if val < 0
      raise ArgumentError, "#{conf[:name]} is #{val} and value is not less than #{conf[:options]}" if val > conf[:options]
    else
      raise ArgumentError, "#{conf[:name]} is not a valid value please associate it with an object in an array or give it an integer value" 
    end
    true
  end

end

