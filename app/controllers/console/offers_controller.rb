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
 
    if @offer.save
      redirect_to console_offers_path
    end
  end

  def implement_all
    
  end

  def implement_product
    
  end

  private

  def offer_params
    params.require(:offer).permit!
  end
end




