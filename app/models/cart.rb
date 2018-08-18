class Cart
  SessionKey_cart = :my_cart_sr0cywr
  SessionKey_order = :my_order_aTpk2wr

  #自動產生getter & setter
  attr_accessor  :items, :offer_id

  # def items
  #   return @items
  # end

  # def items=(new_item)
  #   @items = new_item
  # end

  def initialize(items = [], offer_id = nil)
    @items = items
    @offer_id = offer_id
    # <Cart:0x007f9aa15c82b0 @items=[#<CartItem:0x007f9aa15c82d8 @product_id="23", @quantity=1, @price=70, @offer_id=25>], @offer_id=nil>
  end

  # 將商品加入cart
  def add_item(product_id, quantity, price, offer_id)
    found_item = @items.find{ |item| item.product_id == product_id } 

    if found_item
      product_quantity = Product.find(found_item.product_id).quantity
      found_item.quantity + quantity > product_quantity ? found_item.change(product_quantity) : found_item.increment(quantity)
    else
      @items << CartItem.new(product_id, quantity, Product.find(product_id).price, offer_id)
    end
  end

  def change_quantity(product_id, quantity)
    found_item = @items.find{ |item| item.product_id == product_id }
    found_item.change(quantity)
  end

  # 計算 order session 中所有商品之總價(含商品優惠、不含全館優惠)
  def order_total_price
    @items.reduce(0){ |sum, item| sum + item.price }
    #[].reduce(initial){ |memo, obj| block }
  end

  def to_hash
    # all_item = @items.map{ |item| {'product_id' => item.product_id, 'quantity' => item.quantity, 'price' => item.price } }
    all_item = @items.map{ |item| {'product_id' => item.product_id, 'quantity' => item.quantity, 'price' => item.price, 'offer_id' => item.offer_id } }

    { "items" => all_item, 'offer_id' => @offer_id }
  end

  # class method 類別方法
  # 將session內容存於hash
  def self.from_hash(hash)
    if hash.nil?
      new []   #new([]) => initialize([])
    else
      Cart.new(hash['items'].map{ |item|
        CartItem.new(item['product_id'], item['quantity'], item['price'], item['offer_id'] ) 
      }, hash['offer_id'])
    end  
  end

  def self.new_order_hash(hash, offer_id)
    new []
    @items = hash
    @items.items.map{|item|
      item.offer_id = Product.find(item.product_id).offer_id
      item.price = calc_order_price(item.product_id, item.quantity, item.offer_id)
    }
    @items.offer_id = offer_id
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

      elsif offer.offer == 'freight'
        price = product.price * quantity
      end
    else
      price = product.price * quantity
    end
    price
  end

  # 將 order session 中的 items 存入 OrderItem，並對 product 的已賣/庫存數量作變動
  def session_to_order_items(order)
    @items.each_with_index do |item, index|
      order.order_items[index].product_id = item.product_id
      order.order_items[index].quantity = item.quantity
      order.order_items[index].price = item.price
      order.order_items[index].offer_id = item.offer_id
      
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
