class Console::OffersController < ApplicationController
  def index
    @offers_all = Offer.where(range: ['all', 'price'])
    @offers_products = Offer.where(range: 'product')
    @offer = Offer.new
  end

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
    @offer = Offer.create(offer_params)
    @offer.message = @offer.get_message
    @offer.implement = 'false'

    if @offer.offer == 'discount'
      if @offer.offer_discount.to_s.length == 1
        @offer.offer_discount = (@offer.offer_discount.to_s + '0').to_i
      end
    end
    
    if @offer.save
      redirect_to console_offers_path
    end
  end

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
    @offer.destroy

    if @category.destroyed?
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




