class Console::OffersController < ApplicationController
  def index
    @offers_all = Offer.where(range: ['all', 'price'])
    @offers_products = Offer.where(range: 'product')

    @check_Y = @offers_products.where(implement: 'true')
    @check_N = @offers_products.where(implement: 'false')

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
 
    if @offer.save
      redirect_to console_offers_path
    end
  end

  def implement_all
    
  end

  def implement_product
    offers = Offer.where(id: params[:products])

    @repeat = [false, false]    

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

    if !@repeat.include? true
      products = Product.all
      products.each do |p|
        p.offer_id = 'null'
        p.save
        puts p.offer_id
      end

    end
    @action = 'implement_product'
    render 'console/offers/offers.js.erb'
  end

  private

  def offer_params
    params.require(:offer).permit!
  end
end




