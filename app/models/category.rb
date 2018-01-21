class Category < ApplicationRecord
  has_many :product
  enum cat1: ['電子產品', '食品', '寵物'] # 0開始
end
