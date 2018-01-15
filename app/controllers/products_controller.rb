class ProductsController < ApplicationController
  def index
    @products = Product.all
    @cat1s = Category.select(:cat1).distinct
    
    if params[:cat1_field].present?
      @cat2s = Category.where(cat1: params[:cat1_field])
      puts @cat2s.first.cat2
    end
    
    respond_to do |format|
      format.html
      format.js
    end

  end

  def show
    @product = Product.find(params[:id])
  end

  private


end
