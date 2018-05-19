class Console::CategoriesController < ApplicationController
  before_action :dashboard_authorize

  def new
    @categories = Category.all
  end

  def create
    @category = Category.find_or_create_by(name: params[:cat])
    params[:subcat].map{ |subcat| @category.subcategories.find_or_initialize_by(name: subcat, category_id: @category.id) } if params[:subcat].present?

    if @category.save
      redirect_to new_console_category_path
    else
      redirect_to products_path
    end
  end

  def edit
    @category = Category.find(params[:id])
  end

  def update
    @category = Category.find(params[:id])
    if !Category.find_by(name: cat_params[:name]).present?
      @category.update(cat_params)
      if @category.save
        flash[:notice] = '更新成功'
        redirect_to new_console_category_path
      else
        flash[:notice] = '更新失敗'
        redirect_to edit_console_category_path(@category)
      end
    else
      flash[:notice] = '更新失敗（已存在該分類）'
      redirect_to edit_console_category_path(@category)
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy if @category.subcategories.length == 0
    flash[:notice] = '刪除成功' if @category.destroyed?
    redirect_to new_console_category_path
  end

  def subcat_edit
    @subcategory = Subcategory.find(params[:id])
  end

  def subcat_update
    @subcategory = Subcategory.find(params[:id])
    if !@subcategory.category.subcategories.find_by(name: subcat_params[:name]).present?
      @subcategory.update(subcat_params)
      if @subcategory.save
        flash[:notice] = '更新成功' 
        redirect_to new_console_category_path
      else
        flash[:notice] = '更新失敗'
      redirect_to subcat_edit_console_categories_path(@subcategory)
      end
    else
      flash[:notice] = '更新失敗（已存在該分類）'
      redirect_to subcat_edit_console_categories_path(@subcategory)
    end
  end

  def subcat_destroy
    @subcategory = Subcategory.find(params[:id])
    @subcategory.destroy if @subcategory.product.length == 0 
    flash[:notice] = '刪除成功' if @subcategory.destroyed?
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