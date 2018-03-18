class Product < ApplicationRecord
  belongs_to :category

  scope :cat1_search, ->(params){ where( :categories => { :cat1 => params } ) }
  scope :cat2_search, ->(params){ where( :categories => { :id => params } ) }
  scope :price_search, ->(params1, params2){ where("price between ? and ?", params1, params2) }
  scope :price_top, ->(params){ where("price > ? ", params ) }
  scope :keyword, ->(params){ where("name LIKE ?", "%#{params}%") }
end

