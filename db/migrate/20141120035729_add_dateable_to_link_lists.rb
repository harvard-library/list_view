class AddDateableToLinkLists < ActiveRecord::Migration
  def change
    add_column :link_lists, :dateable, :boolean, :default => true
  end
end
