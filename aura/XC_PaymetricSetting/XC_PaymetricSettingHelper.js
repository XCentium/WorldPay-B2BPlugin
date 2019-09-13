({
	initController : function(component, event, helper) {
		var action = component.get("c.initClass");       
        var self = this;
        action.setCallback(this, function(response) {
            component.set("v.psController", response.getReturnValue());
            var psController = response.getReturnValue();
            var updateButton = component.find("updateId");
            updateButton.set("v.disabled",true);
            self.initView(component, psController.currentPSList[0].DeveloperName);
        });
        $A.enqueueAction(action);
	},
    initView: function(component, devName){ 
        var updateButton = component.find("updateId");
        var createButton = component.find("createId");
        component.find("tabId").set("v.selectedTabId", "tabGeneral");
        
        var action = component.get("c.paymetricSettingChange");
        action.setParams({
            envType: devName
        });
        action.setCallback(this, function(response){    
        		component.set("v.paySettingObject", response.getReturnValue()); 
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
                component.set("v.envSelectedValue", psController.DeveloperName);
                component.set("v.isActive", psController.WPB2B__XC_Active__c);
                component.set("v.allowUsertoSaveValue", psController.WPB2B__XC_Save_Card__c);
        });
        $A.enqueueAction(action);
        
    }
})