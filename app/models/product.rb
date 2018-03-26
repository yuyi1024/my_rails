class Product < ApplicationRecord
  belongs_to :category, optional: true
  mount_uploader :photo, PhotoUploader
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  after_update :crop_photo

  scope :cat1_search, ->(params){ where( :categories => { :cat1 => params } ) }
  scope :cat2_search, ->(params){ where( :categories => { :id => params } ) }
  scope :price_search, ->(params1, params2){ where("price between ? and ?", params1, params2) }
  scope :price_top, ->(params){ where("price >= ? ", params ) }
  scope :keyword, ->(params){ where("name LIKE ?", "%#{params}%") }

  def crop_photo
  	photo.recreate_versions! if crop_x.present?
	end

end

