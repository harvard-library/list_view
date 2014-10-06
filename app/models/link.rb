class Link < ActiveRecord::Base
  belongs_to :link_list
  acts_as_list :scope => :link_list
end
