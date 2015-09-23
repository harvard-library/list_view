require 'java'
Dir[File.expand_path("../../lib/java/*.jar", File.dirname(__FILE__))].each { |jar| require jar }

class DRSLinkList
  include ActiveModel::Model
  
  java_import "javax.xml.stream.XMLInputFactory"
  java_import "javax.xml.stream.XMLStreamWriter"
  java_import "java.io.ByteArrayInputStream"
  java_import "java.lang.StringBuilder"
  java_import "java.lang.Character"
  java_import "edu.harvard.hul.ois.ots.schemas.ModsMD.Mods"
      
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
      #What should the title be if there is no alternate label?
      pdslinktitle = pdsobject.getDocumentObject().label
      if pdslinktitle.nil? || pdslinktitle.empty?
        pdslinktitle = pdsobject.getDocumentObject().getOwnerSuppliedName()
      end
      pdslinks.push PDSLink.new(pdslinktitle, deliveryURN) 
    }
    
    #set up the Mods object for use in extracting title, author, etc.
    mymods = create_mods_from_string(drsObjectViewDTO_v2.getMods())

    title = drsObjectViewDTO_v2.label
    if title.nil? || title.empty?
      title = drsObjectViewDTO_v2.getOwnerSuppliedName()
    end
    
    names = get_display_names(mymods)
    
    @list_object = DRSListObject.new(title, names, drsObjectViewDTO_v2.getId(),  pdslinks)
    if drsObjectViewDTO_v2.getUrns().size() > 0
      @list_object.url = APP_CONFIG['NRS_RESOLVER_URL'] + "/" + drsObjectViewDTO_v2.getUrns().iterator().next().getUrn()
    end
    
    publication = get_publication(mymods)
    if !publication.empty?
      @list_object.publication = publication
    end
    
    @list_object
  end

  
  def self.create_mods_from_string(string_mods)
    #Java code to get the mods from the returned doc
    #begin
      mmods = Mods.new()      
      if !string_mods.nil?
        
        # parse the mods chunk
        xmlif = XMLInputFactory.newInstance()
        xmlReader = xmlif.createXMLStreamReader(ByteArrayInputStream.new(string_mods.to_java(java.lang.String).getBytes('UTF-8')))
        mmods.setRoot(true)
        mmods.parse(xmlReader)
      end
      return mmods
    #rescue 
#              String errMsg = "error parsing mods: " + e.getMessage();
#              LOG.error(errMsg);
#              addActionError(errMsg); 
    #end
  end
  
  #Java methods for creating the display name
  def self.get_display_names(mods) 
    if mods.nil?
      return ""
    end
    retnames = []
    mods.getNames().each{ 
          |n| 
          if "personal" == n.getAttribute("type")
              return get_personal_name(n)
          else 
              return get_organization_name(n)
          end 
    }
        
    return ""
  end

  def self.get_organization_name(n) 
    forms = n.getDisplayForms()
    if !forms.nil? && !forms.empty?
      return forms.get(0).toString()
    end
    
    # Get name parts in sequence
    name = StringBuilder.new()
    n.getNameParts().each{ 
          |part| 
      name.append(part.toString()) 
      if Character.isLetterOrDigit(name.charAt(name.length() - 1))
        name.append(". ") # Append period if name part doesn't already end with punctuation
      else
        name.append(" ")
      end
    }

    return name.toString()
  end

  def self.get_personal_name(n)
    forms = n.getDisplayForms()
    if !forms.nil? && !forms.empty?
      return forms.get(0).toString()
    end
    
    # Get name parts in sequence
    name = StringBuilder.new()
    n.getNameParts().each{ 
          |part| 
      type = part.getAttribute("type")
      name.append(part.toString()) 
      if !type.nil? && !type.empty?
        name.append(" ")
      end
    }
    
    if name.length() > 1
      name.deleteCharAt(name.length() - 1) # remove trailing space
    end

    # Look for typeOfAddress
    n.getNameParts().each{ 
        |part|
      type = part.getAttribute("type")
      if "typeOfAddress" == type
        name.append(", " + part.toString())
        break
      end
    }
    
    # Look for date    
    n.getNameParts().each{ 
        |part|
      type = part.getAttribute("type")
      if "date" == type
        name.append(", " + part.toString())
        break
      end
    }  
    
    return name.toString()
  end
  
  def self.get_publication(mods)
    if mods.nil?
      return ""
    end
    
    publications = []
    mods.getOriginInfos().each{ 
      |oi|
      placestring = get_places(oi.getPlaces())
      namestring = get_publisher_names(oi.getPublishers())
      datestring = get_publisher_dates(oi.getDatesIssued())
        
      publicationstring = ""
      delimiter = ""
      if !placestring.empty?
        publicationstring = placestring
        delimiter = " : "
      end
      if !namestring.empty?
        publicationstring = publicationstring + delimiter + namestring
        delimiter = ", "
      end
      if !datestring.empty?
        publicationstring = publicationstring + delimiter + datestring
      end
      publications.push publicationstring
    }
    if publications.empty?
      return ""
    end
    return publications.join("\n")
      
#    <s:iterator var="oinfo" value="mods.getOriginInfos()">
#    39                      <s:iterator value="#oinfo.getPlaces()">
#    40                        <s:iterator var="places" value="#oinfo.getPlaces()">
#    41                          <s:iterator value="#places.getPlaceTerms()">
#    42                            <s:if test="#originStatus.index > 0">, </s:if>
#    43                            <s:property/>
#    44                          </s:iterator>
#    45                        </s:iterator>
#    46                      </s:iterator>
#    47                      <s:iterator value="#oinfo.getPublishers()">
#    48                        <s:if test="#originStatus.index > 0">, </s:if>
#    49                        <s:property/>
#    50                      </s:iterator>
#    51                      <s:iterator value="#oinfo.getDatesIssued()" status="originStatus">
#    52                        <s:if test="#originStatus.index > 0">, </s:if>
#    53                        <s:property/>
#    54                      </s:iterator>
  end

  def self.get_places(places)
    if places.nil?
      return ""
    end
    placestring = ""
    delimiter = ""
    places.each{ 
      |place|
      place.getPlaceTerms().each {
        |placeterm|
        placestring = placestring + delimiter + placeterm.toString()
        delimiter = ", "
      }
    }
    return placestring
  end
  
  def self.get_publisher_names(names)
    if names.nil?
      return ""
    end
    pubstring = ""
    delimiter = ""
    names.each{
      |pubname|
      pubstring = pubstring + delimiter + pubname.toString()
      delimiter = ", "
    }
    return pubstring
  end
  
  def self.get_publisher_dates(dates)
    if dates.nil?
      return ""
    end
    datestring = ""
    delimiter = ""
    dates.each{ 
      |pubdate|
      datestring = datestring + delimiter + pubdate.toString()
      delimiter = ", " 
    }
    return datestring
  end
end
