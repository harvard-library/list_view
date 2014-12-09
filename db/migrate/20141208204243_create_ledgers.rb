class CreateLedgers < ActiveRecord::Migration
  def change
    create_table :ledgers do |t|
      t.string :user_email, :null => false, :default => '<Admin Console>'
      t.string :ext_id, :null => false
      t.string :ext_id_type, :null => false
      t.datetime :time
      t.string :event_type
      t.json :serialized_linklist
      t.timestamps
    end
    add_index :ledgers, [:ext_id_type, :ext_id]
  end
end
