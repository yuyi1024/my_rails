class Offer < ApplicationRecord
	
	def get_message

		if self.range == 'all'
      msg1 = '全館'
    elsif self.range == 'price'
      msg1 = '全館滿' + self.range_price + '元'
    elsif self.range == 'product'
      if self.range_quantity == '1'
        msg1 = '本商品每件'
      else
        msg1 = '本商品' + self.range_quantity + '件'
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
      msg2 = '折' + self.offer_price + '元'
    elsif self.offer == 'discount'
      msg2 = '打' + self.offer_discount + '折'
    end

    msg1 + msg2
	end
end
