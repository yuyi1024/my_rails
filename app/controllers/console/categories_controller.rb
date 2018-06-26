class Console::CategoriesController < Console::DashboardsController
  before_action :dashboard_authorize

  def new
    @categories = Category.all
  end

  def create
    @category = Category.find_or_create_by(name: params[:cat])
    params[:subcat].map{ |subcat| 
      @category.subcategories.find_or_initialize_by(name: subcat, category_id: @category.id) 
    } if params[:subcat].present?

    if @category.save
      flash[:seccess] = '分類新增成功'
      redirect_to new_console_category_path
    else
      redirect_to(new_console_category_path, alert: '分類新增失敗')
    end
  end

  #主分類
  def edit
    @category = Category.find(params[:id])
  rescue StandardError => e
    redirect_back(fallback_location: new_console_category_path, alert: "發生錯誤：#{e}")
  end

  def update
    @category = Category.find(params[:id])
    if !Category.find_by(name: cat_params[:name]).present? #是否有與更改後同名的主分類
      @category.update(cat_params)
      if @category.save
        flash[:seccess] = '更新成功'
        redirect_to new_console_category_path
      else
        raise StandardError, '更新失敗'
      end
    else
      raise StandardError, '更新失敗（已存在該分類）'
    end
  rescue StandardError => e
    redirect_back(fallback_location: edit_console_category_path(@category), alert: "發生錯誤：#{e}")
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy if @category.subcategories.length == 0
    if @category.destroyed?
      flash[:success] = '刪除成功' 
    else
      flash[:alert] = '刪除失敗' 
    end
    redirect_to new_console_category_path
  end

  #次分類
  def subcat_edit
    @subcategory = Subcategory.find(params[:id])
  rescue StandardError => e
    redirect_back(fallback_location: new_console_category_path, alert: "發生錯誤：#{e}")
  end

  def subcat_update
    @subcategory = Subcategory.find(params[:id])
    if !@subcategory.category.subcategories.find_by(name: subcat_params[:name]).present?
      @subcategory.update(subcat_params)
      if @subcategory.save
        flash[:success] = '更新成功' 
        redirect_to new_console_category_path
      else
        raise StandardError, '更新失敗'
      end
    else
      raise StandardError, '更新失敗（該主分類下已存在該次分類）'
    end
  rescue StandardError => e
    redirect_back(fallback_location: subcat_edit_console_categories_path(@subcategory), alert: "發生錯誤：#{e}")
  end

  def subcat_destroy
    @subcategory = Subcategory.find(params[:id])
    @subcategory.destroy if @subcategory.product.length == 0 
    if @subcategory.destroyed?
      flash[:success] = '刪除成功'
    else
      flash[:alert] = '刪除失敗' 
    end
    redirect_to new_console_category_path
  end

  def dashboard_authorize
    authorize! :dashboard, Category
  end

  private

  def cat_params
    params.require(:category).permit!
  end

  def subcat_params
    params.require(:subcategory).permit!
  end
end