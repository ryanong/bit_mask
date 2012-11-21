class DealershipSearch < BitMask
  field :makes, :values => ['honda','toyota','ford'], :null => true
  field :zip, :values => 99999, :null => true
  field :distance, :values => -1
end
