class Subcategory < ApplicationRecord
  has_many :product
  belongs_to :category
end
