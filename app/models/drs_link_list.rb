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
    drsObjectListViewDTO = DRSServices.drs_object(object_id)
    
    pdslinks = []
    pdsobjects = drsObjectListViewDTO.getActiveDocumentListMapping()
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
      pdslinktitle = pdsobject.getAlternateLabel()
      if pdslinktitle.nil? || pdslinktitle.empty? 
        pdslinktitle = pdsobject.getDocumentObject().getLabel()
      end
      if pdslinktitle.nil? || pdslinktitle.empty? 
        pdslinktitle = pdsobject.getDocumentObject().getOwnerSuppliedName()
      end
      pdslinks.push PDSLink.new(pdslinktitle, deliveryURN)
    }
    
    #set up the Mods object for use in extracting title, author, etc.
    mymods = create_mods_from_string(drsObjectListViewDTO.getMods())

    
    title = get_mods_title(mymods)

    names = get_display_names(mymods)
    
    @list_object = DRSListObject.new(title, names, drsObjectListViewDTO.getId(),  pdslinks)
    @list_object.mets_title = drsObjectListViewDTO.label
    if drsObjectListViewDTO.label.nil? || drsObjectListViewDTO.label.empty?
      @list_object.mets_title = drsObjectListViewDTO.getOwnerSuppliedName()
    end
           
    @list_object.osn_id = drsObjectListViewDTO.getOwnerSuppliedName()
        
    if drsObjectListViewDTO.getUrns().size() > 0
      @list_object.url = APP_CONFIG['NRS_RESOLVER_URL'] + "/" + drsObjectListViewDTO.getUrns().iterator().next().getUrn()
    end
    @list_object.fts_search_url=APP_CONFIG['FTS_SEARCH_URL'] + drsObjectListViewDTO.getId().to_s
    
    publication = get_publication(mymods)
    if !publication.empty?
      @list_object.publication = publication
    end
    
    if (!drsObjectListViewDTO.getOwner().nil?)
      @list_object.repository = drsObjectListViewDTO.getOwner().getCode()
    end
    
    @list_object.related_links = get_related_links(drsObjectListViewDTO)
    @list_object
  end

  
  def self.create_mods_from_string(string_mods)
     mmods = Mods.new()      
      if !string_mods.nil?
        
        # parse the mods chunk
        xmlif = XMLInputFactory.newInstance()
        xmlReader = xmlif.createXMLStreamReader(ByteArrayInputStream.new(string_mods.to_java(java.lang.String).getBytes('UTF-8')))
        mmods.setRoot(true)
        mmods.parse(xmlReader)
      end
      return mmods

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
  
  def self.get_mods_title(mods)
      if mods.nil?
        return ""
      end
      
      titles = []
      mods.getTitleInfos().each{ 
          |info|
          info.getTitles().each {
          |t|
            titles.push t.toString()
          }
      }
      if titles.empty?
        return ""
      end
      return titles
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
  
  def self.get_related_links(drsObjectListViewDTO)
    
    relatedlinks = []
      
    harvardmetadatalinks = drsObjectListViewDTO.getHarvardMetadata()
    #Add the md links
    harvardmetadatalinks.each{ 
          |harvardmd| 
      relatedlinks.push DRSRelatedLink.new(harvardmd.getMetadataType(), harvardmd.getMetadataIdentifier(), harvardmd.getDisplayLabel())
    }
    
    otherrelatedlinks = drsObjectListViewDTO.getRelatedLinks()
    #Add otherrelatedlinks md links
    otherrelatedlinks.each{ 
          |otherrl| 
      relatedlinks.push DRSRelatedLink.new('Link', nil, otherrl.getRelationship(), otherrl.getRelatedUri())
    }
    
    return relatedlinks
  end
end
