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
      @total_price += item.unit_price
    end
    @cart_length = @carts.items.length
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



