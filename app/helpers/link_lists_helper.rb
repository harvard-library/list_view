module LinkListsHelper
  def split_qualified_id(q_id)
    HashWithIndifferentAccess.new([:ext_id_type, :ext_id].zip(q_id.split('-')).to_h)
  end
end
