class Console::ProductsController < Console::DashboardsController
  def index
    @products = Product.includes(:category, :subcategory)
    cat_to_select # 取得下拉可選擇的分類

    if params[:search].present?
      @action = 'search'
      @products = @products.where(id: params[:product_id]) if params[:product_id].present?
      @products = @products.where(category_id: params[:cat_box]) if params[:cat_box].present? && params[:cat_box] != 'all'
      @products = @products.where(subcategory_id: params[:subcat_box]) if params[:subcat_box].present? && params[:subcat_box] != 'all'
      @products = @products.keyword(keyword_split(['name', 'description'], params[:keyword])) if params[:keyword].present?
      @products = @products.where(status: params[:status]) if params[:status].present?
    end

    @products = @products.order('products.' + (params[:sort_item] ||= 'created_at')+ ' ' + (params[:sort_order] ||= 'DESC'))
    @products = kaminari_page(@products)
    render 'console/products/products.js.erb' if params[:search].present?
  end

  def new
    # 如果次分類不存在需先新增
    if Subcategory.first.present?
      @product = Product.new
      cat_to_select
      subcat_to_select(@categories[0][1])
    else
      redirect_to(new_console_category_path, alert: '請先新增至少一種分類！')
    end
  end

  def create
    raise StandardError, '商品價錢或庫存數量小於 1' if product_params[:price].to_i < 1 || product_params[:quantity].to_i < 1
    @product = Product.create(product_params)
    @product.status = 'off_shelf'

    warehouse = Warehouse.where(room: warehouse_params[:warehouse][:room], shelf: warehouse_params[:warehouse][:shelf], row: warehouse_params[:warehouse][:row].to_i, column: warehouse_params[:warehouse][:column].to_i).first
    warehouse ||= Warehouse.create(warehouse_params[:warehouse]) # x = 123 unless x
    @product.warehouse = warehouse

    # 若該商品子分類有優惠則套用
    Offer.where(range: 'product', implement: 'true').each do |offer|
      # 若作用分類存在則以","分割，並檢查是否 include 商品分類
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
  rescue StandardError => e
    redirect_back(fallback_location: console_products_path, alert: "#{e}")
  end

  def update
    raise StandardError, '商品價錢小於 1' if product_params[:price].to_i < 1
    @product = Product.find(params[:id])
    @product.update(product_params)

    # 刪除所有該商品的追蹤
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

  def get_subcat # 選擇主分類後顯示次分類
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

  private
  
  def cat_to_select # 主分類 select_box
    @categories = Category.all
    @categories = @categories.map{ |cat| [cat.name, cat.id] }
  end

  def subcat_to_select(cat_id = nil) # 次分類 select_box
    @subcategories = Subcategory.where(category_id: cat_id)
    @subcategories =  @subcategories.map{ |subcat| [subcat.name, subcat.id] }
  end

  def product_params
    params.require(:product).permit(:name, :price, :quantity, :quantity_alert, :category_id, :subcategory_id, :summary, :description)
  end

  def warehouse_params
    params.require(:product).permit(warehouse: [:room, :shelf, :row, :column])
  end
end