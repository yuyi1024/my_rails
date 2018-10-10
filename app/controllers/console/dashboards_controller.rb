class Console::DashboardsController < ApplicationController
  layout "console"
  before_action :dashboard_authorize

  def index
    t = Time.now

    orders = Order.all
    products = Product.all

    @orders = orders.sort_by{|o| o.created_at}.reverse[0..9]
    @waiting = orders.select{|o| o.status == 'waiting_refunded'}.sort_by{|o| o.created_at}.reverse[0..9]
    @quantity_alert_products = products.select{|p| p.quantity < p.quantity_alert}
    @messages = Message.where(qanda: [nil, '']).order('created_at DESC').limit(10)

    # 圓餅圖
    @y_order = orders.select{|o| t.all_year.include?(o.created_at)}
    @m_order = orders.select{|o| t.all_month.include?(o.created_at)}
    @w_order = orders.select{|o| t.all_week.include?(o.created_at)}
    @d_order = orders.select{|o| t.all_day.include?(o.created_at)}
    
    @product_click = products.select{|p| p.click_count > 0}.sort_by{|p| -p.click_count}[0..9]
    @product_buy = products.select{|p| p.sold > 0}.sort_by{|p| -p.sold}[0..9]

    @favorites = Favorite.select("COUNT(favorites.product_id) AS total, favorites.product_id").group('product_id').order('total DESC')
    @favorites.includes(:product).map{ |f| Favorite.where(product_id: f.product_id).destroy_all if !f.product.present? || f.product.status == 'off_shelf' }
  end

  def kaminari_page(o) #分頁
    @rows = o.count
    params[:page] ||= 1
    object = o.page(params[:page]).per(25)
    return object
  end

  private

  def dashboard_authorize
    authorize! :dashboard, :all
  end
end
