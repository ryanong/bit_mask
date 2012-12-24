require 'active_support/core_ext/class/attribute'
require 'active_support/ordered_hash'

class BitMask
  autoload :Field, 'bit_mask/field'
  autoload :Radix, 'bit_mask/radix'

  CHARACTER_SET = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  class_attribute :fields, :base
  def self.inherited(sub)
    sub.fields = ActiveSupport::OrderedHash.new
    sub.base = 62
  end

  def initialize(new_attributes = {})
    @attributes = {}
    self.assign_attributes(
      self.class.defaults.merge(new_attributes)
    )
  end

  def assign_attributes(new_attributes)
    new_attributes.each do |field, value|
      self.send("#{field}=",value)
    end
  end

  alias_method :attributes=, :assign_attributes

  def [](field)
    self.read_attribute(field)
  end

  def []=(field,value)
    self.write_attribute(field,value)
  end

  def read_attribute(key)
    @attributes[key]
  end

  def write_attribute(key,value)
    if field = self.fields[key]
      if self.class.check_and_cast_value(field,value)
        @attributes[field.name] = value
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
      field.to_bin(val)
    end.join('').sub(/\A0+/,'')
  end

  #converts it to an integer, Good for IDs
  def to_i
    self.to_bin.to_i(2)
  end

  def to_s(radix=nil)
    radix ||= self.base

    if radix.kind_of? String
      Radix.integer_to_string(self.to_i, radix)
    elsif radix.kind_of?(Integer) && radix > 1 && radix <= CHARACTER_SET.length
      Radix.integer_to_string(self.to_i, CHARACTER_SET[0..radix-1])
    else
      raise '#{radix} is and invali base to convert to. It must be a string or between 0 and 64'
    end
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
      self.fields.keys
    end

    def from_s(string,radix = nil)
      radix ||= self.base

      integer = if radix.kind_of? String
        Radix.string_to_integer(string, radix)
      elsif radix.kind_of?(Integer) && radix > 1 && radix <= CHARACTER_SET.length
        Radix.string_to_integer(string, CHARACTER_SET[0..radix-1])
      else
        raise '#{radix} is an invalid base to convert to. It must be a string or between 0 and 64'
      end

      self.from_i(integer)
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
      self.fields[name] = Field.new(name,opts)

      include(Module.new do
        define_method(name) do
          read_attribute(name)
        end

        define_method("#{name}=") do |*args|
          write_attribute(name,*args)
        end
      end)
    end

    def defaults
      fields_array = fields.values.map do |field|
        [field.name, field.default]
      end
      Hash[fields_array]
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
