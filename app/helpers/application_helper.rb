module ApplicationHelper

  #註冊錯誤訊息
  def registration_error_message
    return "" if resource.errors.empty?
    details = resource.errors.details
    key = details.keys[0]
    message = ''
    if key == :email
      message = '該信箱已存在，請登入以繼續操作' if details[key][0][:error] == :taken
    elsif key == :password
      message = '密碼太短，請至少包含8個字元' if details[key][0][:error] == :too_short
    elsif key == :password_confirmation
      message = '密碼認證錯誤，請重新確認密碼'
    end
    message
  end

  def user_role(role)
    if role == 'admin'
      '（管理者）'
    elsif role == 'employee'
      '（員工）'
    end
  end

  #如果商品圖片不存在顯示no-image.png
  def product_image_present(product)
    if product.photo.present?
      product.photo_url(:thumb)
    else
      'https://s3-ap-northeast-1.amazonaws.com/bawan-rails/assets/images/no-image.png'
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
    if !offer_id.nil?
      offer = Offer.find(offer_id)
      if offer.range_quantity == 1
        if offer.offer == 'discount'
          price = (price * (offer.offer_discount / 100.0)).ceil
        elsif offer.offer == 'price'
          price = price - offer.offer_price
        end
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

      elsif offer.offer == 'freight'
        price = product.price * quantity
      end
    price
  end

  #判斷總價優惠前後價格是否改變（是否有全館優惠、是否符合優惠資格、是有為freight優惠）
  def price_change_decide(sum, offer)
    price_change = false
    if offer.range == 'all' && offer.offer != 'freight'
      price_change = true
    elsif offer.range == 'price' && offer.offer != 'freight'
      price_change = true if sum >= offer.range_price
    end
    price_change
  end

  def product_quantity_alert(product)
    'quantity_red' if product.quantity <= product.quantity_alert
  end

  def order_canceled?(status)
    if ['canceled', 'returned', 'waiting_refunded', 'refunded'].include?(status) 
      true
    else
      false
    end
  end
end