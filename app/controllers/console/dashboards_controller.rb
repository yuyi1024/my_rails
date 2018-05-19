class Console::DashboardsController < ApplicationController
  def index

    authorize! :dashboard, :all

    t = Time.now
    @orders = Order.where("created_at > ?", t.days_ago(30)).order('created_at DESC')
    
    @y_order = Order.where(created_at: t.all_year)
    @m_order = Order.where(created_at: t.all_month)
    @w_order = Order.where(created_at: t.all_week)
    @d_order = Order.where(created_at: t.all_day)

    @product_click = Product.all.order('click_count DESC').limit(10)

    items_count = OrderItem.group(:product_id).order('count_all desc').count
    @product_buy = []
    items_count.each_with_index do |item, index|
      @product_buy << {product: Product.find(item[0]), count: item[1]}
    end

  end
end