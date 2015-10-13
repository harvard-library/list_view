class DRSRelatedLink
  include ActiveModel::Model
  
  attr_accessor :type, :value, :label
  attr_writer :relatedurl
  
  def initialize(type, value = nil, label = nil, relatedurl = nil)
     @type = type
     @value = value
     @label = label
     @relatedurl = relatedurl
  end
  
  def related_url()
    if (@relatedurl.nil? && !@value.nil?)
      build_url()
    end
    
    @relatedurl
  end
  
  def build_url()
    if (type.casecmp("hollis") == 0 || type.casecmp("aleph") == 0)
      @relatedurl = "http://id.lib.harvard.edu/aleph/"+@value+"/catalog"
    end
    if (type.casecmp("oldhollis") == 0)
      @relatedurl = "http://hollisclassic.harvard.edu/F?func=find-c&amp;CCL_TERM=sys="+@value
    end
    if (type.casecmp("uri") == 0)
      @relatedurl = @value
    end
    if (type.casecmp("link") == 0)
      @relatedurl = @value
    end
    if (type.casecmp("related") == 0)
      @relatedurl = @value
    end
    if (type.casecmp("finding aid") == 0)
      if (@value.startsWith("http://") || value.startsWith("www.")) 
        @relatedurl = @value
      else
        @relatedurl = APP_CONFIG['OASIS_URL'] + "&uniqueid=" + @value
      end
    end
  end

end