require 'to_insane'

class CFG
  
  def initialize(config_map=nil, base = :url_safe, char_set = nil)
    @base = base
    @char_set = char_set
    @config = Hash.new
    #validate mapping
    load_config_map(config_map) if config_map.kind_of? Array
    @config
  end
  
  def load_config_map(config_map)
    raise ArgumentError, "Config Map must be an Array" unless config_map.kind_of? Array
    config_array = []
    config_map.each_index do |index|
      conf = config_map[index]
      raise ArgumentError, "config is not a Hash" unless conf.kind_of? Hash
      raise ArgumentError, ":name cannot be nil for [#{index}]" if conf[:name].nil?
      raise ArgumentError, ":options cannot be nil for [#{index}]" if conf[:options].nil?
      if conf[:options].kind_of? Integer
        conf[:size] = conf[:options]
      elsif conf[:options].kind_of? Array
        conf[:size] = conf[:options].size
      else
        raise ArgumentError, ":options needs to be an Array or Integer for [#{conf[:name]}]" 
      end
      conf[:size] = conf[:size].to_s(2).size
      unless conf[:default].nil?
        raise ArgumentError, "default value of (#{conf[:default]}) is not valid for #{conf[:name]}" unless check_value(conf,conf[:default])
      end
      @config[conf[:name]] = conf[:default] || 0
      config_array[index] = conf 
    end
    @config_map = config_array
  end

  def keys
    @config_map.map{ |c| c[:name]}
  end

  def set(key,value)
    conf = get_options(key)
    if conf && check_value(conf,value)
      @config[key] = value
    else
      nil
    end
  end

  def set!(key,value)
    conf = get_options(key)
    if conf && check_value!(conf,value)
      @config[key] = value
    else
      raise ArgumentError, "Key: '#{key}' not found in config"
    end
  end

  def get(key)
    @config[key]
  end

  def inspect
    @config
  end

  def load_hash(hash)
    hash.each do |key, value|
      set(key,value)
    end
  end

  def get_options(key)
    index = @config_map.index{|x|x[:name]==key}
    (index) ? @config_map[index].merge({:index => index}) : nil
  end

  def load_string(config_string, base = nil, char_set=nil)
    base ||= @base
    char_set ||= @char_set
    config_array = config_string.from_insane(base,char_set).to_s(2).split('').reverse
    @config_map.each do |conf|
      break if conf[:size]
      value = config_array.drop(conf[:size]).join('').to_i(2)
      @config[conf[:name]] = (conf[:options].kind_of? Array ) ? conf[:options][value] : value
    end
    @config.dup
  end

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

  private

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

