class Product < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :subcategory
  has_many :order_items
  has_many :favorites
  belongs_to :offer, optional: true
  mount_uploader :photo, PhotoUploader
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  after_update :crop_photo
  belongs_to :warehouse

  # scope :cat1_search, ->(params){ where( :categories => { :cat1 => params } ) }
  # scope :cat2_search, ->(params){ where( :categories => { :id => params } ) }
  scope :price_search, ->(params1, params2){ where("price between ? and ?", params1, params2) }
  scope :price_top, ->(params){ where("price >= ? ", params ) }
  scope :keyword, ->(params){ where("#{params}") }

  def crop_photo
  	photo.recreate_versions! if crop_x.present?
	end

  def status_cn
    case self.status
    when 'on_shelf'
      '上架'
    when 'off_shelf'
      '下架'
    end
  end

end

