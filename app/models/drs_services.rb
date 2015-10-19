
require 'java'

$CLASSPATH << "../../lib/java/log4j.properties"

Dir[File.expand_path("../../lib/java/*.jar", File.dirname(__FILE__))].each { |jar| require jar }
  
class DRSServices
  java_import 'edu.harvard.hul.ois.drs2.callservice.ServiceWrapper'
  java_import 'edu.harvard.hul.ois.drs2.services.dto.ext.DRSObjectListViewDTO'

    # This gets the DRSObjectViewDTO_v2 object from the drs2_services
    # using the proper keys
		def self.drs_object(object_id)
		  #Build the service wrapper with the keys
      svc = ServiceWrapper.new(APP_CONFIG['DRS2_SERVICE_BASE_URL'],
		                            APP_CONFIG['DRS2_SERVICE_APPKEY'],
		                             APP_CONFIG['DRS2_TIMEOUT'],
		                             APP_CONFIG['CLIENT_KEYSTORE_PATH'],
		                             APP_CONFIG['CLIENT_KEYSTORE_PASS'],
		                            APP_CONFIG['CLIENT_TRUSTSTORE_PATH'],
		                             APP_CONFIG['CLIENT_TRUSTSTORE_PASS'])
		  #Get the object from the service                             
		  content = svc.getDRSObjectByID(object_id, DRSObjectListViewDTO.java_class, true)
    end
	
end