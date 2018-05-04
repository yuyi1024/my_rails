class CartsController < ApplicationController

  #show 在 application_controller

  def add
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    params[:product].nil? ? quantity = 1 : quantity = params[:product][:quantity].to_i
    @carts.add_item(params[:id] ,quantity, Product.find(params[:id]).price)
    session[Cart::SessionKey_cart] = @carts.to_hash

    @add_item = Product.find(params[:id]).name
    cart_to_array
  end

  def change
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    cart_quantity = params[:quantity].to_i
    product_quantity = Product.find(params[:id]).quantity

    if cart_quantity < 1
      cart_quantity = 1
    elsif cart_quantity > product_quantity
      cart_quantity = product_quantity
    end

    @carts.change_quantity(params[:id], cart_quantity)
    puts @carts.items
    session[Cart::SessionKey_cart] = @carts.to_hash
    cart_to_array
  end

  def destroy
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])

    @carts.items.map{ |item| 
      @carts.items.delete(item) if item.product_id == params[:format] 
    }

    session[Cart::SessionKey_cart] = @carts.to_hash
    cart_to_array
  end

  def checkout
    @cart_session = Cart.from_hash(session[Cart::SessionKey_cart])
    @order_session = Cart.new_order_hash(@cart_session)
    session[Cart::SessionKey_order] = @order_session.to_hash
    @order = Order.new
  end

  def ship_method
    @ship_method = params[:ship_method]
    @total = Cart.from_hash(session[Cart::SessionKey_cart]).total_price
    if ship_method == 'home_delivery'
      @freight = Order::Freight_home_delivery
    else
      @freight = Order::Freight_in_store
    end
    @total += @freight
    render 'carts/carts.js.erb'
  end

  def cart_to_array
    @cart_items = []
    @total_price = 0
    @cart_length = @carts.items.length
    
    @carts.items.each do |item|
      product = Product.find(item.product_id)
      @cart_items << [ product, item.quantity, item.price ]
      @total_price += item.unit_price
    end
  end
end
