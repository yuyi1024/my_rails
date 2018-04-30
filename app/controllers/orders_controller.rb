 class OrdersController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session, only: [:ezship]

  def new
    # 按下結帳後將 cart session 中的資料存入新產生的 order session，以防結帳後再更動 cart
    @cart_session = Cart.from_hash(session[Cart::SessionKey_cart])
    @order_session = Cart.new_order_hash(@cart_session)
    session[Cart::SessionKey_order] = @order_session.to_hash

    if !params[:stName].nil?
      @stName = params[:stName]
      @stCode = params[:stCode]
    end
  end

  def ship_method #選擇寄送方式並改變 total_price、收件資料 form
    @order = Order.new
    @total_price_with_ship = Cart.from_hash(session[Cart::SessionKey_cart]).total_price
    @ship_method = params[:ship_method] 
    @user = current_user if params[:user_data] == 'true'

    if @ship_method == 'in_store'
      @total_price_with_ship += Order::Freight_in_store
    elsif @ship_method == 'to_address'
      @total_price_with_ship += Order::Freight_to_address
    end
  end

  def ezship #EZship 回傳
    redirect_to new_order_path(:stName => params[:stName], :stCode => params[:stCode], :stCate => params[:stCate])
  end

  def create
    @cart_session = Cart.from_hash(session[Cart::SessionKey_cart])
    @order_session = Cart.from_hash(session[Cart::SessionKey_order])

    @order = Order.create(order_params)
    @order.user = current_user
    @order.price = @order_session.total_price #不含運
    @order.process_id = @order.g_process_id(current_user.id, current_user.orders.length+1)

    if order_params[:ship_method] == 'in_store'
      @order.freight = Order::Freight_in_store
    elsif order_params[:ship_method] == 'to_address'
      @order.freight = Order::Freight_to_address
    end

    # 將 order session 的東西存入 new 的 OrderItem 中
    @order_session.items.length.times{@order.order_items.build}
    @order_session.session_to_order_items(@order) 

    @cart_session = @cart_session.to_hash
    @order_session = @order_session.to_hash

    if @order.save

      # 刪除 cart session 中已結帳的物品，未結帳的不動
      @order_session['items'].each do |item|
        @cart_session['items'] = @cart_session['items'].delete_if{|key,_| key['product_id'] == item['product_id'].to_s}
      end

      session[Cart::SessionKey_cart] = @cart_session
      session[Cart::SessionKey_order] = Cart.new

      flash[:notice] = '訂單建立'

      if order_params[:pay_method] == 'pay_before'
        redirect_to remit_info_orders_path(@order.process_id)
      else
        redirect_to products_path
      end
      
    else
      redirect_to new_order_path
    end

  end

  def show
    @order = current_user.orders.find_by(process_id: params[:id])
    @order.status_cn
  end

  def remit_info
    @order = current_user.orders.find_by(process_id: params[:process_id])
  end

  private

  def order_params
    params.require(:order).permit!
  end

end