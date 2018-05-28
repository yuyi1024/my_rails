 class OrdersController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session, only: [:ezship]

  def new #購物車頁面
    #將 cart session 中的資料存入新產生的 order session，以防結帳後再更動 cart
    if session[Cart::SessionKey_cart]["items"].length > 0
      @cart_session = Cart.from_hash(session[Cart::SessionKey_cart])
      @order_session = Cart.new_order_hash(@cart_session)
      session[Cart::SessionKey_order] = @order_session.to_hash
      @order = Order.new
    else
      redirect_back(fallback_location: root_path, notice: '購物車內尚無商品')
    end
  end

  def ship_method #選擇送貨方式
    @ship_method = params[:ship_method]
    @total = Cart.from_hash(session[Cart::SessionKey_order]).total_price
    if @ship_method == 'home_delivery'
      @freight = Order::Freight_home_delivery
    else
      @freight = Order::Freight_in_store
    end
    @total += @freight

    @action = 'ship_method'
    render 'orders/orders.js.erb'
  end

  def ezship #EZship 回傳
    redirect_to new_order_path(:stName => params[:stName], :stCode => params[:stCode], :stCate => params[:stCate])
  end

  def create #前往結帳
    @order_session = Cart.from_hash(session[Cart::SessionKey_order])

    @order = Order.create(order_params)
    @order.user = current_user
    @order.price = @order_session.total_price #不含運
    @order.process_id = @order.g_process_id(current_user.id, current_user.orders.length+1)
    if order_params[:ship_method] == 'home_delivery'
      @order.freight = Order::Freight_home_delivery
    else
      @order.freight = Order::Freight_in_store
    end

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
      redirect_to new_order_path
    end
  end

  def edit #訂單資料填寫
    @order = Order.find_by(process_id: params[:id])
    if !params[:stName].nil?
      @stName = params[:stName]
    end
  end

  def to_ezship #傳至 EZship
    @order = Order.find_by(process_id: params[:process_id])
    args = { suID: 'bonnie831024@gmail.com', processID: @order.process_id, rtURL: 'http://localhost:3001/orders/from_ezship' }
    redirect_to 'http://map.ezship.com.tw/ezship_map_web.jsp?' + args.to_query
  end

  def from_ezship #EZship 回傳
    @order = Order.find_by(process_id: params[:processID])
    if @order.ship_method == 'pickup_and_cash' || @order.ship_method == 'only_pickup'
      @order.address = params[:stCate] + params[:stCode]
      if @order.save
        redirect_to edit_order_path(@order.process_id, :stName=> params[:stName])
      end
    end
  end

  def get_user_data #勾選同會員資料
    @order = Order.find_by(process_id: params[:id])
    @chk = params[:user_data_chk]
    @user = current_user if @chk == 'on'
    @action = 'get_user_data'
    render 'orders/orders.js.erb'
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
        flash[:notice] = '訂單建立'
        redirect_to remit_info_orders_path(@order.process_id)
      elsif @order.pay_method == 'pickup_and_cash'
        flash[:notice] = '訂單建立'
        redirect_to products_path
      end
    else
      redirect_to edit_order_path(@order)
    end

  end

  def show
    @order = Order.find_by(process_id: params[:id])
    authorize! :read, @order
  end

  def remit_info #匯款資訊
    @order = current_user.orders.find_by(process_id: params[:process_id])
  end

  def cash_card #信用卡付款頁面
    @order = Order.find_by(process_id: params[:process_id])
    @client_token = Braintree::ClientToken.generate
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
      if @order.save
        flash[:notice] = '付款成功'
      end
    end
    redirect_to cash_card_orders_path(@order.process_id)
  end




  #########

  def test
    
  end

  def to_map
    order = Order.find_by(process_id: params[:process_id])
    pay = (order.pay_method == 'pickup_and_cash' ? 'Y' : 'N')

    args = { 
      MerchantID: '3076564', #廠商編號
      LogisticsType: 'CVS', #物流類型：超商取貨
      LogisticsSubType: params[:st_type], #子物流類型：7-11/全家/萊爾富
      IsCollection: pay, #是否代收
      ServerReplyURL: 'http://localhost:3001/orders/from_map'
    }
    redirect_to 'https://logistics.ecpay.com.tw/Express/map?' + args.to_query
  end

  def from_map
    @stType = params[:LogisticsSubType]
    @stId = params[:CVSStoreID]
    @stName = params[:CVSStoreName]
  end










  private

  def order_params
    params.require(:order).permit!
  end

end