class Product < ApplicationRecord
  belongs_to :category

  scope :cat1_search, ->(params){ where( :categories => { :cat1 => params } ) }
  scope :cat2_search, ->(params){ where( :categories => { :cat2 => params } ) }
  scope :price_search, ->(){ where("price between ? and ?",params[:price_bottom],params[:price_top]) }
end

