class ProductsController < ApplicationController
  before_action :authenticate_user!, only: [:update]

  def index
    
    @products = Product.all
    @cat1s = Category.all
        
    if params[:cat1_field].present?
      cat1 = Category.find_by(name: params[:cat1_field])
      @cat2s = cat1.subcategory
      @products = cat1.product
    end

    if params[:cat2_field].present?
      @products = @products.where(:subcategory => params[:cat2_field])
    end

    if params[:price_top].present?
      params[:price_bottom] = 0 if !params[:price_bottom].present?
      @products = @products.price_search(params[:price_bottom],params[:price_top])
    elsif params[:price_bottom].present?
      @products = @products.price_top(params[:price_bottom])
    end

    if params[:keyword].present?
      keyword = params[:keyword].split(' ')
      keyword = keyword.reduce(''){ |memo, obj| memo += "name LIKE '%"+ obj + "%' AND " }
      keyword = keyword.chomp(' AND ')
      @products = @products.keyword(keyword)
    end

    @cat2_click = params[:cat2_click]

    params[:page] = 1 if !params[:page].present?
    @products = @products.page(params[:page]).per(24)
    
    respond_to do |format|
      format.html
      format.js
    end

  end

  def show
    @product = Product.find(params[:id])

  end
end