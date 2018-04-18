class OrdersController < ApplicationController
  before_action :authenticate_user!

  def new

    # 按下結帳後將 cart session 中的資料存入新產生的 order session，以防結帳後再更動 cart
    @order_session = Cart.new_order_hash(session[Cart::SessionKey_order])
    @cart = Cart.from_hash(session[Cart::SessionKey_cart])
    @order_session = @cart
    session[Cart::SessionKey_order] = @order_session.to_hash

    @order = Order.new
    @order.order_items.build
  end

  def create
    @cart = Cart.from_hash(session[Cart::SessionKey_cart])
    @order_session = Cart.from_hash(session[Cart::SessionKey_order])

    @order = Order.create(order_params)
    @order.user = current_user
    @order.order_items.map{ |order_item| order_item = @order_session }

    @cart = @cart.to_hash
    @order_session = @order_session.to_hash

    if @order.save

      # 刪除購物車session中已結帳的物品
      @order_session['items'].each do |item|
        @cart['items'] = @cart['items'].dup.delete_if{|k,_| k['product_id'] == item['product_id'].to_s}
      end

      session[Cart::SessionKey_cart] = @cart
      session[Cart::SessionKey_order] = Cart.new
      redirect_to products_path
    else
      redirect_to new_order_path
    end

  end

  def index

  end

  private

  def order_params
    params.require(:order).permit!
  end

end


# 判斷cartItem數量沒有<1
# 判斷user有信箱認證過

# 列出cartItem的商品、數量、金額
# 列出cart的總金額
# 付款方式
# 運送方式
# user資料：姓名/地址/電話/信箱/



# user => address, phone, true_name, 
# order => total_price, true_name, address, phone, freight