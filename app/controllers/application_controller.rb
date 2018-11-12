class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  #CSRF protection，需放在最前，若不，可用prepend：true前置
	before_action :configure_permitted_parameters, if: :devise_controller?

  # 是否有未結帳訂單
  def order_pending
    if current_user
      @pending = current_user.orders.where(status: 'pending').length
    else
      @pending = 0
    end
  end

  # 購物車顯示
  def cart_show
    @carts = Cart.from_hash(session[Cart::SessionKey_cart])
    
    @cart_items = []
    @total_price = 0
    
    products = Product.where(status: 'on_shelf', id: [] << @carts.items.map{|i| i.product_id})
    @carts.items.each do |item|
      product = products.select{|p| p.id == item.product_id.to_i}
      if product.present?
        @cart_items << [ product[0], item.quantity ]
      else
        @carts.items.delete(item) # 找不到購物車中的商品或商品下架則刪除
      end
    end
    session[Cart::SessionKey_cart] = @carts.to_hash
    
    @cart_length = @cart_items.length
    @offer = Offer.where(range: ['all', 'price'], implement: 'true').first
    
  end

  # 關鍵字查詢以' '分割
  def keyword_split(cols, k, table)
    keyword = k.split(' ')
    sql = ''
    cols.each do |col|
      m = keyword.reduce(''){ |memo, obj| memo += table + "." + col + " LIKE '%"+ obj + "%' AND " }
      sql += '(' + m.chomp(' AND ') + ')' + ' OR '
    end
    sql = sql.chomp(' OR ')
    # User.where("(name LIKE '%b%' AND name LIKE '%n%') OR (email LIKE '%b%' AND email LIKE '%n%')")
  end

  # ↓↓↓↓↓ 錯誤處理 ↓↓↓↓↓

  #devise 認證沒過(未登入)
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    redirect_back(fallback_location: root_path, notice: '沒有權限執行此操作')
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



