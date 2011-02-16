require 'to_insane'

class BitHash

  attr_accessor :options, :default
  # look below at load_config_map for config_map schema
  # base is the base value you want to use. Defaults to a URL safe character base which is 63
  # character set can also be changed but not really necessary. read to_insane doc for more details
  def initialize(config_map=nil, *options)
    load_options(options)
    @config = Hash.new
    @default = Hash.new
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
      raise ArgumentError, "#{conf[:name]} is a duplicate" if new_config.keys.index(conf[:name])
      new_config[conf[:name]] = get_check_config(index,conf)
      config_array[index] = conf 
    end
    @config = new_config.dup
    @default = new_config.dup
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
  def parse(config_string, *options)
    if options.kind_of? Array
      @options[:base] = options[0] unless options[0].nil?
      @options[:char_set] = options[1] unless options[1].nil?
      @options[:prefix] = options[2] unless options[2].nil?
    end
    @options.merge!(options) if options.kind_of? Hash
    raise ArgumentError, "Prefix must be a string" if !@options[:prefix].nil? && !@options[:prefix].kind_of?(String)
    config_string[0..@options[:prefix].size] = nil unless @options[:prefix].nil?
    config_array = config_string.from_insane(@options[:base],@options[:char_set]).to_s(2).split('')
    new_config = @default.dup
    @config_map.each do |conf|
      break if config_array.size == 0
      value = config_array.pop(conf[:size]).join('').to_i(2)
      new_config[conf[:name]] = (conf[:options].kind_of? Array ) ? conf[:options][value] : value
    end
    new_config
  end

  # pareses and saves string into internal hash
  def save(config_string, *options)
    @config = parse(config_string, *options)
  end

  #converts it into a binary string
  def to_bin
    bin_config = ''
    @config_map.reverse_each do |conf|
      val = @config[conf[:name]]
      val = conf[:options].index(val) if conf[:options].kind_of? Array
      bin = val.to_s(2)
      bin_config << bin.rjust(conf[:size]-bin.size,'0')
    end
    bin_config
  end
  
  #converts it to an integer, Good for IDs
  def to_i
    to_bin.to_i(2)
  end

  # turns hash into a small compact string.
  # see to_insane rdoc for base, and char_set definitions
  def to_s(*options)
    load_options(options)
    str = ''
    str << @options[:prefix] if @options[:prefix].kind_of? String
    str << to_i.to_insane(@options[:base], @options[:char_set])
    str
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

  private

  # checks value against given config
  def check_value(conf,val)
    if conf[:options].kind_of?(Array)
      return false if conf[:options].index(val).nil?
    elsif conf[:options].kind_of?(Integer) && val.kind_of?(Integer)
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
  
  def load_options(options)
    if options.kind_of? Array
      @options = {:base => options[0], :char_set => options[1]}
    elsif options.kind_of? Hash
      @options = options
    end
    @options[:base] ||= :url_safe
    @options[:char_set] ||= nil
    @options[:prefix] ||= nil
  end

  def get_check_config(key,conf)
    raise ArgumentError, "config is not a Hash" unless conf.kind_of? Hash
    raise ArgumentError, ":name cannot be nil for [#{key}]" if conf[:name].nil?
    raise ArgumentError, ":options cannot be nil for [#{key}]" if conf[:options].nil?
    if conf[:options].kind_of? Integer
      conf[:size] = conf[:options]
    elsif conf[:options].kind_of? Array
      conf[:size] = conf[:options].size
    elsif conf[:options].kind_of? Symbol || conf[:options].kind_of?(String)
      raise ArgumentError, ":options Character set cannot have duplicate characters" if conf[:options].kind_of?(String) && (conf[:options].size != conf[:options].split(//).uniq.size)
      raise ArgumentError, ":options"
      raise ArgumentError, ":size needs to be an integer larger than 0 [#{conf[:name]}]" unless conf[:size].kind_of? Integer and conf[:size] > 0
    else
      raise ArgumentError, ":options needs to be an Array or Integer for [#{conf[:name]}]" 
    end
    if !conf[:default].nil?
      raise ArgumentError, "default value of (#{conf[:default]}) is not valid for #{conf[:name]}" unless check_value(conf,conf[:default])
      default = conf[:default]
    elsif !conf[:default_index].nil?
      raise ArgumentError, ":default_index must be an integer #{conf[:name]}" unless conf[:default_index].kind_of? Integer
      unless default = conf[:options][conf[:default_index]]
        raise ArgumentError, ":default_index must be a valid option array index #{conf[:name]}"
      end
    end
    conf[:size] = conf[:size].to_s(2).size
    default ||= (conf[:options].kind_of? Integer) ? 0 : conf[:options][0]
  end
end

