class Ledger < ActiveRecord::Base
  serialize :serialized_linklist, JSON
end
