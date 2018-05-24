class Console::DashboardsController < ApplicationController
  def index

    authorize! :dashboard, :all

    t = Time.now
    @orders = Order.where("created_at > ?", t.days_ago(30)).order('created_at DESC')
    @messages = Message.all
    
    @y_order = Order.where(created_at: t.all_year)
    @m_order = Order.where(created_at: t.all_month)
    @w_order = Order.where(created_at: t.all_week)
    @d_order = Order.where(created_at: t.all_day)

    @product_click = Product.all.order('click_count DESC').limit(10)
    @product_buy = OrderItem.select("COUNT(order_items.product_id) AS total, order_items.product_id").group('product_id').order('total DESC').limit(10)
    @favorites = Favorite.select("COUNT(favorites.product_id) AS total, favorites.product_id").group('product_id').order('total DESC').limit(10)

  end
end
