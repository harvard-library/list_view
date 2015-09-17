
require 'java'

$CLASSPATH << "../../lib/java/log4j.properties"
#$CLASSPATH << "/Users/vac765/git/list_view/lib/java/log4j-1.2.11.jar"
#$CLASSPATH << "/Users/vac765/git/list_view/lib/java/drs2_services-util.jar"
#$CLASSPATH << "/Users/vac765/git/list_view/lib/java/drs2_services-dto.jar"

#require File.expand_path("../../lib/java/log4j-1.2.11.jar", File.dirname(__FILE__))
#require File.expand_path("../../lib/java/drs2_services-dto.jar", File.dirname(__FILE__))
#require File.expand_path("../../lib/java/drs2_services-util.jar", File.dirname(__FILE__))

Dir[File.expand_path("../../lib/java/*.jar", File.dirname(__FILE__))].each { |jar| require jar }
  
class DRSServices
  #java_import 'org.apache.log4j.Logger'
  java_import 'edu.harvard.hul.ois.drs2.callservice.ServiceWrapper'
  java_import 'edu.harvard.hul.ois.drs2.services.dto.ext.v2.DRSObjectViewDTO_v2'

#java code: private static ServiceWrapper svc = new ServiceWrapper (SERVICE_BASE_URL, DRS2_APPKEY, DRS2_TIMEOUT, 
			#Config.getInstance().CLIENT_KEYSTORE_PATH, Config.getInstance().CLIENT_KEYSTORE_PASS, 
			#Config.getInstance().CLIENT_TRUSTSTORE_PATH, Config.getInstance().CLIENT_TRUSTSTORE_PASS);

#java code for lv object by id
#content = svc.getDRSObjectByID(String.valueOf(objectId), DRSObjectViewDTO_v2.class, true);

		def self.drs_object(object_id)
      svc = ServiceWrapper.new(APP_CONFIG['DRS2_SERVICE_BASE_URL'],
		                            APP_CONFIG['DRS2_SERVICE_APPKEY'],
		                             APP_CONFIG['DRS2_TIMEOUT'],
		                             APP_CONFIG['CLIENT_KEYSTORE_PATH'],
		                             APP_CONFIG['CLIENT_KEYSTORE_PASS'],
		                             APP_CONFIG['CLIENT_TRUSTSTORE_PATH'],
		                             APP_CONFIG['CLIENT_TRUSTSTORE_PASS'])
		  conent = svc.getDRSObjectByID(object_id, DRSObjectViewDTO_v2.java_class, true)
      @list_objects = []
            @list_objects.push DRSListObject.new('Test 1', '1', ['abc', '123'])
            @list_objects.push DRSListObject.new('Test 2', '2', ['def', '456'])
            
		end
	
end