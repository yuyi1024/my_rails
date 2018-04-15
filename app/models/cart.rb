class Cart
  SessionKey = :my_cart666999

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

  def add_item(product_id, quantity)
    found_item = @items.find{ |item| item.product_id == product_id } 

    if found_item
      product_quantity = Product.find(found_item.product_id).quantity
      found_item.quantity + quantity > product_quantity ? found_item.change(product_quantity) : found_item.increment(quantity)
    else
      @items << CartItem.new(product_id, quantity)
    end
  end

  def change_quantity(product_id, quantity)
    found_item = @items.find{ |item| item.product_id == product_id }
    found_item.change(quantity)
  end

  def total_price
    @items.reduce(0){ |sum, item| sum + item.price }
    #[].reduce(initial){ |memo, obj| block }
  end

  def to_hash
    all_item = @items.map{ |item| {'product_id' => item.product_id, 'quantity' => item.quantity } }
    { "items" => all_item }
  end

  # class method 類別方法
  def self.from_hash(hash)
    if hash.nil?
      new []   #new([]) => initialize([])
    else
      new hash['items'].map{ |item|
        CartItem.new(item['product_id'], item['quantity']) 
      }
    end  
  end



  # def empty?
  #   @items.empty?
  # end

  


end
