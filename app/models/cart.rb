class Cart < ApplicationRecord

  #自動產生getter
  attr_reader :items

  # def items
  #   return @items
  # end

  # def items=(new_item)
  #   @items = new_item
  # end

  def initialize(items = [])
    @items = item
  end

  def add_item(product_id, quantity)
    found_item = @items.find{ |item| item.product_id == product_id } 

    if found_item
      found_item.increment(quantity)
    else
      @items << CartItem.new(product_id, quantity)
    end
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
    # @items = Cart.new
    # if !hash.nil?
    #   hash['items'].each do |item|
    #     @items << CartItem.new( item['product_id'], item['quantity'] )
    #   end
    # end  

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
