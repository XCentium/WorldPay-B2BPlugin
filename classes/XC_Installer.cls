global class XC_Installer implements InstallHandler {
  global void onInstall(InstallContext context) {
    if(context.previousVersion() == null) {
        //Required Page LAbels
        try{
      List<ccrz__E_PageLabel__c> lbls = new List<ccrz__E_PageLabel__c>();
        
      ccrz__E_PageLabel__c MyWallet_AcctType_pp = new ccrz__E_PageLabel__c();
      MyWallet_AcctType_pp.Name = 'PaymentProcessorTab_wp';
      MyWallet_AcctType_pp.ccrz__Value__c = 'Credit Card';
      MyWallet_AcctType_pp.ccrz__ValueRT__c = 'Credit Card';
      MyWallet_AcctType_pp.ccrz__Storefront__c = 'Global';
      MyWallet_AcctType_pp.ccrz__PageName__c = 'All';
      
      ccrz__E_PageLabel__c MyWallet_AcctNum_pp = new ccrz__E_PageLabel__c();
      MyWallet_AcctNum_pp.Name = 'PaymentDisplay_wp';
      MyWallet_AcctNum_pp.ccrz__Value__c = 'Credit Card: {1}';
      MyWallet_AcctNum_pp.ccrz__ValueRT__c = 'Credit Card: {1}';
      MyWallet_AcctNum_pp.ccrz__Storefront__c = 'Global';
      MyWallet_AcctNum_pp.ccrz__PageName__c = 'All';
        
      lbls.add(MyWallet_AcctType_pp);
      lbls.add(MyWallet_AcctNum_pp);
        
        if(Schema.sObjectType.ccrz__E_PageLabel__c.fields.Name.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_PageLabel__c.fields.ccrz__Value__c.isCreateable()  &&                                                      
           Schema.sObjectType.ccrz__E_PageLabel__c.fields.ccrz__ValueRT__c.isCreateable()  &&                                                      
           Schema.sObjectType.ccrz__E_PageLabel__c.fields.ccrz__Storefront__c.isCreateable()  &&                                                      
           Schema.sObjectType.ccrz__E_PageLabel__c.fields.ccrz__PageName__c.isCreateable() )
   		{
        	insert lbls;
        }
        }catch(Exception e){
            
        }
        
        try{       
       // Add “pp” on Checkout and My Wallet
       ccrz__E_Configuration__c coConfig = [Select ccrz__ConfigurationId__c, ccrz__ConfigurationMeta__c, ccrz__PageName__c, ccrz__SequencePriority__c, ccrz__Storefront__c, ccrz__TextValue__c, Name  from ccrz__E_Configuration__c where Name = 'Global.all.co.pmts'];
       ccrz__E_Configuration__c myWallConfig = [Select ccrz__ConfigurationId__c, ccrz__ConfigurationMeta__c, ccrz__PageName__c, ccrz__SequencePriority__c, ccrz__Storefront__c, ccrz__TextValue__c, Name  from ccrz__E_Configuration__c where Name = 'Global.all.wlt.pmts'];

       coConfig.ccrz__TextValue__c = coConfig.ccrz__TextValue__c + ',wp';
       myWallConfig.ccrz__TextValue__c = myWallConfig.ccrz__TextValue__c + ',wp';
        
        if(Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__TextValue__c.isUpdateable())
   		{
            update coConfig;
            update myWallConfig;
        }
        
    	//Create new Configuration Module for Payment WP
    	ccrz__E_ConfigurationModule__c payPP = new ccrz__E_ConfigurationModule__c();
        payPP.ccrz__APIName__c = 'pmt_wp';
        payPP.Name = 'Payment WorldPay';
        if(Schema.sObjectType.ccrz__E_ConfigurationModule__c.fields.Name.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_ConfigurationModule__c.fields.ccrz__APIName__c.isCreateable() )
   		{
        insert payPP;
        }
        
        List<ccrz__E_ConfigurationMeta__c> configMetas = new List<ccrz__E_ConfigurationMeta__c>();
        ccrz__E_ConfigurationMeta__c newPP = new ccrz__E_ConfigurationMeta__c();
        newPP.ccrz__APIName__c = 'new';
        newPP.ccrz__ConfigurationModule__c = payPP.Id;
        newPP.ccrz__Description__c = 'New Payment Page for WorldPay Payments';
        configMetas.add(newPP);
        
        ccrz__E_ConfigurationMeta__c editPP = new ccrz__E_ConfigurationMeta__c();
        editPP.ccrz__APIName__c = 'edit';
        editPP.ccrz__ConfigurationModule__c = payPP.Id;
        editPP.ccrz__Description__c = 'Edit Payment Page for PayWorldPaypal Payments';
        configMetas.add(editPP);
        
        ccrz__E_ConfigurationMeta__c payPPage = new ccrz__E_ConfigurationMeta__c();
        payPPage.ccrz__APIName__c = 'pay';
        payPPage.ccrz__ConfigurationModule__c = payPP.Id;
        payPPage.ccrz__Description__c = 'Pay Payment Page for WorldPay Payments';
        configMetas.add(payPPage);
        
        if(Schema.sObjectType.ccrz__E_ConfigurationMeta__c.fields.ccrz__APIName__c.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_ConfigurationMeta__c.fields.ccrz__ConfigurationModule__c.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_ConfigurationMeta__c.fields.ccrz__Description__c.isCreateable()  )
   		{
            insert configMetas;
        }
        
        List<ccrz__E_Configuration__c> configs = new List<ccrz__E_Configuration__c>();
		//On storefront Configuration Setting – setup new and pay page values on Payment WP        
        ccrz__E_Configuration__c payPage = new ccrz__E_Configuration__c();
        payPage.ccrz__ConfigurationMeta__c = payPPage.Id;
        payPage.ccrz__PageName__c = 'all';
        payPage.ccrz__SequencePriority__c = 2.0;
        payPage.ccrz__Storefront__c = 'Global';
        payPage.ccrz__TextValue__c = 'WPB2B__XC_Paymetric_Pay';
        payPage.Name  = 'Global.all.pmt_wp.pay';   
        configs.add(payPage);
        
        if(Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__ConfigurationMeta__c.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__PageName__c.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__SequencePriority__c.isCreateable() &&                                                      
           Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__Storefront__c.isCreateable()  &&                                                      
           Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__TextValue__c.isCreateable()  &&                                                      
           Schema.sObjectType.ccrz__E_Configuration__c.fields.Name.isCreateable()  )
   		{
        insert configs;
        }
        
        //Add the new and pay pages on the Payment -> Whitelist list
        
    	ccrz__E_Configuration__c whiteList = [Select ccrz__ConfigurationId__c, ccrz__ConfigurationMeta__c, ccrz__PageName__c, ccrz__SequencePriority__c, ccrz__Storefront__c, ccrz__TextValue__c, Name  from ccrz__E_Configuration__c where Name = 'Global.all.pmt.whitelst'];
    	whiteList.ccrz__TextValue__c = whiteList.ccrz__TextValue__c + ',WPB2B__XC_Paymetric_Pay';
        
        if(Schema.sObjectType.ccrz__E_Configuration__c.fields.ccrz__TextValue__c.isUpdateable())
   		{
        	update WhiteList; 
        }
            
        }catch(Exception e){
            
        }
    }
  }
}