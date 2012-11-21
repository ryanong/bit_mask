class BitMask::Field
  attr_reader :name, :values, :bits, :null, :default
  def initialize(name, opts)
    @name = name
    self.opts = opts
  end

  def opts=(opts)
    unless opts[:bits]
      unless opts[:limit]
        if opts[:characters]
          opts[:limit] = opts[:characters].to_i*self.base
        elsif opts[:values].respond_to? :bit_length
          opts[:bits] = opts[:values].bit_length
        elsif opts[:values].kind_of? Integer
          if opts[:values] == -1
            opts[:bits] = -1
          else
            opts[:limit] = opts[:values]
            opts[:limit] += 1 if opts[:null]
          end
        else
          opts[:limit] = opts[:values].size
          opts[:limit] += 1 if opts[:null]
        end
      end
      opts[:bits] ||= (opts[:limit].to_i-1).to_s(2).length
    end
    raise "value cannot be negative" if opts[:values].class == Integer && opts[:values] < 0
    @values = opts[:values]
    @bits = opts[:bits].to_i
    @null = opts[:null]
    @default =if null
      nil
    elsif values.kind_of? Integer
      0
    elsif values.respond_to? :first
      values.first
    elsif values.respond_to? :defaults
      values.defaults
    end
  end
end
