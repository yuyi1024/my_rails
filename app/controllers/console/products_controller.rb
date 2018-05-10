class Console::ProductsController < ApplicationController
  def index
    @products = Product.all
    @categories = Category.all
    @categories = @categories.map{ |cat| [cat.name, cat.id] }

    if params[:search].present?
      @action = 'search'
      @products = @products.where(category_id: params[:cat_box]) if params[:cat_box].present? && params[:cat_box] != 'all'
      @products = @products.where(subcategory_id: params[:subcat_box]) if params[:subcat_box].present? && params[:subcat_box] != 'all'
      
      if params[:keyword].present?
        keyword = params[:keyword].split(' ')
        keyword = keyword.reduce(''){ |memo, obj| memo += "name LIKE '%"+ obj + "%' AND " }
        keyword = keyword.chomp(' AND ')
        @products = @products.keyword(keyword)
      end

      @products = @products.where(status: params[:status]) if params[:status].present?

      if params[:sort_item].present? && params[:sort_order].present?
        @products = @products.order(params[:sort_item] + ' ' + params[:sort_order])
      end

      render 'console/products/products.js.erb'
    end

    if params[:cat].present?
      @action = 'subcat'
      if params[:cat] == 'all'
        @subcategories = []
      else
        @subcategories = Subcategory.where(category_id: params[:cat])
        @subcategories =  @subcategories.map{ |subcat| [subcat.name, subcat.id] }
      end
      render 'console/products/products.js.erb'
    end

  end
end