class Order < ApplicationRecord
  has_many :order_items
  belongs_to :user
  accepts_nested_attributes_for :order_items

  Freight_in_store = 60
  Freight_home_delivery = 100

  include AASM

  def g_process_id(user, order)
    t = Time.now
    process_id = t.year.to_s[2,3] + "%02d" % t.mon + "%02d" % t.mday + "%03d" % user + rand(0..9).to_s + "%02d" % order + "%02d" % rand(0..99)
  end

  aasm column: :status do
    state :pending, initial: true
    state :paid, :shipping, :delivered, :returned, :refunded, :canceled, :deliverd_store, :picked_up, :finished

    event :pay do
      transitions from: :pending, to: :paid
    end

    event :ship do 
      transitions from: [:paid, :pending], to: :shipping
    end

    event :deliver do
      transitions from: :shipping, to: :delivered
    end

    event :return do
      transitions from: [:shipping, :delivered, :delivered_store, :picked_up], to: :returned
    end

    event :refund do
      transitions from: [:returned, :paid], to: :refunded
    end

    event :cancel do
      transitions from: :paid, to: :canceled
    end

    #到店
    event :deliver_store do
      transitions from: :shipping, to: :delivered_store
    end

    #取貨付款
    event :pick_up do
      transitions from: :delivered_store, to: :picked_up
    end

    event :finish do
      transitions from: [:delivered, :picked_up, :refunded, :returned], to: :finished
    end

  end
end
