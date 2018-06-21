class CreateOffers < ActiveRecord::Migration[5.1]
  def change
    create_table :offers do |t|
      t.string :range
      t.integer :range_price
      t.integer :range_quantity
      t.string :offer
      t.string :offer_freight
      t.integer :offer_price
      t.integer :offer_discount
      t.string :message
      t.string :implement
      t.timestamps
    end
  end
end
