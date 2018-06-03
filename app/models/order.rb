class Order < ApplicationRecord
  has_many :order_items
  belongs_to :user
  accepts_nested_attributes_for :order_items

  #運費
  Freight_in_store = 60
  Freight_home_delivery = 100

  #訂單序號
  def g_process_id(user, order)
    t = Time.now
    process_id = t.year.to_s[2,3] + "%02d" % t.mon + "%02d" % t.mday + "%03d" % user + rand(0..9).to_s + "%02d" % order + "%02d" % rand(0..99)
  end

  def status_cn
    case self.status
    when 'pending'
      '結帳未完成'
    when 'waiting_payment'
      '待付款'
    when 'waiting_shipment'
      '待出貨'
    when 'paid'
      '待出貨'
    when 'shipping'
      '運送中'
    when 'delivered'
      '已到貨'
    when 'returned'
      '已退貨'
    when 'refunded'
      '已退款'
    when 'canceled'
      '已取消'
    when 'delivered_store'
      '已到店'
    when 'picked_up'
      '已取貨'
    when 'finished'
      '結束交易'
    end
  end

  def pay_method_cn
    case self.pay_method
    when 'pickup_and_cash'
      '取貨付款'
    when 'cash_card'
      '信用卡'
    when 'atm'
      '實體ATM'
    end
  end

  def ship_method_cn
    case self.logistics_type
    when 'CVS'
      '超商取貨'
    when 'Home'
      '宅配'
    end
  end

  def paid_cn
    if self.pay_method == 'atm'
      if self.remit_data.blank?
        '未付款'
      else
        self.paid == 'true' ? '已付款' : '已通知付款'
      end
    else
      self.paid == 'true' ? '已付款' : '未付款'
    end
  end

  def delivered_cn
    self.delivered == 'true' ? '已收貨' : '未收貨'
  end

  def may_status
    @may = []
    @may << ['已付款, 待出貨', 'pay'] if self.may_pay?
    @may << ['已出貨', 'ship'] if self.may_ship?
    @may << ['已到貨', 'deliver'] if self.may_deliver? && self.ship_method == 'to_address'
    @may << ['已到店', 'deliver_store'] if self.may_deliver_store?  && self.ship_method == 'in_store'
    @may << ['已取貨', 'pick_up'] if self.may_pick_up?
    @may << ['結束交易', 'finish'] if self.may_finish?
    @may << ['取消訂單', 'cancel'] if self.may_cancel?
    @may << ['已退貨', 'return'] if self.may_return?
    @may << ['以退款', 'refund'] if self.may_refund?
    @may
  end

  def ecpay_create

    total_price = (self.price + self.freight).to_s
    is_collection = ( self.pay_method == 'pickup_and_cash' ? 'Y' : 'N' )

    if !self.receiver_zipcode.blank?
      zipcode = self.receiver_zipcode[0..2].to_i
      
      if zipcode >= 207 && zipcode <= 253
        distance = '00'
      elsif zipcode >= 880 && zipcode <= 896
        distance = '02'
      else
        distance = '01'
      end
    end
      

    b2c_param = {
      'MerchantTradeNo' => self.process_id, 
      'MerchantTradeDate' => Time.now.strftime("%Y/%m/%d %T"),
      
      'LogisticsType' => self.logistics_type, #CVS/Home
      'LogisticsSubType' => self.logistics_subtype,  
      'GoodsAmount' => total_price,
      'CollectionAmount' => ( is_collection == 'Y' ? total_price : '0' ),
      'IsCollection' => is_collection,
      
      'GoodsName' => '霸雕爆裂丸商品',
      'TradeDesc' => '',  

      'SenderName' => '李霸丸',  
      'SenderPhone' => '0222888800',   
      'SenderCellPhone' => '0988123456',  
      
      'ReceiverName' => self.receiver_name,
      'ReceiverCellPhone' => self.receiver_cellphone, #CVS不可空
      'ReceiverPhone' => (self.receiver_phone.blank? ? '' : self.receiver_phone), #Home與手機擇一
      'ReceiverEmail' => (self.receiver_email.blank? ? '' : self.receiver_email), 
      
      'ServerReplyURL' => 'http://localhost:3001',
      'ClientReplyURL' => '',  
      'LogisticsC2CReplyURL' => '',
      'Remark' => '',
      'PlatformID' => '',
    }

    cvs_params = {
      'ReceiverStoreID' => self.receiver_store_id,
      'ReturnStoreID' => '',
    }

    home_params = {
      'SenderZipCode' => '23159',
      'SenderAddress' => '新北市霸丸街12號9樓',
      
      'ReceiverZipCode' => self.receiver_zipcode,
      'ReceiverAddress' => self.receiver_address,
      
      'Temperature' => '0001',
      'Distance' => distance,
      'Specification' => '0001',

      'ScheduledPickupTime' => '2',
      'ScheduledDeliveryTime' => '',
      'ScheduledDeliveryDate' => '',
      'PackageCount' => '',
    }

    receive_params = (self.logistics_type == 'CVS' ? cvs_params : home_params)
    receive_params.map{ |key, value| b2c_param[key] = value }

    create = ECpayLogistics::CreateClient.new
    res = create.create(b2c_param)

    puts res
    res = res.sub('1|', '')

    hash = CGI::parse(res)
    return hash
    
  end

  include AASM

  aasm column: :status do
    state :pending, initial: true
    state :waiting_payment, :waiting_shipment, :paid, :shipping #準備流程
    state :delivered, :delivered_store, :picked_up, :finished #出貨後流程
    state :returned, :refunded, :canceled #退貨流程
    
    #待付款
    event :wait_payment do 
      transitions from: :pending, to: :waiting_payment
    end

    #待出貨
    event :wait_shipment do
      transitions from: :pending, to: :waiting_shipment
    end

    #已付款, 待出貨
    event :pay do
      transitions from: :waiting_payment, to: :paid
    end

    #已出貨
    event :ship do 
      transitions from: [:paid, :waiting_shipment], to: :shipping
    end


    #宅配已到貨（含付款）
    event :deliver do
      transitions from: :shipping, to: :delivered
    end

    #超商已到店
    event :deliver_store do
      transitions from: :shipping, to: :delivered_store
    end

    #超商已取貨（含付款）
    event :pick_up do
      transitions from: :delivered_store, to: :picked_up
    end

    #訂單順利結束
    event :finish do
      transitions from: [:delivered, :picked_up], to: :finished
    end


    # 已退貨（訂單結束後欲退貨）
    event :return do
      transitions from: [:finished], to: :returned
    end

    #已退款
    event :refund do
      transitions from: [:returned, :paid], to: :refunded
    end

    #訂單取消
    event :cancel do
      transitions from: [:waiting_payment, :waiting_shipment, :refunded], to: :canceled
    end


  end
end