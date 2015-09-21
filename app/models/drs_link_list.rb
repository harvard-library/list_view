require 'java'
Dir[File.expand_path("../../lib/java/*.jar", File.dirname(__FILE__))].each { |jar| require jar }

class DRSLinkList
  include ActiveModel::Model
  
  java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.Mods"
  java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.ModsElement"
    java_import "edu.harvard.hul.ois.ots.schemas.XmlContent.GenericElement"
  #java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.ModsStringElement"
  #java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.Name"
  java_import "javax.xml.stream.XMLInputFactory"
  java_import "javax.xml.stream.XMLOutputFactory"
  java_import "javax.xml.stream.XMLStreamWriter"
  java_import "java.io.ByteArrayInputStream"
  java_import "java.io.ByteArrayOutputStream"
    
  #Returns a DRSListObject for the given object_id
  def self.display_object(object_id)
    #Retrieve it from the services
    drsObjectViewDTO_v2 = DRSServices.drs_object(object_id)
    
    pdslinks = []
    pdsobjects = drsObjectViewDTO_v2.getDocumentListMapping()
    #Add the pds links
    pdsobjects.each{ 
      |pdsobject| 
      if pdsobject.getDocumentObject().getUrns().size() > 0
        deliveryURN = APP_CONFIG['NRS_RESOLVER_URL'] + "/" + pdsobject.getDocumentObject().getUrns().iterator().next().getUrn()
      else 
        deliveryURN = ""
      end
      #Push onto the array
      pdslinks.push PDSLink.new(parse_title(pdsobject.getDocumentObject()), deliveryURN) 
    }
    
    #set up the Mods object for use in extracting title, author, etc.
    mymods = create_mods_from_string(drsObjectViewDTO_v2.getMods())
        
    #TODO Get the title from Mods
    title = parse_title(drsObjectViewDTO_v2)

    @list_object = DRSListObject.new(title, 'Temp Author', drsObjectViewDTO_v2.getId(),  pdslinks)
    if drsObjectViewDTO_v2.getUrns().size() > 0
      @list_object.url = APP_CONFIG['NRS_RESOLVER_URL'] + "/" + drsObjectViewDTO_v2.getUrns().iterator().next().getUrn()
    end
    @list_object
  end
  
  def self.parse_title(content_object)
    #Todo - get the title from the MODS once Mods parsing is working
    #titles = mods.getTitleInfos()
    #loop through the titles and get the status
    #if status.index > 0  title = info.getTitle
    @title = content_object.getOwnerSuppliedName()
  end

  
  def self.create_mods_from_string(string_mods)
    #Java code to get the mods from the returned doc
    #begin
                    
      if !string_mods.nil?
        
        # parse the mods chunk
        xmlif = XMLInputFactory.newInstance()
        xmlReader = xmlif.createXMLStreamReader(ByteArrayInputStream.new(string_mods.to_java_bytes))
        construct = Mods.java_class.constructor(javax.xml.stream.XMLStreamReader, Java::boolean)
        m = construct.new_instance(xmlReader, true)
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
    mods.java_object.getNames().each{ 
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
