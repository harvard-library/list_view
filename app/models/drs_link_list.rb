require 'java'
Dir[File.expand_path("../../lib/java/*.jar", File.dirname(__FILE__))].each { |jar| require jar }

class DRSLinkList
  include ActiveModel::Model
  
  java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.Mods"
  java_import "edu.harvard.hul.ois.ots.schemas.XmlContent.GenericElement"
  #java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.ModsStringElement"
  #java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.Name"
  java_import "javax.xml.stream.XMLInputFactory"
  java_import "javax.xml.stream.XMLOutputFactory"
  java_import "javax.xml.stream.XMLStreamWriter"
  java_import "java.io.ByteArrayInputStream"
  java_import "java.io.ByteArrayOutputStream"
    
  #todo - this should eventually just return one DRSListObject
  def self.all
    drsObjectViewDTO_v2 = DRSServices.drs_object("400086909")
    
    #This is where the DRSListObject will be created
    pdslinks = []
    pdsobjects = drsObjectViewDTO_v2.getDocumentListMapping()
    pdsobjects.each{ 
      |pdsobject| 
      if pdsobject.getDocumentObject().getUrns().size() > 0
        deliveryURN = APP_CONFIG['NRS_RESOLVER_URL'] + "/" + pdsobject.getDocumentObject().getUrns().iterator().next().getUrn()
      else 
        deliveryURN = ""
      end
      pdslinks.push PDSLink.new(pdsobject.getDocumentObject().getOwnerSuppliedName(), deliveryURN) }
    #the PDSLinks are formed from the  (drsObjectViewDTO_v2.getDocumentListMapping())
      # which returns a list of ListDocumentMapDTO objects
      #the parse_title will be the same as the parse_title method below
 
      #ultimately, this will be the call 
      title = drsObjectViewDTO_v2.getOwnerSuppliedName()

    #set up the Mods object for use in extracting title, author, etc.
    mods = get_mods(drsObjectViewDTO_v2.getMods())
      
    @list_object = DRSListObject.new(title, display_name(mods), drsObjectViewDTO_v2.getId(),  pdslinks)
    if drsObjectViewDTO_v2.getUrns().size() > 0
      @list_object.url = APP_CONFIG['NRS_RESOLVER_URL'] + "/" + drsObjectViewDTO_v2.getUrns().iterator().next().getUrn()
    end
    @list_object
  end
  
  def self.parse_title(content_object)
    #do this in a method called parse_title
    #titles = mods.getTitleInfos()
    #loop through the titles and get the status
    #if status.index > 0  title = info.getTitle
    @title = "Title"
  end
  
  def self.parse_url(content_object)
    @url = "http://www.google.com"
  end
  
  def self.get_mods(string_mods)
    #Java code to get the mods from the returned doc
    #begin
      mods = Mods.new()
                    
      if !string_mods.nil?
        # parse the mods chunk
        xmlif = XMLInputFactory.newInstance()
        xmlReader = xmlif.createXMLStreamReader(ByteArrayInputStream.new(string_mods.to_java_bytes))
        mods.parse(xmlReader)
        #mods.java_send(:parse, [javax.xml.stream.XMLStreamReader], xmlif.createXMLStreamReader(ByteArrayInputStream.new(string_mods.to_java_bytes)))     
        
        #convert mods chunk to something usable by JSTree for display in user interface
        xmlf = XMLOutputFactory.newInstance()
        outputStream = ByteArrayOutputStream.new()
        xmlw = xmlf.createXMLStreamWriter(outputStream)
        mods.setRoot(true)
        mods.output(xmlw)
      end
    #rescue 
              #String errMsg = "error parsing mods: " + e.getMessage();
              #LOG.error(errMsg);
              #addActionError(errMsg); 
    #end
  end
  
  #Java methods for creating the display name
  def self.display_name(mods) 
    if mods.nil?
      return "nil"
    end
    mods.getNames().each{ 
          |n| 
          if "personal" == n.getAttribute("type")
              return "personal"#display_personal_name(n)
          else 
              return "org"#display_organization_name(n)
          end 
    }
        
    return ""
  end

#  def self.display_organization_name(n) 
#    forms = n.getDisplayForms()
#    if forms != null && !forms.isEmpty()
#      return forms.get(0).toString()
#    end
#    
#    # Get name parts in sequence
#    name = StringBuilder.new()
#    n.getNameParts().each{ 
#          |part| 
#      name.append(part.toString()) 
#      if Character.isLetterOrDigit(name.charAt(name.length() - 1))
#        name.append(". ") # Append period if name part doesn't already end with punctuation
#      else
#        name.append(" ")
#      end
#    }
#
#    return name.toString().trim()
#  end
#
#  def self.display_personal_name(n)
#    forms = n.getDisplayForms()
#    if forms != null && !forms.isEmpty()
#      return forms.get(0).toString()
#    end
#        
#    # Get name parts in sequence
#    name = StringBuilder.new()
#    n.getNameParts().each{ 
#          |part| 
#      type = part.getAttribute("type")
#      name.append(part.toString()) 
#      if type == null || ""  == type.trim()
#        name.append(part.toString() + " ")
#      end
#    }
#    
#    if name.length() > 1
#      name.deleteCharAt(name.length() - 1) # remove trailing space
#    end
#
#    # Look for typeOfAddress
#    n.getNameParts().each{ 
#        |part|
#      type = part.getAttribute("type")
#      if "typeOfAddress" == type
#        name.append(", " + part.toString())
#        break
#      end
#    }
#    
#    # Look for date    
#    n.getNameParts().each{ 
#        |part|
#      type = part.getAttribute("type")
#      if "date" == type
#        name.append(", " + part.toString())
#        break
#      end
#    }  
#    
#    return name.toString()
#  end

end
