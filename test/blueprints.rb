require 'machinist/active_record'

# Add your blueprints here.
#
# e.g.
#   Post.blueprint do
#     title { "Post #{sn}" }
#     body  { "Lorem ipsum..." }
#   end


Product.blueprint do
  name { Faker::Food.dish }
  price { Faker::Number.between(100, 1000) }
  category_id { 1 }
end
