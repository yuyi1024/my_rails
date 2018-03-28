class ProductsController < ApplicationController
  # before_action :authenticate_user!

  def index
    @products = Product.all
    @cat1s = Category.select(:cat1).distinct
    @items = Product.includes(:category)
    
    if params[:cat1_field].present?
      @cat2s = Category.where(cat1: params[:cat1_field])
      @items = @items.cat1_search(params[:cat1_field])
    end

    if params[:cat2_field].present?
      @items = @items.cat2_search(params[:cat2_field])
    end

    if params[:price_bottom].present? && params[:price_top].present?
      @items = @items.price_search(params[:price_bottom],params[:price_top])
    elsif params[:price_bottom].present?
      @items = @items.price_top(params[:price_bottom])
    elsif params[:price_top].present?
      params[:price_bottom] = 0
      @items = @items.price_search(params[:price_bottom],params[:price_top])  
    end

    if params[:keyword].present?
      @items = @items.keyword(params[:keyword])
    end

    @cat2_click = params[:cat2_click]
    
    respond_to do |format|
      format.html
      format.js
    end

  end

  def show
    @product = Product.find(params[:id])

  end

  def update
    @product = Product.find(params[:id])
    @product.cache = rand(0..100) if params[:product][:photo].present?
    @product.update(product_params)
   
    if params[:product][:photo].present?
      render :crop
    else
      redirect_to products_path
    end
  end



  private

  def product_params
    params.require(:product).permit!
  end
end