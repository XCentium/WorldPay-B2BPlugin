({
	doInit : function(component, event, helper) {
		helper.initController(component, event, helper);
    },

    insertUpdateClick:function(component, event, helper){    
        var action = component.get("c.insertUpdateSetting");
        var buttonId = event.getSource().getLocalId();
        var developerName = component.get("v.developerNameValue");
        var hasError = false;

        if(!component.find("storeFrontId").get("v.validity").valid){            
            component.find("storeFrontId").showHelpMessageIfInvalid();
            hasError = true;
        }
        
        if(component.get("v.masterLabelValue") == ""){           
            hasError = true;
        }
        
        if(component.get("v.interceptDomainValue") == ""){             
            hasError = true;
        }
        
        if(component.get("v.merchantGUIDValue") == ""){          
           hasError = true;
        }
        
        if(component.get("v.interceptSharedKeyValue") == ""){            
            hasError = true;
        }
        
        if(component.get("v.hostNameValue") == ""){             
            hasError = true;
        }
        
        if(component.get("v.payUserNameValue") == ""){             
            hasError = true;
        }
        
        if(component.get("v.paySharedValue") == ""){             
            hasError = true;
        }
       
        
        if(!hasError){
            
            if(buttonId == "createId"){
                var storefront = component.get("v.storeFrontValue");
                var environment = component.get("v.environmentValue");           
                developerName = storefront.replace(/\s/g, '') + "_" + environment.replace(/\s/g, '');
            }
            action.setParams(
              	{
                    "valuesMap": {                    
                        "XC_Storefront__c": component.get("v.storeFrontValue"),
                        "Environment__c": component.get("v.environmentValue"),
                        "masterlabel": component.get("v.masterLabelValue"),
                        "Success_Message__c": component.get("v.successMSGValue"),
                        "Error_Message__c": component.get("v.errorMSGValue"),
                        "XI_Intercept_Domain__c": component.get("v.interceptDomainValue"),
                        "XI_Intercept_MerchantGUID__c": component.get("v.merchantGUIDValue"),
                        "XI_Intercept_SharedKey__c": component.get("v.interceptSharedKeyValue"),
                        "XIPay_HostName__c": component.get("v.hostNameValue"),
                        "XI_Pay_Username__c": component.get("v.payUserNameValue"),
                        "XI_Pay_SharedKey__c": component.get("v.paySharedValue"),
                        "developername": developerName,
                        "XC_Active__c": component.get("v.isActive"),
                        "XC_Save_Card__c": component.get("v.allowUsertoSaveValue")                      
                    }
                }
            );
            action.setCallback(this, function(result) {
                var st3 = component.get("v.storeFrontValue");
                var currList = component.get("v.psController").currentPSList;
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Your updates are being saved, please refresh the page to see your updated changes.",
                    "type": 'success'
                });
                toastEvent.fire();
                var inactiveSettings = component.get("v.psController").currentPSList.filter(x => x.DeveloperName != developerName && x.WPB2B__XC_Storefront__c == st3);
                if(inactiveSettings.length > 0 && component.get("v.isActive")){
                    for(var x in inactiveSettings){
                        var newaction = component.get("c.insertUpdateSetting");
                        newaction.setParams(
                            {
                              "valuesMap": {       
                                  "developername": inactiveSettings[x].DeveloperName,
                                  "XC_Active__c": false,  
                                  "masterlabel": inactiveSettings[x].MasterLabel,               
                              }
                          }
                        );
                        $A.enqueueAction(newaction); 
                    }
                }
            } );
            $A.enqueueAction(action);  
        }else{
            
            //error message
        }
    },
    
    evnOnChange: function(component, event, helper){
        var selectedValue = event.getSource().get("v.value");  
        var updateButton = component.find("updateId");
        var createButton = component.find("createId");
        component.find("tabId").set("v.selectedTabId", "tabGeneral");
        
        var action = component.get("c.paymetricSettingChange");
        action.setParams({
            envType: event.getSource().get("v.value")
        });
        
        action.setCallback(this, function(response){            
        	component.set("v.paySettingObject", response.getReturnValue());
            
            if(selectedValue != 'new'){     
                createButton.set("v.disabled",true);
                updateButton.set("v.disabled",false);
                var psController = response.getReturnValue(); 
                component.set("v.storeFrontValue", psController.WPB2B__XC_Storefront__c);
                component.set("v.environmentValue", psController.WPB2B__Environment__c);
                component.set("v.masterLabelValue", psController.MasterLabel);
                component.set("v.successMSGValue", psController.WPB2B__Success_Message__c);
                component.set("v.errorMSGValue", psController.WPB2B__Error_Message__c);
                component.set("v.interceptDomainValue", psController.WPB2B__XI_Intercept_Domain__c);
                component.set("v.merchantGUIDValue", psController.WPB2B__XI_Intercept_MerchantGUID__c);
                component.set("v.interceptSharedKeyValue", psController.WPB2B__XI_Intercept_SharedKey__c);
                component.set("v.hostNameValue", psController.WPB2B__XIPay_HostName__c);
                component.set("v.payUserNameValue", psController.WPB2B__XI_Pay_Username__c);
                component.set("v.paySharedValue", psController.WPB2B__XI_Pay_SharedKey__c);
                component.set("v.developerNameValue", psController.DeveloperName);
                component.set("v.recordId", psController.Id);
                component.set("v.isActive", psController.WPB2B__XC_Active__c);
                component.set("v.allowUsertoSaveValue", psController.WPB2B__XC_Save_Card__c);
            }else{
                component.set("v.storeFrontValue", "");
                component.set("v.masterLabelValue", "");
                component.set("v.successMSGValue", "");
                component.set("v.errorMSGValue", "");
                component.set("v.interceptDomainValue", "");
                component.set("v.merchantGUIDValue", "");
                component.set("v.interceptSharedKeyValue", "");
                component.set("v.hostNameValue", "");
                component.set("v.payUserNameValue", "");
                component.set("v.paySharedValue", "");
                component.set("v.developerNameValue", "");
                component.set("v.isActive", false);
                component.set("v.allowUsertoSaveValue", false);
                createButton.set("v.disabled",false);
                updateButton.set("v.disabled",true);
            }
            
        });
        $A.enqueueAction(action);
        
    }
	
})