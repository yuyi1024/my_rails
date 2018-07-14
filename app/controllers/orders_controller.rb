 class OrdersController < ApplicationController
  before_action :authenticate_user!
  
  #除了from_map的方法都啟動CSRF安全性功能（預設全部方法都啟動
  protect_from_forgery with: :null_session, except: :from_map

  require 'ecpay_logistics'  

  def new #購物車頁面
    #將 cart session 中的資料存入新產生的 order session，以防結帳後再更動 cart
    if session[Cart::SessionKey_cart]["items"].length > 0
      @whole_offer = whole_store_offer

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
    @location = params[:location]
    @ship_method = params[:ship_method]

    if @location == 'new'
      @order_session = Cart.from_hash(session[Cart::SessionKey_order])

      total_and_offer_price #計算優惠前後的價錢
      freight_offer #計算運費
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

  def total_and_offer_price #計算優惠前後的價錢
    @total_price = @order_session.order_total_price
    @offer =  whole_store_offer
    if @offer.present?
      @offer = Offer.find(@offer)
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

    total_and_offer_price
    @order.price = @offer_price #不含運
    @order.process_id = @order.g_process_id(current_user.id, current_user.orders.length+1)

    offer = Offer.find(@order_session.offer_id)
    if offer.range == 'all'
      @order.offer_id = @order_session.offer_id
    elsif offer.range == 'price'
      @order.offer_id = @order_session.offer_id if @offer_price > offer.price
    end

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
    @location = 'edit'
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def to_map
    order = Order.find_by(process_id: params[:process_id])
    pay = (order.pay_method == 'pickup_and_cash' ? 'Y' : 'N')

    args = {
      'MerchantTradeNo' => order.process_id,
      'ServerReplyURL' => 'https://bawan-store-0225.herokuapp.com/orders/from_map',
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

    #↓↓↓↓↓愉快的判斷資料格式時間↓↓↓↓↓

    #【收件姓名】字元限制為 10 個字元(最多 5 個中文字、10 個英文字)、不可有空白，若帶有空白系統自動去除
    r_name = order_params[:receiver_name]
    r_name.gsub!(/\s/, '') if !r_name.match(/\s/).nil? #有空白則去空白

    if (r_name =~ /\p{han}/).nil? #不含中文
      raise StandardError, '收件人姓名格式錯誤(最多10個英文字)' if r_name.length > 10
    else #含中文
      if !r_name.match(/\p{^han}/).nil? #同時含中文與其他字符
        raise StandardError, '收件人姓名格式錯誤(最多5個中文字、10個英文字)'
      else #全中文
        raise StandardError, '收件人姓名格式錯誤(最多5個中文字)' if r_name.length > 5
      end
    end

    #【收件手機】只允許數字、10 碼、09 開頭
    r_cellphone = order_params[:receiver_cellphone]
    if r_cellphone.match(/\D/).nil? #不含數字外的字符
      raise StandardError, '手機格式錯誤(必須為10碼)' if r_cellphone.length != 10
      raise StandardError, '手機格式錯誤(必須為09開頭)' if r_cellphone.match(/^../)[0] != '09'
    else
      raise StandardError, '手機格式錯誤(含錯誤字元)'
    end

    #【收件信箱】需含@
    if order_params[:receiver_email].present?
      r_email = order_params[:receiver_email]
      raise StandardError, '信箱格式錯誤(需含@字元)' if r_email.match(/@/).nil?
    end
      
    #【收件電話】允許數字+特殊符號；特殊符號僅限()-#
    if order_params[:receiver_phone].present?
      r_phone = order_params[:receiver_phone]
      r_phone.gsub!(/(\()|(\))|(-)|(#)/, '') #去除合法特殊字符
      raise StandardError, '電話格式錯誤(含錯誤字元)' if !r_phone.match(/\D/).nil? #含數字外的字符
    end

    #【收件地址】制需大於 6 個字元，且不可超過 60個字元。
    if order_params[:receiver_address].present?
      r_address = order_params[:receiver_address]
      raise StandardError, '地址格式錯誤(需大於6個，且不可超過60個字元)' if !r_address.length.between?(7, 60)
    end

    #↑↑↑↑↑判斷結束↑↑↑↑↑↑

    @order.update(order_params)
    
    if @order.pay_method == 'pickup_and_cash'
      @order.wait_shipment
    
    elsif @order.pay_method == 'cash_card'
      if @order.paid == 'true' && @order.may_wait_shipment?
        @order.wait_shipment
      else
        @order.wait_payment if @order.may_wait_payment?
      end
    
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
    @refund = @order.remittance_infos.where(transfer_type: 'refund', checked: 'true').first
    @remittance_info = RemittanceInfo.new
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
    @order = Order.find_by(process_id: params[:process_id])
    @remit = @order.remittance_infos.create(remittance_info_params)
    @remit.transfer_type = 'remit'
    @order.wait_check
    if @remit.save && @order.save
      flash[:success] = '通知付款成功'
      redirect_to order_path(@order.process_id)
    else
      raise StandardError, '通知付款失敗'
    end
    rescue StandardError => e 
      redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def cash_card #信用卡付款頁面
    @order = Order.find_by(process_id: params[:process_id])
    raise StandardError, '已付款' if @order.paid == 'true'
    total_price = (@order.price + @order.freight).to_s
    @client_token = Braintree::ClientToken.generate
  rescue StandardError => e
    redirect_to(user_order_list_path, alert: "#{e}")
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

  def order_revise
    @order = Order.find_by(process_id: params[:process_id])
    @location = 'revise'
    @freight = Order::Freight_in_store
    @remittance_info = RemittanceInfo.new
  rescue StandardError => e
    redirect_back(fallback_location: user_order_list_path, alert: "#{e}")
  end

  def order_update
    @order = Order.find_by(process_id: params[:process_id])
    @order.update(order_params)
    if order_params[:logistics_type] == 'Home'
      @order.logistics_subtype = 'TCAT'
    else
      @order.logistics_subtype = ''
    end
    
    @offer = @order.offer
    @ship_method = order_params[:logistics_type]
    freight_offer
    @order.freight = @freight
    @order.status = 'pending'
    @order.ecpay_logistics_id = ''
    @order.save
    redirect_to edit_order_path(@order.process_id)
  end

  def order_cancel
    @order = Order.find_by(process_id: params[:process_id])
    if params[:remittance_info].present?
      @info = @order.remittance_infos.create(remittance_info_params)
      @info.transfer_type = 'refund'
      raise StandardError, '訂單取消失敗' if !@info.save
    end
    if @order.may_cancel?
      @order.cancel
      raise StandardError, '訂單取消失敗' if !@order.save
    end
    flash[:success] = '訂單取消成功'
    redirect_to user_order_list_path
  rescue StandardError => e
    redirect_to(user_order_list_path, alert: "#{e}")
  end

  private

  def order_params
    params.require(:order).permit!
  end

  def remittance_info_params
    params.require(:remittance_info).permit!
  end

end