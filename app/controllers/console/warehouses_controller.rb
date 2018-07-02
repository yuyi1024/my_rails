class Console::WarehousesController < Console::DashboardsController
  def index
    @products = Product.includes(:warehouse)
    @rooms = Warehouse.select('DISTINCT room').map{|room| [room.room, room.room]}

    if params[:search].present?
      @action = 'search'

      @products = @products.where(id: params[:product_id]) if params[:product_id].present?
      @products = @products.keyword(ApplicationController.keyword_split(['name', 'description'], params[:keyword])) if params[:keyword].present?
      
      if params[:quantity_status].present?
        if params[:quantity_status][0] == 'shortage'
          @products = @products.where('quantity <= quantity_alert')
        elsif params[:quantity_status][0] == 'enough'
          @products = @products.where('quantity > quantity_alert')
        end
      end

      @products = @products.where(:warehouses => {:room => params[:room]}) if params[:room].present? && params[:room] != 'all'
      @products = @products.where(:warehouses => {:shelf => params[:shelf]}) if params[:shelf].present?
      @products = @products.where(:warehouses => {:row => params[:row]}) if params[:row].present?
      @products = @products.where(:warehouses => {:column => params[:column]}) if params[:column].present?

      @products = @products.order(params[:sort_item] + ' ' + params[:sort_order]) if params[:sort_item].present? && params[:sort_order].present?

      kaminari_page

      render 'console/warehouses/warehouses.js.erb'
    end
    @products = @products.order('quantity ASC')
    kaminari_page
  end

  def edit
    @product = Product.find(params[:id])
    @warehouse = @product.warehouse
  rescue StandardError => e
    redirect_back(fallback_location: console_warehouses_path, alert: "#{e}")
  end

  def update
    @product = Product.find(params[:id])
    @product.update(product_params)

    warehouse = Warehouse.where(room: warehouse_params[:warehouse][:room], shelf: warehouse_params[:warehouse][:shelf], row: warehouse_params[:warehouse][:row].to_i, column: warehouse_params[:warehouse][:column].to_i).first
    warehouse ||= Warehouse.create(warehouse_params[:warehouse])
    @product.warehouse = warehouse

    if @product.save
      flash[:success] = '庫存更新成功'
      redirect_to edit_console_warehouse_path(@product)
    else
      raise StandardError, '庫存更新失敗'
    end
  rescue StandardError => e
    redirect_back(fallback_location: console_warehouses_path, alert: "#{e}")
  end

  def new
    @rooms = Warehouse.all.group_by(&:room)  
  end

  def kaminari_page #分頁
    @rows = @products.length
    params[:page] = 1 if !params[:page].present?
    @products = @products.page(params[:page]).per(25)
  end

  private

  def product_params
    params.require(:product).permit(:quantity, :quantity_alert)
  end

  def warehouse_params
    params.require(:product).permit(warehouse: [:room, :shelf, :row, :column])
  end

end
