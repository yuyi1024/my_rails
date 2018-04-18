class OrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @order = Order.new
    @order.order_items.build

    @cart = Cart.from_hash(session[Cart::SessionKey])
    @total_price = @cart.items.reduce(0){ |sum, item| 
      sum + Product.find(item.product_id).price*item.quantity 
    }
  end

  def create
    @order = Order.create(order_params)
    @order.user = current_user


    if @order.save
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