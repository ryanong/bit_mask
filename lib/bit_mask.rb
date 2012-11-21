require 'active_support/core_ext/class/attribute'
require 'active_support/ordered_hash'

class BitMask
  autoload :Field, 'bit_mask/field'

  CHARACTER_SET = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  class_attribute :fields, :base
  def self.inherited(sub)
    sub.fields = ActiveSupport::OrderedHash.new
    sub.base = 62
  end

  def initialize(args = {})
    self.replace(
      self.class.defaults.merge(args)
    )
  end

  def replace(args)
    args.each do |field,value|
      self[field]= value
    end
  end

  alias_method :attributes=, :replace

  def [](field)
    raise "#{field} is an invalid key" unless self.respond_to?(field)
    self.send(field)
  end

  def []=(field,value)
    raise "#{field} is an invalid key" unless self.respond_to?("#{field}=")
    self.send("#{field}=",value)
  end

  def read_attribute(key)
    self.instance_variable_get("@#{key}".to_sym)
  end

  def write_attribute(key,value)
    if field = self.fields[key]
      if self.class.check_and_cast_value(field,value)
        self.instance_variable_set("@#{field.name}",value)
      else
        raise "Invalid input for #{key}: #{value}  field: #{field}"
      end
    else
      raise "#{key} is an invalid key"
    end
  end

  def to_bin
    self.fields.values.reverse.map do |field|
      val = self.read_attribute(field.name)
      if field.null && val.nil?
        val = 0
      elsif field.values.respond_to? :index
        val = field.values.index(val)
        val += 1 if field.null
      end
      val = val.to_i.to_s(2)
      val = val.rjust(field.bits,'0') if field.bits > 0
      val
    end.join('').sub(/\A0+/,'')
  end

  #converts it to an integer, Good for IDs
  def to_i
    self.to_bin.to_i(2)
  end

  def to_s(radix=nil)
    radix ||= self.base
    characters = CHARACTER_SET

    if radix.kind_of? String
      characters = radix.dup
      radix = radix.size
    elsif !radix.kind_of?(Integer) || radix < 0 || radix > 64
      raise '#{radix} is and invalid base to convert to. It must be a string or between 0 and 64'
    end

    dec = self.to_i
    result = ''
    while dec != 0
      result += characters[dec%radix].chr
      dec /= radix
    end
    result.reverse
  end

  def keys
    self.class.keys
  end

  alias_method :dump, :to_s

  def ==(other)
    self.class == other.class && self.fields == other.fields && self.attributes == other.attributes
  end

  def attributes
    fields.inject({}) do |attrs, field|
      attrs[field.first] = self.send(field.first)
      attrs
    end
  end

  def inspect
    self.attributes.inspect
  end

  class << self

    def keys
      self.fields.map {|f| f[0]}
    end

    def from_s(string,radix = nil)
      radix ||= self.base
      if radix.kind_of? String
        char_ref = radix
        radix = radix.size
      elsif !radix.kind_of?(Integer) || radix < 0 || radix > 64
        raise '#{radix} is and invalid base to convert to. It must be a string or between 0 and 64'
      else
        char_ref = CHARACTER_SET[0..radix]
      end

      int_val = 0
      string.reverse.split('').each_with_index do |char,index|
        raise ArgumentError, "Character #{char} at index #{index} is not a valid character for to_insane Base #{radix} String." unless char_index = char_ref.index(char)
        int_val += (char_index)*(radix**(index))
      end
      self.from_i(int_val)
    end

    alias_method :load, :from_s

    def from_i(integer)
      self.from_bin(integer.to_s(2))
    end

    def from_bin(binary_string)
      binary_array = binary_string.split('')
      bit_hash = self.new
      self.fields.values.each do |field|
        value = (field.bits == -1) ? binary_array : binary_array.pop(field.bits)
        break if value.nil?
        value = value.join('').to_i(2)
        value -= 1 if field.null

        if field.null && value == -1
          value = nil
        elsif field.values.respond_to?(:at)
          value = field.values.at(value)
        elsif field.values.respond_to?(:from_i)
          value = field.values.from_i(value)
        end
        bit_hash.write_attribute(field.name,value)
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
      name = name.to_sym
      if field = self.fields[name]
        field.opts = options
      else
        field = Field.new(name,opts)
        self.fields[name] = field
      end

      define_method name do
        self.read_attribute(name)
      end

      define_method "#{name}=" do |*args|
        self.write_attribute(name,*args)
      end
    end

    def defaults
      {}.tap do |default_fields|
        fields.values.each do |field|
          default_fields[field.name] = field.default
        end
      end
    end

    def check_and_cast_value(key,value)
      if field = (key.is_a? Field) ? key : self.fields[key]
        return true if field.null && value.nil?
        if values = field.values
          if values.kind_of? Integer
            value = value.to_i
            return nil if value < 0
            return value if (values == -1 || value <= values)
          elsif values.is_a? BitMask
            return value.is_a? BitMask && value.fields.hash == value.fields.hash
          else
            return value if values.include?(value)
          end
        end
      end
      nil
    end
  end
end
