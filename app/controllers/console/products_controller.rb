class Console::ProductsController < ApplicationController
  def index
    @products = Product.all
    cat_to_select

    if params[:search].present?
      @action = 'search'
      @products = @products.where(category_id: params[:cat_box]) if params[:cat_box].present? && params[:cat_box] != 'all'
      @products = @products.where(subcategory_id: params[:subcat_box]) if params[:subcat_box].present? && params[:subcat_box] != 'all'
      @products = @products.keyword(ApplicationController.keyword_split(params[:keyword])) if params[:keyword].present?
      @products = @products.where(status: params[:status]) if params[:status].present?
      @products = @products.order(params[:sort_item] + ' ' + params[:sort_order]) if params[:sort_item].present? && params[:sort_order].present?

      kaminari_page

      render 'console/products/products.js.erb'
    end
    kaminari_page
  end

  def new
    @product = Product.new
    cat_to_select
    subcat_to_select(Category.first.id)
  end

  def create
    @product = Product.create(product_params)
    @product.status = 'off_shelf'
    if @product.save
      flash[:notice] = '新增成功' 
    else
      flash[:notice] = '新增失敗'
    end
    redirect_to edit_console_product_path(@product)
  end

  def edit
    @product = Product.find(params[:id])
    cat_to_select
    subcat_to_select(@product.category_id)
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

  def get_subcat #選擇主分類後顯示次分類
    if params[:cat].present?
      @action = 'subcat'
      @method = params[:method]
      if params[:cat] == 'all'
        @subcategories = []
      else
        subcat_to_select(params[:cat])
      end
      render 'console/products/products.js.erb'
    end
  end

  def update_photo
    @product = Product.find(params[:id])
    @product.cache = rand(0..100) if params[:product][:photo].present?
    
    @product.update(product_params) #update 後會執行 @product.crop_photo
    
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

  def destroy
    @product = Product.find(params[:id])
    @product.destroy if !@product.order_items.present?
    flash[:notice] = '刪除成功' if @product.destroyed?
    redirect_to console_products_path
  end

  def kaminari_page #分頁
    @rows = @products.length
    params[:page] = 1 if !params[:page].present?
    @products = @products.page(params[:page]).per(25)
  end

  def cat_to_select #主分類select_box
    @categories = Category.all
    @categories = @categories.map{ |cat| [cat.name, cat.id] }
  end

  def subcat_to_select(cat_id) #次分類select_box
    @subcategories = Subcategory.where(category_id: cat_id)
    @subcategories =  @subcategories.map{ |subcat| [subcat.name, subcat.id] }
  end

  private

  def product_params
    params.require(:product).permit!
  end
end