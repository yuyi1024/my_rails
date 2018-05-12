class Category < ApplicationRecord
  has_many :product
  has_many :subcategories
end
