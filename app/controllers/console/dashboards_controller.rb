class Console::DashboardsController < ApplicationController
  layout "console"
  def index

    authorize! :dashboard, :all

    t = Time.now
    @orders = Order.where("created_at > ?", t.days_ago(30)).order('created_at DESC').limit(10) #30天內
    @messages = Message.where(qanda: [nil, '']).where("created_at > ?", t.days_ago(30)).order('created_at DESC').limit(10)
    
    @y_order = Order.where(created_at: t.all_year)
    @m_order = Order.where(created_at: t.all_month)
    @w_order = Order.where(created_at: t.all_week)
    @d_order = Order.where(created_at: t.all_day)

    @product_click = Product.where.not(click_count: 0).order('click_count DESC').limit(10)
    # @product_buy = OrderItem.select("COUNT(order_items.product_id) AS total, order_items.product_id").group('product_id').order('total DESC').limit(10)
    @product_buy = Product.where.not(sold: 0).order('sold DESC').limit(10)

    Favorite.all.each do |f|
      f.destroy if !f.product.present? || f.product.status == 'off_shelf'
    end
    @favorites = Favorite.select("COUNT(favorites.product_id) AS total, favorites.product_id").group('product_id').order('total DESC').limit(10)

    @quantity_alert_products = Product.where('quantity < quantity_alert')
  end
end
