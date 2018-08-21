class CartsController < ApplicationController

  # show 在 application_controller

  def add # add product to cart
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    
    # params[:product]：加購物車時帶有數量參數 / params[:id]：加購物車時未帶數量參數，預設1
    params[:product].nil? ? quantity = 1 : quantity = params[:product][:quantity].to_i
    @carts.add_item(params[:id] ,quantity, nil, nil)
    session[Cart::SessionKey_cart] = @carts.to_hash

    @product = Product.find(params[:id])
    cart_to_array
  end

  def change # change product quantity
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    cart_quantity = params[:quantity].to_i
    product_quantity = Product.find(params[:id]).quantity

    if cart_quantity < 1
      cart_quantity = 1
    elsif cart_quantity > product_quantity
      cart_quantity = product_quantity
    end

    @carts.change_quantity(params[:id], cart_quantity)
    session[Cart::SessionKey_cart] = @carts.to_hash
    cart_to_array
  end

  def destroy # destroy product from cart
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])

    @carts.items.map{ |item| 
      if item.product_id == params[:format]
        @carts.items.delete(item)
        @product = Product.find(params[:format])
      end
    }

    session[Cart::SessionKey_cart] = @carts.to_hash
    cart_to_array
  end

  private

  def cart_to_array # 將 cart 內容存入 array
    @cart_items = []
    @cart_length = @carts.items.length
    @carts.items.each do |item|
      product = Product.find(item.product_id)
      @cart_items << [ product, item.quantity ]
    end

    # caller 的 method name
    @action = caller_locations.first.label
    render 'carts/carts.js.erb'
  end

end
