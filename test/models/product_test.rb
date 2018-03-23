require './test/test_helper'

class ProductTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end



  test 'find products' do
  	
    c = [Product.make!, Product.make!, Product.make!]
    found = Product.all
    puts found.last.name
    assert_equal(3, found.count, ['good'])
  end
end
