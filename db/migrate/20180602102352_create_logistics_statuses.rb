class CreateLogisticsStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :logistics_statuses do |t|
      t.string :type
      t.string :subtype
      t.string :code
      t.string :message

      t.timestamps
    end
  end
end
