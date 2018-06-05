class Console::OffersController < ApplicationController
  def index
    @offers_all = Offer.where(range: ['all', 'price'])
    @offers_products = Offer.where(range: 'product')

    @offer = Offer.new
  end

  def create
    @offer = Offer.create(offer_params)
    @offer.message = @offer.get_message
    @offer.implement = 'false'
 
    if @offer.save
      redirect_to console_offers_path
    end
  end

  private

  def offer_params
    params.require(:offer).permit!
  end
end




