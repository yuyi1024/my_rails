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
      
      kaminari_page

      render 'console/products/products.js.erb'
    end

    kaminari_page
    
  end

  def edit
    @product = Product.find(params[:id])
    @categories = Category.all
    @categories = @categories.map{ |cat| [cat.name, cat.id] }

    @subcategories = Subcategory.where(category_id: @product.category_id)
    @subcategories =  @subcategories.map{ |subcat| [subcat.name, subcat.id] }
  end

  def update
    @product = Product.find(params[:id])
    @product.update(product_params)
    if @product.save
      flash[:notice] = '更新成功' 
    else
      flash[:notice] = '更新失敗'
    end
    redirect_to edit_console_product_path
  end

  def update_photo
    @product = Product.find(params[:id])
    @product.cache = rand(0..100) if params[:product][:photo].present?
    
    #update 後會執行 crop_photo
    @product.update(product_params)
    
    if params[:product][:photo].present?
      render :crop
    else
      if @product.save
        flash[:notice] = '更新成功' 
      else
        flash[:notice] = '更新失敗'
      end
      redirect_to edit_console_product_path
    end

  end

  def get_subcat
    if params[:cat].present?
      @action = 'subcat'
      @method = params[:method]
      if params[:cat] == 'all'
        @subcategories = []
      else
        @subcategories = Subcategory.where(category_id: params[:cat])
        @subcategories =  @subcategories.map{ |subcat| [subcat.name, subcat.id] }
      end
      render 'console/products/products.js.erb'
    end
  end

  def kaminari_page
    @rows = @products.length
    params[:page] = 1 if !params[:page].present?
    @products = @products.page(params[:page]).per(25)
  end

  private

  def product_params
    params.require(:product).permit!
  end
end