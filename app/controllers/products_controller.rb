class ProductsController < ApplicationController
  before_action :authenticate_user!, only: [:update]

  def index
    @products = Product.all
    @cat1s = Category.all
    
    @items = Product.all
    
    if params[:cat1_field].present?
      @cat2s = Category.find_by(name: params[:cat1_field]).subcategory
      @items = Category.find_by(name: params[:cat1_field]).product
    end

    if params[:cat2_field].present?
      @items = @items.where(:subcategory => params[:cat2_field])
    end

    if params[:price_top].present?
      params[:price_bottom] = 0 if !params[:price_bottom].present?
      @items = @items.price_search(params[:price_bottom],params[:price_top])
    elsif params[:price_bottom].present?
      @items = @items.price_top(params[:price_bottom])
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