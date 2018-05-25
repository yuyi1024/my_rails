class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.integer :user_id
      t.text :question
      t.text :answer
      t.string :reply_method
      t.string :email
      t.integer :qanda

      t.timestamps
    end
  end
end
