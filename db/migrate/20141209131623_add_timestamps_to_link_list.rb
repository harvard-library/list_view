class AddTimestampsToLinkList < ActiveRecord::Migration
  def change
    add_column :link_lists, :created_at, :datetime
    add_column :link_lists, :updated_at, :datetime
  end
end
