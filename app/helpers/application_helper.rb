module ApplicationHelper

  def order_status_color(status)
    if status == 'waiting_shipment' || status == 'paid'
      status_color = 'status_red'
    elsif status == 'waiting_payment'
      status_color = 'status_blue'
    end
    status_color
  end

  def time_ago(created_at)
    t = Time.at(Time.now - created_at).utc
    if t.strftime("%H").to_i > 0
      t.strftime("%H小時前")
    else
      t.strftime("%M分鐘前")
    end
  end
end
