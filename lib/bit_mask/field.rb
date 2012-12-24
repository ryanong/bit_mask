class BitMask::Field
  attr_reader :name
  attr_reader :options

  def initialize(name, opts)
    @name = name
    @options = opts
    if !values.is_a?(Integer) && !values.is_a?(Array)
      raise "#{values.class} is an invalid class for values."
    end
  end

  def bits
    @bits ||=
      if options[:bits]
        options[:bits]
      elsif values.kind_of?(Integer) && values < 0
        -1
      else
        if options[:limit]
          max_number = options[:limit]
        elsif values.is_a?(Integer)
          max_number = values
        elsif values.is_a?(Array)
          max_number = values.size
        end

        max_number += 1 if null

        (Math.log(max_number) / Math.log(2)).ceil
      end
  end

  def values
    options[:values]
  end

  def null
    options[:null]
  end

  def default
    @default ||=
      if null
        nil
      elsif values.kind_of? Integer
        0
      elsif values.respond_to? :first
        values.first
      elsif values.respond_to? :defaults
        values.defaults
      end
  end

  def to_bin(value)
    if self.null && value.nil?
      value = 0
    elsif self.values.respond_to? :index
      value = self.values.index(value)
      value += 1 if self.null
    end
    value = value.to_s(2)
    value = value.rjust(self.bits,'0') if self.bits > 0
    value
  end

  def from_i(value)
    value -= 1 if self.null

    if self.null && value == -1
      value = nil
    elsif self.values.respond_to?(:at)
      value = self.values.at(value)
    end
    value
  end
end
