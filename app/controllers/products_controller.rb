class ProductsController < ApplicationController
  
  def index # 首頁
    @products = Product.where(status: 'on_shelf')
    @cat1s = Category.joins(:product).select('categories.id', 'categories.name').where('products.status': 'on_shelf').group('id').order('id ASC')

    # ↓↓↓ search begin ↓↓↓
    if params[:cat1_field].present?
      cat1 = Category.find_by(name: params[:cat1_field])
      @cat2s = cat1.subcategories.joins(:product).group('subcategories.id').having('count(subcategory_id) > 0')
      @products = cat1.product.where(status: 'on_shelf')
    end

    if params[:cat2_field].present?
      @products = @products.where(:subcategory => params[:cat2_field])
    end

    if params[:price_top].present?
      params[:price_bottom] = 0 if !params[:price_bottom].present?
      @products = @products.price_search(params[:price_bottom],params[:price_top])
    elsif params[:price_bottom].present?
      @products = @products.price_top(params[:price_bottom])
    end

    @products = @products.keyword(keyword_split(['name', 'description'] ,params[:keyword])) if params[:keyword].present?

    if params[:sort_item].present? && params[:sort_order].present?
      @products = @products.order(params[:sort_item] + ' ' + params[:sort_order])
    else
      @products = @products.order('sold DESC')
    end
    # ↑↑↑ search end ↑↑↑

    @cat2_click = params[:cat2_click]

    params[:page] = 1 if !params[:page].present?
    @products = @products.page(params[:page]).per(24)

    @favorites = current_user.favorites if current_user.present?
    
    @action = __method__.to_s
    
    respond_to do |format|
      format.html
      format.js
    end

  end

  def show # 商品詳細頁
    @product = Product.where(status: 'on_shelf').find_by_id(params[:id])
    if @product.present?
      @product.increment(:click_count)
      @product.save
      @offer = Offer.where.not(range: 'product').find_by(implement: 'true')
    else
      redirect_to(root_path, alert: '該商品不存在')
    end
  end

  def heart # 商品追蹤
    favorite = current_user.favorites
    @product = Product.find(params[:id])

    if favorite.find_by(product_id: @product.id).present?
      favorite.find_by(product_id: @product.id).destroy
      @heart = 'remove'
    else
      if favorite.length <= 10
        favorite = current_user.favorites.new(product_id: @product.id) 
        favorite.save
        @heart = 'add'
      else
        @heart = 'full' # 追蹤數量超過十筆
      end
    end

    @action = __method__.to_s
    render 'products/index.js.erb'
  end

  def index_with_params # 首頁url帶分類params
    cats = Category.joins(:product).select('categories.id', 'categories.name').where('products.status': 'on_shelf').group('id').order('id ASC')
    cat = cats.index(cats.find(params[:cat]))
    subcat = params[:subcat]
    redirect_to root_path(cat: cat, subcat: subcat)
  end

end
