class CreateLink < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.integer :position, :null => false
      t.references :link_list, :null => false
      t.string :name, :null => false
      t.string :url, :null => false
    end
  end
end
