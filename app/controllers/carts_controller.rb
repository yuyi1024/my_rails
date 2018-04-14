class CartsController < ApplicationController

  def add
    @carts = Cart.from_hash(session[:my_cart6699])
    params[:product].nil? ? quantity = 1 : quantity = params[:product][:quantity].to_i
    @carts.add_item(params[:id] ,quantity)
    session[:my_cart6699] = @carts.to_hash

    # respond_to do |format|
    #   format.html
    #   format.js
    # end
  end

  def show
    @carts = Cart.from_hash(session[:my_cart6699])
    
    @cart_items = []
    @total_price = 0
    
    @carts.items.each do |item|
      product = Product.find(item.product_id)
      @cart_items << [ product, item.quantity ]
      @total_price += (product.price*item.quantity)
    end
  end

  def destroy
    @cart = Cart.from_hash(session[:my_cart6699])

    @cart.items.map{ |item| 
      @cart.items.delete(item) if item.product_id == params[:format] 
    }

    session[:my_cart6699] = @cart.to_hash

  end

end
