class ImagesController < ApplicationController
  def create
  	@image = Image.new(image_params)
  	@image.save

    respond_to do |format|
    	format.json { render :json => { url: @image.image_url, id: @image.id } }
  	end
  end

  def destroy
  	@image = Image.find(params[:id])

  	@image.remove_image! # 刪除檔案
  	@image.save
  	
  	@image.destroy # 刪除DB資料

  	respond_to do |format|
    	format.json { render :json => { status: :ok } }
  	end
	end

  private
  def image_params
	  params.require(:image).permit!
	end
end
