module ApplicationHelper

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
end
