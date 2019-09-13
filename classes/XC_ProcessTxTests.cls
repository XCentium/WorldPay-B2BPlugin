@isTest
public class XC_ProcessTxTests {
    @isTest
    static void testCharge(){
        List<String> txIds = new List<String>();
        ccrz__E_TransactionPayment__c tx1 = new ccrz__E_TransactionPayment__c();
        tx1.ccrz__Storefront__c = 'DefaultStore';
        insert tx1;
        txIds.add((String)tx1.Id);

        Test.setMock(HttpCalloutMock.class, new XC_HttpCallout());
        Test.startTest();
        XC_ProcessTransaction_Charge.chargeTranx(txIds);
        Test.stopTest();
    }

    @isTest
    static void testVoid(){
        List<String> txIds = new List<String>();
        ccrz__E_TransactionPayment__c tx1 = new ccrz__E_TransactionPayment__c();
        tx1.ccrz__Storefront__c = 'DefaultStore';
        insert tx1;
        txIds.add((String)tx1.Id);

        Test.setMock(HttpCalloutMock.class, new XC_HttpCallout());
        Test.startTest();
        XC_ProcessTransaction_Void.reverseTrans(txIds);
        Test.stopTest();
    }
}