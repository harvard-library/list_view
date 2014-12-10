class AddImageToLinkList < ActiveRecord::Migration
  def change
    add_column :link_lists, :image, :string
  end
end
