public with sharing class QuickDataUtility {
    
    /* Description: this lets an admin-type quickly update children with their parents where doing so via 
     * ExternalId upsert would be impossible (e.g., for polymorphic fields), and where doing an advanced 
     * data load would be annoying!
     * To consume this method pass in the following parameters:
     * 
     * sObjectSource = the source object you want to populate parent records
     * sObjectTarget = the target object from which you want to find parent records
     * sourceLookupId = the lookup() id from the child that you want to populate
     * sObjectSourceStamp = the name of the ExternalId on the child object (it should match the ExternalId on the parent object)
     * sObjectTargetStamp = the name of the ExternalId on the parent object (it should match the ExternalId on the child object)
     * onlyUpdateOrphans = Set this to TRUE if you only want to update orphans, otherwise set to FALSE to update every child!
     * 
     * Example:
	 * String result= DataLoadHandler.addParentIds('Task','User','OwnerId','UserStamp__c','UserStamp__c',FALSE);
	 * System.debug('>>' + result);
	
     */
    public static String addParentIds(String sObjectSource, String sObjectTarget,
                                      String sourceLookupId,
                                      String sObjectSourceStamp, String sObjectTargetStamp,
                                      Boolean onlyUpdateOrphans) 
    {
        String resultStr = 'INITVALUE: Something bad has happened if you find this. Troubleshoot and review the debug logs!';
     
        List<sObject> sobjListToUpdate = new List<SObject>();
        
        String defaultQuerySource;
        if(onlyUpdateOrphans) { 
        	defaultQuerySource = 'Select Id, ' + sourceLookupId + ',' + sObjectSourceStamp + ' from ' + sObjectSource + ' where ' + sourceLookupId + '= null and ' + sObjectSourceStamp + ' != null';
        } else {
            defaultQuerySource = 'Select Id, ' + sourceLookupId + ',' + sObjectSourceStamp + ' from ' + sObjectSource + ' where ' + sourceLookupId + '!= null and ' + sObjectSourceStamp + ' != null';
        }
        
        List<sObject> sobjListSource = Database.query(defaultQuerySource);
        Map<String,String> mapStampToIdSource = new Map<String,String>();
        for(sObject item : sobjListSource) {
            mapStampToIdSource.put( String.valueOf(item.get(sObjectSourceStamp)),item.Id);                        
        }
        
        String defaultQueryTarget = 'Select Id, ' +  sObjectTargetStamp + ' from ' + sObjectTarget + ' where ' + sObjectTargetStamp + ' != null' ;
        List<sObject> sobjListTarget = Database.query(defaultQueryTarget);
        Map<String,String> mapStampToIdTarget = new Map<String,String>();
        for(sObject item : sobjListTarget) {
            mapStampToIdTarget.put( String.valueOf(item.get(sObjectTargetStamp)),item.Id);
        }
        
        if(sobjListSource.size() > 0) {
            for(sObject item : sobjListSource) {
                String itemId = String.valueOf(item.Id);
                if(mapStampToIdTarget.get(String.valueOf(item.get(sObjectSourceStamp))) != null ) {
                    item.put(sourceLookupId, mapStampToIdTarget.get(String.valueOf(item.get(sObjectSourceStamp))) );                        
                    sobjListToUpdate.add(item);
                }
            }
        }
        if(sobjListToUpdate.size() > 0 ) {
            try {
			update sobjListToUpdate;
        	resultStr = 'The following records were updated in the running of this method : ' + sobjListToUpdate;         	                   
            } catch(DmlException e ) {
            	System.debug('DML ERROR! : ' + e);
            } 
        } else { 
        	resultStr = 'No records were harmed or updated in the running of this method';
        }        

        return resultStr;
    }
}