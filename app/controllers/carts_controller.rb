class CartsController < ApplicationController

  #show 在 application_controller

  def add
    @carts = Cart.from_hash(session[:my_cart6699])
    params[:product].nil? ? quantity = 1 : quantity = params[:product][:quantity].to_i
    @carts.add_item(params[:id] ,quantity)
    session[:my_cart6699] = @carts.to_hash
    cart_to_array
  end

  def destroy
    @carts = Cart.from_hash(session[:my_cart6699])

    @carts.items.map{ |item| 
      @carts.items.delete(item) if item.product_id == params[:format] 
    }

    session[:my_cart6699] = @carts.to_hash
    cart_to_array
  end

  def cart_to_array
    @cart_items = []
    @total_price = 0
    
    @carts.items.each do |item|
      product = Product.find(item.product_id)
      @cart_items << [ product, item.quantity ]
      @total_price += (product.price*item.quantity)
    end
  end

end
