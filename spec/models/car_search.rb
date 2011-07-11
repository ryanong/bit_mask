class CarSearch < BitHash
  field :min_price_cents, :values => [1000000,1500000,2000000,3000000,3500000,4000000,4500000,5000000,5500000,6000000,6500000,7000000]
  field :max_price_cents, :values => [1500000,2000000,3000000,3500000,4000000,4500000,5000000,5500000,6000000,6500000,7000000,8000000]
  field :segment_1, :values => 2
  field :segment_2, :values => 2
  field :segment_3, :values => 2
  field :segment_4, :values => 2
  field :segment_5, :values => 2
  field :segment_6, :values => 2
  field :segment_7, :values => 2
  field :segment_8, :values => 2
  field :segment_9, :values => 2
  field :brand_pref_acura, :values => 3
  field :brand_pref_aston_martin, :values => 3
  field :brand_pref_audi, :values => 3
  field :brand_pref_bentley, :values => 3
  field :brand_pref_bmw, :values => 3
  field :brand_pref_buick, :values => 3
  field :brand_pref_cadillac, :values => 3
  field :brand_pref_chevrolet, :values => 3
  field :brand_pref_chrysler, :values => 3
  field :brand_pref_dodge, :values => 3
  field :brand_pref_ferrari, :values => 3
  field :air, :values => 2
  field :body_style, :values => ['sedan','suv','wagon']
  field :color, :values => ['red','blue','green']
end
