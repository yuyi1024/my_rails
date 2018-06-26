 class OrdersController < ApplicationController
  before_action :authenticate_user!
  
  #除了from_map的方法都啟動CSRF安全性功能（預設全部方法都啟動
  protect_from_forgery with: :null_session, except: :from_map

  require 'ecpay_logistics'  

  def new #購物車頁面
    #將 cart session 中的資料存入新產生的 order session，以防結帳後再更動 cart
    if session[Cart::SessionKey_cart]["items"].length > 0
      @whole_offer = whole_store_offer
      @whole_offer = @whole_offer.id if @whole_offer.present?

      @cart_session = Cart.from_hash(session[Cart::SessionKey_cart])
      @order_session = Cart.new_order_hash(@cart_session, @whole_offer)
      session[Cart::SessionKey_order] = @order_session.to_hash
      @order = Order.new

      total_and_offer_price #計算優惠前後的價錢
      @ship_method = 'CVS'
      freight_offer #計算運費
    else
      raise StandardError, '購物車內尚無商品'
    end
  rescue StandardError => e
    redirect_back(fallback_location: root_path, alert: "#{e}")
  end

  def ship_method #選擇送貨方式
    @ship_method = params[:ship_method]
    @order_session = Cart.from_hash(session[Cart::SessionKey_order])

    total_and_offer_price #計算優惠前後的價錢
    freight_offer #計算運費
    
    @offer_price += @freight

    @action = 'ship_method'
    render 'orders/orders.js.erb'
  end

  def total_and_offer_price #計算優惠前後的價錢
    @total_price = @order_session.order_total_price
    @offer =  whole_store_offer
    if @offer.present?
      @offer_price = @offer.calc_total_price_offer(@total_price)
    else
      @offer_price = @total_price
    end
  end

  def freight_offer #計算運費
    if @offer.present?
      if @offer.range == 'all'
        @freight = 0 if @offer.offer_freight == 'all' || @offer.offer_freight == @ship_method
      elsif @offer.range == 'price'
        if @offer_price >= @offer.range_price
          @freight = 0 if @offer.offer_freight == 'all' || @offer.offer_freight == @ship_method
        end
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

  def create #前往結帳
    @order_session = Cart.from_hash(session[Cart::SessionKey_order])

    #檢查是否有商品之優惠變動
    @order_session.items.each do |item|
      raise StandardError, '部分商品優惠已過期，請重新結帳' if Product.find(item.product_id).offer_id != item.offer_id
    end
    raise StandardError, '全館優惠已過期，請重新結帳' if @order_session.offer_id != whole_store_offer

    @order = Order.create(order_params)
    @order.user = current_user
    @order.offer_id = @order_session.offer_id

    total_and_offer_price
    @order.price = @offer_price #不含運
    @order.process_id = @order.g_process_id(current_user.id, current_user.orders.length+1)

    @ship_method = order_params[:logistics_type]
    freight_offer
    @order.freight = @freight
    @order.logistics_subtype = 'TCAT' if @ship_method == 'Home'

    #將 order session 的東西存入 new 的 OrderItem 中、quantity/sold 操作
    @order_session.items.length.times{@order.order_items.build}
    @order_session.session_to_order_items(@order)

    @cart_session = session[Cart::SessionKey_cart]
    @order_session = @order_session.to_hash

    if @order.save
      # 刪除 cart session 中已結帳的物品，未結帳的不動
      @order_session['items'].each do |item|
        @cart_session['items'] = @cart_session['items'].delete_if{|key,_| key['product_id'] == item['product_id'].to_s}
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

  def edit #訂單資料填寫
    @order = Order.find_by(process_id: params[:id])
    if !params[:stName].nil?
      @stName = params[:stName]
    end
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def to_map
    order = Order.find_by(process_id: params[:process_id])
    pay = (order.pay_method == 'pickup_and_cash' ? 'Y' : 'N')

    args = {
      'MerchantTradeNo' => order.process_id,
      'ServerReplyURL' => 'http://localhost:3001/orders/from_map',
      'LogisticsType' => 'CVS',
      'LogisticsSubType' => params[:st_type],
      'IsCollection' => pay,  
      'ExtraData' => '',
      'Device' => ''
    }

    create = ECpayLogistics::QueryClient.new
    @map = create.expressmap(args)

  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def from_map
    @stType = params[:LogisticsSubType]
    @stId = params[:CVSStoreID]
    @stName = params[:CVSStoreName]
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def get_user_data #勾選同會員資料
    @order = Order.find_by(process_id: params[:process_id])
    @user = @order.user
    @action = 'get_user_data'
    render 'orders/orders.js.erb'
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def update
    @order = Order.find(params[:id])
    @order.update(order_params)
    
    if @order.pay_method == 'pickup_and_cash'
      @order.wait_shipment
    elsif @order.pay_method == 'cash_card'
      @order.paid == 'true' ? @order.wait_shipment : @order.wait_payment
    elsif @order.pay_method == 'atm'
      @order.wait_payment
    end

    if @order.save
      if @order.pay_method == 'cash_card'
        redirect_to cash_card_orders_path(@order.process_id)
      
      elsif @order.pay_method == 'atm'
        flash[:success] = '訂單建立'
        redirect_to remit_info_orders_path(@order.process_id)
      
      elsif @order.pay_method == 'pickup_and_cash'
        hash = @order.ecpay_create
        @order.ecpay_logistics_id = hash['AllPayLogisticsID'][0]

        @order.save
        flash[:success] = '訂單建立'
        redirect_to user_order_list_path
      end
    else
      raise StandardError, '訂單錯誤'
    end

  rescue StandardError => e
    redirect_back(fallback_location: edit_order_path(@order), alert: "#{e}")
  end

  def show
    @order = Order.find_by(process_id: params[:id])
    if @order.ecpay_logistics_id.present?
      @logistics_status = @order.ecpay_trade_info
      @logistics_status = @logistics_status.message
    else
      @logistics_status = '未出貨'
    end

    authorize! :read, @order
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def remit_info #匯款資訊
    @order = current_user.orders.find_by(process_id: params[:process_id])
  rescue StandardError => e 
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def remit_finish #通知已付款
    @order = current_user.orders.find_by(process_id: params[:process_id])
    info = params[:name] + '/' + params[:time].to_datetime.strftime("%Y-%m-%d %T") + '/' + params[:price]
    @order.remit_data = info
    @order.paid = 'remit'
    @order.save
    @logistics_status = '未出貨'

    @action = 'remit_finish'
    render 'orders/orders.js.erb'
  end

  def cash_card #信用卡付款頁面
    @order = Order.find_by(process_id: params[:process_id])
    total_price = (@order.price + @order.freight).to_s
    @client_token = Braintree::ClientToken.generate
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def paid #信用卡付款認證
    @order = Order.find_by(process_id: params[:process_id])
    result = Braintree::Transaction.create(
      :amount => @order.price + @order.freight,
      :payment_method_nonce => params[:payment_method_nonce],
      :customer_id => @order.user.id,
      :custom_fields => {
      :process_id => @order.process_id
      }
    )

    if result
      @order.pay
      @order.paid = 'true'

      hash = @order.ecpay_create
      @order.ecpay_logistics_id = hash['AllPayLogisticsID'][0]
      
      if @order.logistics_type == 'CVS'
        @order.shipment_no = hash['CVSPaymentNo'][0]
      elsif @order.logistics_type == 'Home'
        @order.shipment_no = hash['BookingNote'][0]
      end

      if @order.save
        flash[:success] = '信用卡付款成功'
      end
    end
    redirect_to cash_card_orders_path(@order.process_id)
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def whole_store_offer #實施中的全館優惠
    offer = Offer.where(range: ['all', 'price'], implement: 'true').first
    if offer.nil?
      offer
    else
      offer.id
    end
  end

  private

  def order_params
    params.require(:order).permit!
  end

end