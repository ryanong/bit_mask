# BitMask

A simple class that allows you to store data in a bit mask. It automagically manages bit sizes and base conversion of binary bitmask.

## Usage

When writing these config maps. Try to put the mose used options first so the string can be shorter.

```ruby
require 'rubygems'
require 'bit_mask'
class SearchParams < BitMask

  # first set base defaults is 62
  # Integer up to 62
  set_base 62

  field :air, :values => 2    # number of options must be 2 or greater
  field :color, :values => ['blue','green','red']  # bit_mask can map arrays of data, the default setting will be the first value in the array
  field :body_style,  :values => [:sedan,:mini_van,:suv]  # Array values can be anything that can be found using the Array#index function
  field :transmission,:values => 6
  field :min_price, :values => (50..100).to_a # ( just a way to store ranges of numbers)
  field :max_price, :values => (1..5).to_a.map {|n| 10000+(n*20)}

  # overwrite default accessors

  def body_style=(value)
    self.write_attribute(:body_style,value).to_sym
  end

  def body_style
    self.read_attribute(:body_style).to_s
  end

end

# initialize
@search = SearchParams.new

# set a single value
@search[:color]='red'
@search.color = 'red'

# get a single value
@search.color # the same as @search[:color]

# replace values in config with another hash
@search.replace({:air=>1})

# convert to small compact string
@search.to_s
@search.to_s(36) # choose base different from default
@search.to_s('asldkfjv') # use custom character sets for encoding
@search.dump

# load
SearchParams.load(@search.dump)
SearchParams.load(@search.to_s(36),36) # load from different base
SearchParams.load(@search.to_s('asldkfjv'),'asldkfjv')
```

## TODO

* Impliment more tests
* Storage of strings?
* create javascript version for easy communication between ruby and javascript

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

Ryan Ong - ryanong@gmail.com

## Copyright

Copyright (c) 2021 Ryan Ong. See LICENSE.txt for
further details.

