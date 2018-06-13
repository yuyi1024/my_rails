module ApplicationHelper

  def user_role(role)
    if role == 'admin'
      '（管理者）'
    elsif role == 'employee'
      '（員工）'
    end
  end

  def role_color(role)
    if role == 'admin'
      'admin_color'
    elsif role == 'employee'
      'employee_color'
    end
  end

  def order_status_color(status)
    if status == 'waiting_shipment' || status == 'paid'
      status_color = 'status_red'
    elsif status == 'waiting_payment'
      status_color = 'status_blue'
    end
    status_color
  end

  def is_favorite(favorite, id)
    'favorite' if favorite.find_by(product_id: id)
  end

  def king(index)
    if index < 3
      content_tag(:span, nil, class: 'glyphicon glyphicon-king')
    end
  end

  # 計算每樣商品之單價優惠後的金額
  def calc_price_offer(price, offer_id)
    offer = Offer.find(offer_id)
    
    if offer.range_quantity == 1
      if offer.offer == 'discount'
        price = (price * (offer.offer_discount / 100.0)).ceil
      elsif offer.offer == 'price'
        price = price - offer.offer_price
      end
    end
    price
  end

  # 計算cart內每樣商品之小計金額
  def calc_cart_offer(product_id, quantity)
    product = Product.find(product_id)
    offer = product.offer

      if offer.offer == 'discount'
        value = quantity / offer.range_quantity
        remainder = quantity % offer.range_quantity
        
        price = ((product.price * offer.range_quantity * (offer.offer_discount / 100.0)) * value).ceil
        price += (product.price * remainder)

      elsif offer.offer == 'price'
        value = quantity / offer.range_quantity
        price = product.price * quantity - offer.offer_price * value
      end
    price
  end
end









