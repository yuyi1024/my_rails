class Console::OffersController < ApplicationController
  def index
    @offers_all = Offer.where(range: ['all', 'price'])
    @offers_products = Offer.where(range: 'product')
    @offer = Offer.new
  end

  #新增時選擇優惠範圍
  def select_range 
    @range = params[:range]

    if @range == 'product'
      @cats = Category.all
      @products = Product.all
    end

    @action = 'select_range'
    render 'console/offers/offers.js.erb'
  end

  def create
    if offer_params[:range] == 'price'
      raise StandardError, '訂單金額不得小於1' if offer_params[:range_price].to_i < 1
    elsif offer_params[:range] == 'product'
      if offer_params[:range_quantity].to_i < 1
        raise StandardError, '商品數量不得小於1'
      elsif offer_params[:range_subcats].nil? && offer_params[:range_products].nil?
        raise StandardError, '未設定作用商品或分類'
      end
    end

    if offer_params[:offer] == 'price'
      raise StandardError, '折扣金額不得小於1' if offer_params[:offer_price].to_i < 1

      if offer_params[:range] == 'price'
        raise StandardError, '折扣金額大於訂單金額' if offer_params[:offer_price].to_i >= offer_params[:range_price].to_i
      
      elsif offer_params[:range] == 'product'
        if offer_params[:range_subcats].present?
          arr = offer_params[:range_subcats].split(',')
          arr.each do |subcat|
            Product.where(subcategory_id: subcat).each do |product|
              raise StandardError, '折扣金額大於部分分類之商品金額' if offer_params[:offer_price].to_i >= product.price
            end
          end
        end
        
        if offer_params[:range_products].present?
          arr = offer_params[:range_products].split(',')
          arr.each do |product|
            raise StandardError, '折扣金額大於部分商品金額' if offer_params[:offer_price].to_i >= Product.find(product).price
          end
        end
      end
    
    elsif offer_params[:offer] == 'discount'
      raise StandardError, '打折數錯誤' if !offer_params[:offer_discount].to_i.between?(1, 99)
    end


    @offer = Offer.create(offer_params)
    @offer.message = @offer.get_message
    @offer.implement = 'false'

    #優惠類型為打折時，將折數以兩位數儲存
    if @offer.offer == 'discount'
      if @offer.offer_discount.to_s.length == 1
        @offer.offer_discount = (@offer.offer_discount.to_s + '0').to_i
      end
    end
    
    if @offer.save
      flash[:success] = '優惠新增成功'
    else
      raise StandardError, '優惠新增失敗'
    end
  rescue StandardError => e
    flash[:alert] = "發生錯誤：#{e}"
  ensure
    redirect_to console_offers_path
  end

  #實施全館優惠
  def implement_all
    Offer.where.not(range: 'product').update_all(implement: 'false')
    if params[:all][0] != 'N'
      offer = Offer.find_by(id: params[:all])
      offer.implement = 'true'
      offer.save
    end
    
    @action = 'implement_all'
    render 'console/offers/offers.js.erb'
  end

  #實施商品優惠
  def implement_product
    offers = Offer.where(id: params[:products])
    @repeat = [false, false]    

    #判斷是否有重複設定offer之商品
    ['subcats', 'products'].each_with_index do |range, index_a|
      arrs = []
      offers.map{|offer| arrs << offer.send('range_' + range).split(',')}

      arrs.each_with_index do |arr, index|
        (index+1..arrs.length-1).to_a.each do |i|
          l = arr - arrs[i] 
          @repeat[index_a] = true if l.length != arr.length
          break if @repeat[index_a] == true
        end
        break if @repeat[index_a] == true
      end
    end

    #若沒有重複，更新資料
    if !@repeat.include? true 
      Product.update_all(offer_id: nil)
      Offer.where(range: 'product').update_all(implement: 'false')

      ['subcats', 'products'].each do |range|
        offers.each do |offer|
          arrs = offer.send('range_' + range).split(',')
          arrs.each do |arr|
            if range == 'subcats'
              Subcategory.find(arr.to_i).product.update_all(offer_id: offer.id)
            elsif range == 'products'
              Product.find(arr.to_i).update(offer_id: offer.id)
            end
          end
        end
      end
      offers.update_all(implement: 'true')
    end

    @action = 'implement_product'
    render 'console/offers/offers.js.erb'
  end

  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy if @offer.implement != 'true'
    
    if @offer.destroyed?
      flash[:notice] = '刪除成功'
    else
      flash[:notice] = '刪除失敗'
    end
    redirect_to console_offers_path
  end

  private

  def offer_params
    params.require(:offer).permit!
  end
end




