class DealershipSearch < BitMask
  field :makes, :values => ['honda','toyota','ford']
  field :zip, :values => 99999
  field :distance, :values => -1
end
