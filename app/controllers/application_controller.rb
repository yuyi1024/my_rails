class ApplicationController < ActionController::Base
	before_action :configure_permitted_parameters, if: :devise_controller?
	before_action :cart_show
  protect_from_forgery with: :exception
  

  def cart_show
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    
    @cart_items = []
    @total_price = 0
    
    @carts.items.each do |item|
      product = Product.find(item.product_id)
      @cart_items << [ product, item.quantity, item.price ]
      puts @total_price
      puts item.price
      @total_price += item.unit_price
    end
    @cart_length = @carts.items.length
  end

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
  end
end



