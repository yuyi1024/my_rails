class Order < ApplicationRecord
  has_many :order_items
  belongs_to :user
  accepts_nested_attributes_for :order_items

  Freight_in_store = 60
  Freight_to_address = 100

  include AASM

  def g_process_id(user, order)
    t = Time.now
    process_id = t.year.to_s[2,3] + "%02d" % t.mon + "%02d" % t.mday + "%03d" % user + rand(0..9).to_s + "%02d" % order + "%02d" % rand(0..99)
  end

  def status_cn
    case self.status
    when 'pending'
      self.status = '準備中'
    when 'paid'
      self.status = '已付款'
    when 'shipping'
      self.status = '運送中'
    when 'delivered'
      self.status = '已到貨'
    when 'returned'
      self.status = '已退貨'
    when 'canceled'
      self.status = '已取消'
    when 'deliverd_store'
      self.status = '已到店'
    when 'picked_up'
      self.status = '已取貨'
    when 'finished'
      self.status = '結束交易'
    end
  end

  def pay_method_cn
    case self.pay_method
    when 'pay_before'
      self.pay_method = '先匯款'
    when 'pay_after'
      self.pay_method = '貨到付款'
    end
  end

  def ship_method_cn
    case self.ship_method
    when 'in_store'
      self.ship_method = '超商取貨'
    when 'to_address'
      self.ship_method = '宅配'
    end
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
