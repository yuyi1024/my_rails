class CartItem

  attr_accessor :product_id, :quantity, :price, :offer_id

  def initialize(product_id, quantity = 1, price = nil, offer_id = nil)
    @product_id = product_id
    @quantity = quantity
    @price = price
    @offer_id = offer_id
  end

  def increment(quantity = 1)
    @quantity += quantity
  end

  def change(quantity)
    @quantity = quantity
  end

  # def product
  #   Product.find(@product_id)
  # end

  def unit_price
    @price * @quantity
  end

end