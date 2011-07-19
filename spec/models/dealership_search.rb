class DealershipSearch < BitMask
  field :makes, :values => ['honda','toyota','ford'], :nil => true
  field :zip, :values => 99999, :nil => true
  field :distance, :values => -1
end
