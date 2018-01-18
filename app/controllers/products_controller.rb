class ProductsController < ApplicationController
  def index
    @products = Product.all
    @cat1s = Category.select(:cat1).distinct
    
    if params[:cat1_field].present?
      @cat2s = Category.where(cat1: params[:cat1_field])
      @items = Category.where(cat1: params[:cat1_field])
    end

    if params[:cat2_field].present?
      @items = Category.where(cat1: params[:cat1_field],cat2: params[:cat2_field])



      @www = Product.includes(:category).where( :categories => { :cat1 => params[:cat1_field], :cat2 => params[:cat2_field] } ).where("price between ? and ?",params[:price_bottom],params[:price_top])

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


