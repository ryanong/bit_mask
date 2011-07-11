require 'radix'
require 'active_support/core_ext/class/attribute'
class BitHash < Hash
  class_attribute :fields, :defaults, :base

  def self.inherited(sub)
    sub.fields = []
    sub.defaults = {}
    sub.base = 36
  end

  def initialize(*args)
    super()
    self.replace(self.defaults.merge(*args))
  end

  def []=(key,value)
    if field = self.fields.assoc(key)
      if self.class.check_value(key,value)
        super(key,value)
      else
        raise "Invalid input for #{key}"
      end
    else
      raise "#{key} is an invalid key"
    end
  end

  def to_bin
    self.fields.reverse.map do |field,conf|
      val = self[field]
      val = conf[:values].index(val) if conf[:values].respond_to? :index
      "%0#{conf[:bits]}d" % val.to_i.to_s(2)
    end.join('').sub(/\A0+/,'')
  end

  #converts it to an integer, Good for IDs
  def to_i
    self.to_bin.to_i(2)
  end

  def to_s(base=nil)
    base ||= self.base
    self.to_i.to_s(base)
  end

  def keys
    self.class.keys
  end

  alias_method :dump, :to_s

  class << self

    def keys
      self.fields.map {|f| f[0]}
    end

    def from_s(string,base = nil)
      base ||= self.base
      from_i(string.to_i(base))
    end

    alias_method :load, :from_s

    def from_i(integer)
      from_bin(integer.to_s(2))
    end

    def from_bin(binary_string)
      binary_array = binary_string.split('')
      bit_hash = self.new
      self.fields.each do |field,conf|
        value = (conf[:bits] == -1) ? binary_array : binary_array.pop(conf[:bits])
        break if value.nil?
        value = value.join('').to_i(2)
        if conf[:values].respond_to?(:at)
          bit_hash[field] = conf[:values].at(value)
        elsif conf[:values].respond_to?(:from_i)
          bit_hash[field] = conf[:values].from_i(value)
        else
          bit_hash[field] = value
        end
      end
      bit_hash
    end

    def set_base(base)
      if base.kind_of? Integer && base <= 36
        self.base = base
      end
    end

    def bit_length
      bits = 0
      self.fields.each do |field,opts|
        bits += opts[:bits]
      end
      bits
    end

    def field(name,opts)
      unless opts[:bits]
        unless opts[:limit]
          if opts[:characters]
            opts[:limit] = opts[:characters].to_i*self.base
          elsif opts[:values].respond_to? :bit_length
            opts[:bits] = opts[:values].bit_length
          else
            opts[:limit] = opts[:values].size
          end
        end
        opts[:bits] ||= (opts[:limit].to_i-1).to_s(2).size
      end
      raise "value cannot be negative" if opts[:values].class == Integer && opts[:values] < 0
      options = {:values => opts[:values], :bits => opts[:bits].to_i}
      if index = self.fields.index{|f| f[0] == name}
        self.fields[index][1] = options
      else
        self.fields << [name, options]
      end
      self.defaults[name]=get_default(opts[:values])

      define_method name do
        self[name]
      end

      define_method "#{name}=" do |*args|
        self[name]= *args
      end

    end

    def get_default(values)
      if values.kind_of? Integer
        0
      elsif values.respond_to? :first
        values.first
      elsif values.respond_to? :defaults
        values.defaults
      end
    end

    def check_value(key,value)
      if values = self.fields.assoc(key)[1][:values]
        if values.kind_of? Integer
          return false if value < 0
          return values == -1 || value <= values
        elsif values.kind_of? BitHash
          return value.kind_of? BitHash && value.fields.hash == value.fields.hash
        else
          return values.include?(value)
        end
      end
      false
    end
  end
end
