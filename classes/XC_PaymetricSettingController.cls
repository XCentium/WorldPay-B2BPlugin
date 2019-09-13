global class XC_PaymetricSettingController {
    @AuraEnabled public List<String> environmentTypeList {get;set;}
    @AuraEnabled public List<XC_Paymetric_Setting__mdt> currentPSList {get;set;}  
   
    @AuraEnabled
    global static XC_PaymetricSettingController initClass(){
        XC_PaymetricSettingController obj = new XC_PaymetricSettingController();       
        obj.environmentTypeList = new List<String>();
        obj.currentPSList = new List<XC_Paymetric_Setting__mdt>();
        integer count = 0;
        
        for(XC_Paymetric_Setting__mdt ps : [SELECT Id,DeveloperName, Environment__c, XC_Storefront__c, XI_Intercept_Domain__c, XI_Intercept_MerchantGUID__c, XI_Intercept_SharedKey__c, 
                                            XIPay_HostName__c, XC_Active__c, XI_Pay_SharedKey__c, XI_Pay_Username__c,MasterLabel,XC_Save_Card__c, Success_Message__c,Error_Message__c FROM XC_Paymetric_Setting__mdt Limit 100]){
                                                
                                                obj.currentPSList.add(ps);                                                                                   
        }
        
        Schema.DescribeFieldResult fieldResult = XC_Paymetric_Setting__mdt.Environment__c.getDescribe();
        List<Schema.PicklistEntry> ft = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry f : ft){
            obj.environmentTypeList.add(f.getValue());
        }
        
       return obj ;
   }  
    
    @AuraEnabled
    global static void insertUpdateSetting(Map<String, Object> valuesMap){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        Metadata.CustomMetadata paymetricSetting = new Metadata.CustomMetadata();
        paymetricSetting.fullName = 'WPB2B__XC_Paymetric_Setting__mdt' + '.' + (String)valuesMap.get('developername');
        paymetricSetting.label = (String)valuesMap.get('masterlabel');
        
        for(String s : valuesMap.keySet()){
            if(s != 'developername' && s != 'masterlabel'){
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                    customField.field = 'WPB2B__' + s;
                    if(s == 'XC_Save_Card__c' || s == 'XC_Active__c'){
                        System.debug(s);
                        customField.value = (Boolean)valuesMap.get(s);
                    }else{
                        System.debug(s);
                        customField.value = (String)valuesMap.get(s);
                    }
                    
                    paymetricSetting.values.add(customField);                 
                    mdContainer.addMetadata(paymetricSetting);     
            }
        }
        
        XC_CustomMetadataCallback callback = new XC_CustomMetadataCallback();
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);    
    }

    
    @AuraEnabled
    public static XC_Paymetric_Setting__mdt paymetricSettingChange(String envType){
        XC_Paymetric_Setting__mdt psObj  = new XC_Paymetric_Setting__mdt();
        psObj   = [SELECT Id,DeveloperName, Environment__c, XC_Storefront__c, XI_Intercept_Domain__c, XI_Intercept_MerchantGUID__c, XI_Intercept_SharedKey__c, 
                       XIPay_HostName__c, XC_Active__c, XI_Pay_SharedKey__c, XI_Pay_Username__c,MasterLabel, XC_Save_Card__c, Success_Message__c,Error_Message__c FROM XC_Paymetric_Setting__mdt WHERE DeveloperName =: envType LIMIT 1];
        return psObj ;
    }
    
}