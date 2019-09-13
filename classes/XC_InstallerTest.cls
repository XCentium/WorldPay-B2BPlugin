@isTest
public class XC_InstallerTest {    
    @isTest
	static void testInstallScript() {
        ccrz__E_Configuration__c coConfig = new ccrz__E_Configuration__c(
        	Name = 'Global.all.co.pmts',
            ccrz__TextValue__c = 'test'
        );
        insert coConfig;
        ccrz__E_Configuration__c myWallConfig = new ccrz__E_Configuration__c(
        	Name = 'Global.all.wlt.pmts',
            ccrz__TextValue__c = 'test'
        );
        insert myWallConfig;
        ccrz__E_Configuration__c whiteList = new ccrz__E_Configuration__c(
        	Name = 'Global.all.pmt.whitelst',
            ccrz__TextValue__c = 'test'
        );
        insert whiteList;

      	XC_Installer postinstall = new XC_Installer();
        System.Test.testInstall(postinstall, null);

        ccrz__E_Configuration__c postcoConfig = [Select Id, ccrz__TextValue__c from ccrz__E_Configuration__c where Name = 'Global.all.co.pmts' Limit 1];
        ccrz__E_Configuration__c postmyWallConfig = [Select Id, ccrz__TextValue__c from ccrz__E_Configuration__c where Name = 'Global.all.co.pmts' Limit 1];

        System.assertEquals(postcoConfig.ccrz__TextValue__c, 'test,wp');
        System.assertEquals(postmyWallConfig.ccrz__TextValue__c, 'test,wp');
      }
}