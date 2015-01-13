class Link < ActiveRecord::Base
  belongs_to :link_list, :counter_cache => true
  acts_as_list :scope => :link_list
end
