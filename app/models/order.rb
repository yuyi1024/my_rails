class Order < ApplicationRecord
  has_many :order_items
  belongs_to :offer, optional: true
  belongs_to :user
  has_many :remittance_infos
  has_one :ecpay_payment_atm_info

  accepts_nested_attributes_for :order_items

  # 預設運費
  Freight_in_store = 60
  Freight_home_delivery = 100

  # 訂單編號
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
    when 'waiting_refunded'
      '待退款'
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
    end
  end

  def pay_method_cn
    case self.pay_method
    when 'pickup_and_cash'
      '取貨付款'
    when 'Credit'
      '信用卡'
    when 'ATM'
      'ATM 自動櫃員機'
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
    case self.paid
    when 'true'
      '已付款'
    when 'false'
      '未付款'
    when 'remit'
      '已通知付款'
    end
  end

  def shipped_cn
    self.shipped == 'true' ? '已出貨' : '未出貨'
  end

  def cvs_subtype_cn
    case self.logistics_subtype
    when 'UNIMART'
      '7-11'
    when 'FAMI'
      '全家'
    when 'HILIFE'
      '萊爾富'
    end
  end

  # 可執行的訂單狀態
  def may_status
    @may = []
    @may << ['取消訂單', 'cancel'] if self.may_cancel?
    @may << ['已退貨', 'return'] if self.may_return?
    @may
  end

  # ecpay 金流建立
  def ecpay_payment_create
    self.merchant_trade_no = self.process_id + rand(9).to_s + rand(9).to_s
    self.save

    base_param = {
      'MerchantTradeNo' => self.merchant_trade_no,
      'MerchantTradeDate' => Time.now.strftime("%Y/%m/%d %T"),
      'TotalAmount' => self.price + self.freight,
      'TradeDesc' => '寵物用品',
      'ItemName' => '寵物用品',
      'ReturnURL' => 'https://bawan-store-0225.herokuapp.com/orders/from_ecpay_paid', # 付款完成時通知回傳(Credit、ATM)，更新 DB 資訊
      'OrderResultURL' => 'https://bawan-store-0225.herokuapp.com/orders/payment_result/' + self.process_id, # client 回傳付款結果(Credit) -> 更新 DB -> 顯示付款成功頁面
    }
    create = ECpayPayment::ECpayPaymentClient.new

    if self.pay_method == 'Credit' && self.paid == 'false'
      res = create.aio_check_out_credit_onetime(params: base_param)
    
    elsif self.pay_method == 'ATM'
      pay_info_url = 'https://bawan-store-0225.herokuapp.com/orders/from_ecpay_paid' # 取得請款資訊後回傳
      exp = '7'
      cli_redir_url = 'https://bawan-store-0225.herokuapp.com/orders/ecpay_atm_account' # 取得請款資訊後，client 回傳繳費資訊(ATM)，顯示繳費資訊頁面
      res = create.aio_check_out_atm(params: base_param, url_return_payinfo: pay_info_url, exp_period: exp, client_redirect: cli_redir_url)
    end
    return res
  end

  # ecpay 物流訂單建立
  def ecpay_create
    total_price = (self.price + self.freight).to_s
    is_collection = ( self.pay_method == 'pickup_and_cash' ? 'Y' : 'N' )

    # 郵遞區號
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
      
      'ServerReplyURL' => 'https://bawan-store-0225.herokuapp.com/',
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
    res = res.sub('1|', '')

    hash = CGI::parse(res)
    return hash
  end

  # ecpay 送貨編號
  def ecpay_trade_info
    param = {
    'AllPayLogisticsID' => self.ecpay_logistics_id,
    'PlatformID' => ''
    }
    create = ECpayLogistics::QueryClient.new
    res = create.querylogisticstradeinfo(param)
    res = res.sub('1|', '')
    hash = CGI::parse(res)

    status_hash = JSON.parse(File.read('app/assets/json/logistics_status.json'))
    logistics = status_hash['LogisticsStatus'].select{ |status_hash| status_hash['logistics_subtype'] == self.logistics_subtype && status_hash['code'] == hash['LogisticsStatus'][0] }

    # if !logistics.status.blank?
    #   self.send(logistics.status) if self.send('may_' + logistics.status + '?')
    #   self.save
    # end

    if self.shipment_no.blank?
      self.shipment_no = hash['ShipmentNo'][0]
      self.save
    end
    logistics
  end

  # ↓↓↓↓↓ ecpay 收件資料驗證 ↓↓↓↓↓

  #【收件姓名】字元限制為 10 個字元(最多 5 個中文字、10 個英文字)、不可有空白，若帶有空白系統自動去除
  def self.receiver_name_format(r_name)
    r_name.gsub!(/\s/, '') if !r_name.match(/\s/).nil? # 有空白則去空白

    if (r_name =~ /\p{han}/).nil? # 不含中文
      raise StandardError, '收件人姓名格式錯誤(最多10個英文字)' if r_name.length > 10
    else #含中文
      if !r_name.match(/\p{^han}/).nil? # 同時含中文與其他字符
        raise StandardError, '收件人姓名格式錯誤(最多5個中文字、10個英文字)'
      else #全中文
        raise StandardError, '收件人姓名格式錯誤(最多5個中文字)' if r_name.length > 5
      end
    end
  end

  #【收件手機】只允許數字、10 碼、09 開頭
  def self.receiver_cellphone_format(r_cellphone)
    if r_cellphone.match(/\D/).nil? #不含數字外的字符
      raise StandardError, '手機格式錯誤(必須為10碼)' if r_cellphone.length != 10
      raise StandardError, '手機格式錯誤(必須為09開頭)' if r_cellphone.match(/^../)[0] != '09'
    else
      raise StandardError, '手機格式錯誤(含錯誤字元)'
    end
  end

  #【收件信箱】需含@
  def self.receiver_email_format(r_email)
    raise StandardError, '信箱格式錯誤(需含@字元)' if r_email.match(/@/).nil?
  end

  #【收件電話】允許數字+特殊符號；特殊符號僅限()-#
  def self.receiver_phone_format(r_phone)
    r_phone.gsub!(/(\()|(\))|(-)|(#)/, '') #去除合法特殊字符
    raise StandardError, '電話格式錯誤(含錯誤字元)' if !r_phone.match(/\D/).nil? #含數字外的字符
  end

  #【收件地址】制需大於 6 個字元，且不可超過 60個字元
  def self.receiver_address_format(r_address)
    raise StandardError, '地址格式錯誤(需大於6個，且不可超過60個字元)' if !r_address.length.between?(7, 60)
  end


  # 訂單流程
  include AASM

  aasm column: :status do
    state :pending, initial: true
    state :waiting_payment, :waiting_shipment #準備流程
    state :shipping, :delivered, :delivered_store, :picked_up #出貨流程
    state :waiting_refunded, :refunded, :returned, :canceled #退貨/款流程
    
    #待付款
    event :wait_payment do 
      transitions from: [:pending], to: :waiting_payment
    end

    #待出貨
    event :wait_shipment do
      transitions from: [:pending, :waiting_payment], to: :waiting_shipment
    end

    #已出貨
    event :ship do 
      transitions from: [:waiting_shipment], to: :shipping
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

    #待退款
    event :wait_refunded do 
      transitions from: [:waiting_shipment, :returned], to: :waiting_refunded
    end

    #已退款
    event :refund do
      transitions from: [:waiting_refunded], to: :refunded
    end

    #訂單取消
    event :cancel do
      transitions from: [:pending, :waiting_payment, :waiting_shipment], to: :canceled
    end

    # 已退貨（訂單結束後欲退貨）
    event :return do
      transitions from: [:delivered, :picked_up], to: :returned
    end

  end
end