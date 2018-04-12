class CartsController < ApplicationController

  def add
    cart = Cart.from_hash(session[:cart6699])
    cart.add_item(params[:id])
    session[:cart6699] = cart.serialize

    redirect_to products_path, notice: 'aaaa'
  end


end
