class Offer < ApplicationRecord
  has_many :products, dependent: :nullify

  # attr_accessor :subcats
  # attr_accessor :products
	
	def get_message

		if self.range == 'all'
      msg1 = '全館'
    elsif self.range == 'price'
      msg1 = '全館滿' + self.range_price.to_s + '元'
    elsif self.range == 'product'
      if self.range_quantity == 1
        msg1 = '本商品每件'
      else
        msg1 = '本商品' + self.range_quantity.to_s + '件'
      end
    end

    if self.offer == 'freight'
      if self.offer_freight == 'all'
        msg2 = '免運費'
      elsif self.offer_freight == 'CVS'
        msg2 = '超商取貨免運費'
      elsif self.offer_freight == 'Home'
        msg2 = '宅配免運費'
      end
    elsif self.offer == 'price'
      msg2 = '折' + self.offer_price.to_s + '元'
    elsif self.offer == 'discount'
      msg2 = '打' + self.offer_discount.to_s + '折'
    end

    msg1 + msg2
	end


  def check_repeat_offer
    a = ['subcats', 'products']

    arrs = []

    self.map{|offer| arrs << offer.send('range_' + a[0]).split(',')}

    length = arrs.length
    repeat = false

    arrs.each_with_index do |arr, index|
      (index+1..length-1).to_a.each do |i|
        l = arr - arrs[i] 
        repeat = true if l.length != arr.length
        break if repeat == true
      end
      break if repeat == true
    end
    repeat
  end


end









