class OrdersController < ApplicationController
  before_action :authenticate_user!, except: :from_ecpay_paid
  before_action :order_auth, only: [:edit, :show, :order_revise, :to_map, :remit_info]
  
  # 除了from_map的方法都啟動CSRF安全性功能（預設全部方法都啟動
  protect_from_forgery except: [:from_map, :from_ecpay_paid]

  # ecpay金流物流串接
  require 'ecpay_logistics'
  require 'ecpay_payment'

  def order_auth # 只能查看自己的訂單
    @order = Order.find_by(process_id: params[:process_id])
    authorize! :read, @order
  end

  def new #購物車結帳頁面
    if session[Cart::SessionKey_cart]["items"].length > 0

      # 全館優惠，若存在，return offer id；若無，return nil
      @whole_offer = whole_store_offer

      # 將 cart session 中的資料存入新產生的 order session，以防結帳後再更動 cart
      @cart_session = Cart.from_hash(session[Cart::SessionKey_cart])
      @order_session = Cart.new_order_hash(@cart_session, @whole_offer)
      session[Cart::SessionKey_order] = @order_session.to_hash
      
      @order = Order.new

      total_and_offer_price # 計算優惠前後的價錢
      @ship_method = 'CVS'
      freight_offer # 計算運費
    else
      raise StandardError, '購物車內尚無商品'
    end
  rescue StandardError => e
    redirect_back(fallback_location: root_path, alert: "#{e}")
  end

  def ship_method # 選擇送貨方式
    @location = params[:location] # new(新增訂單) or revise(修改訂單)
    @ship_method = params[:ship_method]

    if @location == 'new'
      @order_session = Cart.from_hash(session[Cart::SessionKey_order])

      total_and_offer_price # 計算優惠前後的價錢
      freight_offer # 計算運費
      @offer_price += @freight

    elsif @location == 'revise'
      @order = Order.find_by(process_id: params[:process_id])
      @offer = @order.offer
      freight_offer
      @offer_price = @order.price + @freight
    end

    @action = 'ship_method'
    render 'orders/orders.js.erb'
  end

  def create # 訂單建立
    @order_session = Cart.from_hash(session[Cart::SessionKey_order])

    # 檢查是否有過期之優惠
    @order_session.items.each do |item|
      raise StandardError, '部分商品優惠已過期，請重新結帳' if Product.find(item.product_id).offer_id != item.offer_id
    end
    raise StandardError, '全館優惠已過期，請重新結帳' if @order_session.offer_id != whole_store_offer

    @order = Order.create(order_params)
    @order.user = current_user

    total_and_offer_price
    @order.price = @offer_price # 不含運之總價
    @order.process_id = @order.g_process_id(current_user.id, current_user.orders.length + 1)

    offer = Offer.find(@order_session.offer_id)
    if offer.range == 'all' || ( offer.range == 'price' && @offer_price >= offer.range_price)
      @order.offer_id = @order_session.offer_id
    end

    @ship_method = order_params[:logistics_type]
    freight_offer
    @order.freight = @freight
    @order.logistics_subtype = 'TCAT' if @ship_method == 'Home'

    # 將 order session 的東西存入 new 的 OrderItem 中、product 的 quantity/sold 操作
    @order_session.items.length.times{@order.order_items.build}
    @order_session.session_to_order_items(@order)

    @cart_session = session[Cart::SessionKey_cart]
    @order_session = @order_session.to_hash

    if @order.save
      # 刪除 cart session 中已結帳的物品，未結帳的不動
      @order_session['items'].each do |item|
        @cart_session['items'].delete_if{ |key,_| key['product_id'] == item['product_id'].to_s }
      end

      session[Cart::SessionKey_cart] = @cart_session
      session[Cart::SessionKey_order] = Cart.new

      redirect_to edit_order_path(@order.process_id)
    else
      raise StandardError, '結帳失敗'
    end
  rescue StandardError => e
    redirect_back(fallback_location: new_order_path, alert: "#{e}")
  end

  def edit # 訂單資料填寫
    @stName = params[:stName] if !params[:stName].nil?
    @location = 'edit'
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def to_map # ecpay CVS 地圖
    pay = (@order.pay_method == 'pickup_and_cash' ? 'Y' : 'N')

    args = {
      'MerchantTradeNo' => @order.process_id,
      'ServerReplyURL' => 'https://bawan-store-0225.herokuapp.com/orders/from_map',
      'LogisticsType' => 'CVS',
      'LogisticsSubType' => params[:st_type],
      'IsCollection' => pay,  
      'ExtraData' => '',
      'Device' => ''
    }

    create = ECpayLogistics::QueryClient.new
    map = create.expressmap(args) # 回傳一段能 post 到 ecpay 的 html code

    render :inline => map # inline(直接提供 erb)

  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def from_map # ecpay CVS 回傳資料
    @stType = params[:LogisticsSubType]
    @stId = params[:CVSStoreID]
    @stName = params[:CVSStoreName]
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def get_user_data # 勾選同會員資料
    @user = current_user
    @action = 'get_user_data'
    render 'orders/orders.js.erb'
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def update # 儲存訂單收件資料
    @order = Order.find_by(process_id: params[:process_id])
    receiver_data_check
    @order.update(order_params)
    
    # 根據 pay_method  更變訂單 status
    if @order.pay_method == 'pickup_and_cash'
      @order.wait_shipment
    
    elsif @order.pay_method == 'Credit' || @order.pay_method == 'ATM'
      if @order.paid == 'true'
        @order.wait_shipment if @order.may_wait_shipment?
      else
        @order.wait_payment if @order.may_wait_payment?
      end
    end

    # 根據 pay_method redirect to page
    if @order.save
      if @order.status == 'waiting_payment'
        res = @order.ecpay_payment_create
        render :inline => res
      elsif @order.pay_method == 'pickup_and_cash'
        hash = @order.ecpay_create
        @order.ecpay_logistics_id = hash['AllPayLogisticsID'][0]
        @order.save
        flash[:success] = '訂單建立'
        redirect_to user_order_list_path
      end
    else
      raise StandardError, '訂單發生錯誤'
    end
  rescue StandardError => e
    redirect_back(fallback_location: edit_order_path(@order.process_id), alert: "#{e}")
  end

  # 根據 pay_method 前往 ecpay 金流頁面
  def to_ecpay_payment
    @order = Order.find_by(process_id: params[:process_id])
    if @order.status == 'waiting_payment'
      res = @order.ecpay_payment_create
      render :inline => res
    else
      raise StandardError, '操作錯誤'
    end
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  # 信用卡付款完成後導回
  def payment_result
    @order = Order.find_by(process_id: params[:MerchantTradeNo][0..13])
    if params[:RtnCode] == '1' # 付款成功
      @order.paid = 'true'
      @order.wait_shipment if @order.may_wait_shipment?
      @order.merchant_trade_no = params[:MerchantTradeNo] if @order.merchant_trade_no != params[:MerchantTradeNo]
      
      hash = @order.ecpay_create
      @order.ecpay_logistics_id = hash['AllPayLogisticsID'][0]
      @order.save
    else
      raise StandardError, '信用卡付款失敗，請再試一次'
    end
  end

  # ATM 取號成功回傳
  def ecpay_atm_account
    @order = Order.find_by(process_id: params[:MerchantTradeNo][0..13])
    if params[:RtnCode] == '2' # 取號成功
      # 若舊的付款資料存在，則刪除舊資料
      old_info = @order.ecpay_payment_atm_info
      if old_info.present?
        if old_info.paid == false
          old_info.destroy
        else
          raise StandardError, '已付款，無法執行此操作'
        end
      end

      v_account = params[:vAccount].gsub(/(\d{4})(?=\d)/,'\1 ')
      atm_info = EcpayPaymentAtmInfo.create(bank_code: params[:BankCode], v_account: v_account, expire_date: params[:ExpireDate])
      atm_info.order = @order
      atm_info.user = @order.user
      @order.merchant_trade_no = params[:MerchantTradeNo] if @order.merchant_trade_no != params[:MerchantTradeNo]
      @order.save
      atm_info.save
      redirect_to atm_info_orders_path(@order.process_id)
    else
      raise StandardError, '取號失敗，請再試一次'
    end
  rescue StandardError => e
    redirect_to(user_order_list_path, alert: "#{e}")
  end

  # ATM 付款資料頁面
  def atm_info
    @order = Order.find_by(process_id: params[:process_id])
    @atm_info = @order.ecpay_payment_atm_info
  end

  # 買家 ATM 付款成功後回傳 
  def from_ecpay_paid
    @order = Order.find_by(process_id: params[:MerchantTradeNo][0..13])
    if params[:PaymentType][0..2] == 'ATM'
      if params[:RtnCode] == '1' # 買家 ATM 付款成功
        @order.paid = 'true'
        @order.wait_shipment if @order.may_wait_shipment?
        hash = @order.ecpay_create
        @order.ecpay_logistics_id = hash['AllPayLogisticsID'][0]
        @order.save
      end
    end
  end

  def show # 訂單詳情
    # ecpay 物流狀態信息
    if @order.ecpay_logistics_id.present?
      @logistics_status = @order.ecpay_trade_info[0]['message']
    else
      @logistics_status = '未出貨'
    end

    # 公司已退款之資訊
    @refunded_data = @order.remittance_infos.where(refunded: true).order('created_at DESC').first

  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def order_revise # 訂單修改(送貨/付款方式)
    
    @location = 'revise'
    if @order.logistics_type == 'CVS'
      @freight = @order.freight
    else
      @freight = Order::Freight_in_store
    end
    @remittance_info = RemittanceInfo.new

    # 銀行代號 select_box
    bank_hash = JSON.parse(File.read('app/assets/json/bank.json'))
    @bank_arr = []
    bank_hash['Bank'].map{ |bank| @bank_arr << bank['code'] + ' - ' + bank['name'] }
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def order_update # 訂單修改更新(送貨/付款方式)
    @order = Order.find_by(process_id: params[:process_id])
    @order.update(order_params)
    if order_params[:logistics_type] == 'Home'
      @order.logistics_subtype = 'TCAT'
    else
      @order.logistics_subtype = ''
    end
    
    @offer = @order.offer
    (@offer_price = @order.offer.range_price if @order.offer.range == 'price') if @offer
    @ship_method = order_params[:logistics_type]
    freight_offer
    @order.freight = @freight
    @order.status = 'pending'
    @order.ecpay_logistics_id = ''
    @order.save
    redirect_to edit_order_path(@order.process_id)
  end

  def order_cancel # 訂單取消
    @order = Order.find_by(process_id: params[:process_id])
    if @order.shipped != 'true'
      if @order.paid == 'true'
        if params[:remittance_info].present?
          @info = @order.remittance_infos.create(remittance_info_params)
          @order.wait_refunded
          raise StandardError, '訂單取消失敗' if !@info.save
        end
      else
        @order.cancel
      end
    end

    if @order.save 
      flash[:success] = '訂單取消成功'
      redirect_to user_order_list_path
    else
      raise StandardError, '訂單取消失敗'
    end
  rescue StandardError => e
    redirect_to(user_order_list_path, alert: "#{e}")
  end

  private

  def total_and_offer_price # 計算優惠前後的價錢
    @total_price = @order_session.order_total_price
    @offer =  whole_store_offer
    
    # 若全館優惠存在則計算優惠後價格；若無，則總價為 order session 之加總
    if @offer.present?
      @offer = Offer.find(@offer)
      @offer_price = @offer.calc_total_price_offer(@total_price)
    else
      @offer_price = @total_price
    end
  end

  def freight_offer # 計算運費
    # 若符合免運資格則 @freight = 0；否則 @freight = 預設
    if @offer.present?
      if @offer.offer_freight == 'all' || @offer.offer_freight == @ship_method
        @freight = 0 if @offer.range == 'all' || ( @offer.range == 'price' && @offer_price >= @offer.range_price )
      end
    end

    if !@freight.present?
      if @ship_method == 'Home'
        @freight = Order::Freight_home_delivery
      elsif @ship_method == 'CVS'
        @freight = Order::Freight_in_store
      end
    end
  end

  def whole_store_offer # 實施中的全館優惠
    offer = Offer.where(range: ['all', 'price'], implement: 'true').first
    if offer.nil?
      offer # nil
    else
      offer.id
    end
  end

  def receiver_data_check # 愉快的判斷資料格式時間
    Order.receiver_name_format(order_params[:receiver_name])
    Order.receiver_cellphone_format(order_params[:receiver_cellphone])
    Order.receiver_email_format(order_params[:receiver_email]) if order_params[:receiver_email].present?
    Order.receiver_phone_format(order_params[:receiver_phone]) if order_params[:receiver_phone].present?
    Order.receiver_address_format(order_params[:receiver_address]) if order_params[:receiver_address].present?
  end

  def order_params
    params.require(:order).permit!
  end

  def remittance_info_params
    params.require(:remittance_info).permit!
  end

end