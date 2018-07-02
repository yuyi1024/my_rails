class Console::ProductsController < Console::DashboardsController
  before_action :dashboard_authorize

  def index
    @products = Product.all
    cat_to_select

    if params[:search].present?
      @action = 'search'
      
      @products = @products.where(id: params[:product_id]) if params[:product_id].present?
      @products = @products.where(category_id: params[:cat_box]) if params[:cat_box].present? && params[:cat_box] != 'all'
      @products = @products.where(subcategory_id: params[:subcat_box]) if params[:subcat_box].present? && params[:subcat_box] != 'all'
      @products = @products.keyword(ApplicationController.keyword_split(['name', 'description'], params[:keyword])) if params[:keyword].present?
      @products = @products.where(status: params[:status]) if params[:status].present?
      @products = @products.order(params[:sort_item] + ' ' + params[:sort_order]) if params[:sort_item].present? && params[:sort_order].present?

      kaminari_page

      render 'console/products/products.js.erb'
    end
    @products = @products.order('created_at DESC')
    kaminari_page
  end

  def new
    if Subcategory.first.present?
      @product = Product.new
      cat_to_select
      subcat_to_select(Category.first.id)
    else
      redirect_to(new_console_category_path, alert: '請先新增至少一種分類！')
    end
  end

  def create
    @product = Product.create(product_params)
    raise StandardError, '商品價錢或庫存數量小於 1' if product_params[:price].to_i < 1 || product_params[:quantity].to_i < 1

    @product.status = 'off_shelf'


    warehouse = Warehouse.where(room: warehouse_params[:warehouse][:room], shelf: warehouse_params[:warehouse][:shelf], row: warehouse_params[:warehouse][:row].to_i, column: warehouse_params[:warehouse][:column].to_i).first
    warehouse ||= Warehouse.create(warehouse_params[:warehouse])
    @product.warehouse = warehouse


    #若該商品子分類有優惠則套用
    Offer.where(range: 'product', implement: 'true').each do |offer|
      if offer.range_subcats.present?
        arr = offer.range_subcats.split(',')
        if arr.include?(@product.subcategory_id.to_s)
          @product.offer_id = offer.id
        end
      end
    end
    
    if @product.save
      flash[:success] = '商品新增成功'
      redirect_to edit_console_product_path(@product)
    else
      raise StandardError, '儲存失敗'
    end
  rescue StandardError => e
    cat_to_select
    subcat_to_select(Category.first.id)
    flash[:alert] = "發生錯誤：#{e}"
    render :new
  end

  def edit
    @product = Product.find(params[:id])
    @warehouse = @product.warehouse
    cat_to_select
    subcat_to_select(@product.category_id)
    @product_offers = Offer.where(range: 'product')
  rescue StandardError => e
    redirect_back(fallback_location: console_products_path, alert: "#{e}")
  end

  def update
    @product = Product.find(params[:id])
    @product.update(product_params)

    #刪除所有該商品的追蹤
    @product.favorites.destroy_all if product_params[:status] == 'off_shelf'

    if @product.save
      flash[:success] = '更新成功'
      redirect_to edit_console_product_path 
    else
      raise StandardError
    end
    rescue StandardError => e
      redirect_back(fallback_location: console_products_path, alert: "發生錯誤：#{e}")
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

  def subcat_to_select(cat_id = nil) #次分類select_box
    @subcategories = Subcategory.where(category_id: cat_id)
    @subcategories =  @subcategories.map{ |subcat| [subcat.name, subcat.id] }
  end

  def dashboard_authorize
    authorize! :dashboard, Product
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :quantity, :quantity_alert, :category_id, :subcategory_id, :summary, :description)
  end

  def warehouse_params
    params.require(:product).permit(warehouse: [:room, :shelf, :row, :column])
  end
end