class MethodsController < ApplicationController
  def kkkeyword(k)
    keyword = k.split(' ')
    keyword = keyword.reduce(''){ |memo, obj| memo += "name LIKE '%"+ obj + "%' AND " }
    keyword = keyword.chomp(' AND ')
    keyword
    
  end
end