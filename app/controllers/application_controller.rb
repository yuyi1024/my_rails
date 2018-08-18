class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  #CSRF protection，需放在最前，若不，可用prepend：true前置

	before_action :configure_permitted_parameters, if: :devise_controller?
	before_action :cart_show, :order_pending

  def order_pending
    if current_user
      @pending = current_user.orders.where(status: 'pending').length
    else
      @pending = 0
    end
  end

  def cart_show
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    
    @cart_items = []
    @total_price = 0

    @carts.items.each do |item|
      product = Product.where(status: 'on_shelf').find_by_id(item.product_id) #找不到時回傳nil
      if !product.nil?
        @cart_items << [ product, item.quantity]
      else
        @carts.items.delete(item)
      end
    end
    session[Cart::SessionKey_cart] = @carts.to_hash
    
    @cart_length = @cart_items.length
    @offer = Offer.where(range: ['all', 'price'], implement: 'true').first
    
  end

  def self.keyword_split(cols, k) #關鍵字以' '分割
    keyword = k.split(' ')
    sql = ''
    cols.each do |col|
      m = keyword.reduce(''){ |memo, obj| memo += col + " LIKE '%"+ obj + "%' AND " }
      sql += '(' + m.chomp(' AND ') + ')' + ' OR '
    end
    sql = sql.chomp(' OR ')
    # User.where("(name LIKE '%b%' AND name LIKE '%n%') OR (email LIKE '%b%' AND email LIKE '%n%')")
  end

  #cancancan 認證沒過
  rescue_from CanCan::AccessDenied do |exception|
    redirect_back(fallback_location: root_path, notice: '沒有權限執行此操作')
  end

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
  end
end



