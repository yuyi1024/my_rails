class ImagesController < ApplicationController
  def create
  	@image = Image.new(image_params)
    @image.save

    respond_to do |format|
    	format.json { render :json => { url: @image.image_url, id: @image.id } }
  	end
  end



  private
  def image_params
	  params.require(:image).permit!
	end
end
