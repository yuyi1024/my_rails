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
end
