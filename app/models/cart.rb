class Cart
  SessionKey_cart = :my_cart_sr0cywr
  SessionKey_order = :my_order_aTpk2wr

  #自動產生getter
  attr_reader :items

  # def items
  #   return @items
  # end

  # def items=(new_item)
  #   @items = new_item
  # end

  def initialize(items = [])
    @items = items
  end

  # 將商品加入cart
  def add_item(product_id, quantity, price, order_id)
    found_item = @items.find{ |item| item.product_id == product_id } 

    if found_item
      product_quantity = Product.find(found_item.product_id).quantity
      found_item.quantity + quantity > product_quantity ? found_item.change(product_quantity) : found_item.increment(quantity)
    else
      @items << CartItem.new(product_id, quantity, price, order_id)
    end
  end

  def change_quantity(product_id, quantity)
    found_item = @items.find{ |item| item.product_id == product_id }
    found_item.change(quantity)
  end

  # def total_price
  #   @items.reduce(0){ |sum, item| sum + item.unit_price }
  #   #[].reduce(initial){ |memo, obj| block }
  # end

  def to_hash
    # all_item = @items.map{ |item| {'product_id' => item.product_id, 'quantity' => item.quantity, 'price' => item.price } }
    all_item = @items.map{ |item| {'product_id' => item.product_id, 'quantity' => item.quantity, 'price' => item.price, 'offer_id' => item.offer_id } }

    { "items" => all_item }
  end

  # class method 類別方法
  def self.from_hash(hash)
    if hash.nil?
      new []   #new([]) => initialize([])
    else
      new hash['items'].map{ |item|
        CartItem.new(item['product_id'], item['quantity'], item['price'], item['offer_id'] ) 
      }
    end  
  end

  def self.new_order_hash(hash)
    new []
    @items = hash
    @items.items.map{|item|
      item.offer_id = Product.find(item.product_id).offer_id
      item.price = calc_order_price(item.product_id, item.quantity, item.offer_id)
    }
    @items
  end

  def self.calc_order_price(product_id, quantity, offer_id)
    product = Product.find(product_id)
    if !offer_id.nil?
      offer = Offer.find(offer_id)

      if offer.offer == 'discount'
        value = quantity / offer.range_quantity
        remainder = quantity % offer.range_quantity
        
        price = ((product.price * offer.range_quantity * (offer.offer_discount / 100.0)) * value).ceil
        price += (product.price * remainder)

      elsif offer.offer == 'price'
        value = quantity / offer.range_quantity
        price = product.price * quantity - offer.offer_price * value
      end
    else
      price = product.price * quantity
    end
    price
  end

  def session_to_order_items(order)
    @items.each_with_index do |item,index|
      order.order_items[index].product_id = item.product_id
      order.order_items[index].quantity = item.quantity
      order.order_items[index].price = item.price
      
      product = Product.find(item.product_id)
      product.quantity -= item.quantity
      product.sold += item.quantity
      product.save
    end
  end

  


  # def empty?
  #   @items.empty?
  # end

  


end
