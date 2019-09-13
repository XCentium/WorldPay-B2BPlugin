global class XC_ProcessTransaction_Charge {
    global XC_ProcessTransaction_Charge() {

    }
    
    @InvocableMethod
    public static List<txProcessResponse> chargeTranx(List<String> txIds) {
        List<txProcessResponse> results = new List<txProcessResponse>();
        for(String txId: txIds){
            ccrz__E_TransactionPayment__c txPay = [Select ccrz__Storefront__c, ccrz__TransactionSubcode__c, ccrz__TransactionCode__c from ccrz__E_TransactionPayment__c where Id =: txId];
            txProcessResponse result = new txProcessResponse();
            XC_Paymetric_Setting__mdt settings = getPaymetricSettings(txPay.ccrz__Storefront__c);

            //XiPay XML
            String XiPayXML = '<?xml version="1.0" encoding="utf-8"?>';
            XiPayXML += '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">';
            XiPayXML += '<soap12:Body>';
            XiPayXML += '<SoapOp xmlns="http://Paymetric/XiPaySoap30/message/">';
            XiPayXML += '<pPacketsIn>';
            XiPayXML += '<count>1</count>';
            XiPayXML += '<xipayvbresult>false</xipayvbresult>';
            XiPayXML += '<packets>';
            XiPayXML += '<ITransactionHeader>';
            XiPayXML += '<TransactionID>' + txPay.ccrz__TransactionCode__c + '</TransactionID>';
            XiPayXML += '<BatchID>' + String.valueOf(Datetime.now()) + '</BatchID>';
            XiPayXML += '<PacketOperation>17</PacketOperation>';
            XiPayXML += '</ITransactionHeader>';
            XiPayXML += '</packets>';
            XiPayXML += '</pPacketsIn>';
            XiPayXML += '</SoapOp>';
            XiPayXML += '</soap12:Body>';
            XiPayXML += '</soap12:Envelope>';

            String xiPayEndpoint = 'https://' + settings.XIPay_HostName__c ;

            HttpClient httpObj = new HttpClient(settings.XI_Pay_Username__c , settings.XI_Pay_SharedKey__c,True);
            HttpRequest Xireq = new HttpRequest();
            Xireq.setBody(XiPayXML);
            Xireq.setMethod('POST');
            Xireq.setEndpoint(xiPayEndpoint);

            Map<String,String> headerMap = new Map<String,String>();
            headerMap.put('Content-Type','text/xml; charset=utf-8');
            headerMap.put('Content-Length', String.valueOf(XiPayXML.length()));

            try{
            HttpResponse xiResponse = httpObj.send(Xireq, headerMap);

            Dom.Document xiResponseXML = new Dom.Document();
			String xiResponseStr = xiResponse.getBody();
            
            Integer statusCode = Integer.valueOf(xiResponseStr.substringBetween('StatusCode').remove('>').remove('</'));
            String respMsg = xiResponseStr.substringBetween('Message').remove('>').remove('</');
 
            result.StatusCode = statusCode;
            result.AUTHRESPONSE = xiResponseStr;
            result.respMsg = respMsg;
            if(statusCode < 0){
                result.status = false;            
            }else{
                txPay.ccrz__TransactionSubcode__c = 'X' + statusCode;
                result.status = true;            
            }

            if(Schema.sObjectType.ccrz__E_TransactionPayment__c.fields.ccrz__TransactionSubcode__c.isUpdateable())
            {
                update txPay;
            }
            }catch(Exception e){

            }

            results.add(result);
        }
        return results;
    }
    
	private static XC_Paymetric_Setting__mdt getPaymetricSettings(String storefront){
        if(!Test.isRunningTest()){
		    XC_Paymetric_Setting__mdt setting = [Select Id, XC_Storefront__c, XC_Manual_Charge__c, XC_Save_Card__c, Environment__c, Label, XI_Intercept_Domain__c, XI_Intercept_MerchantGUID__c, XI_Intercept_SharedKey__c, XI_Pay_SharedKey__c, XI_Pay_Username__c, XIPay_HostName__c from XC_Paymetric_Setting__mdt 
                                                        where XC_Storefront__c =: storefront and XC_Active__c = true Limit 1];
            
            return setting;
        }else{
            XC_Paymetric_Setting__mdt testSetting = new XC_Paymetric_Setting__mdt();
            return testSetting; 
        }
	}   

    public class txProcessResponse{
        @InvocableVariable  public Boolean status;
        
        @InvocableVariable  public Integer StatusCode;
        
        @InvocableVariable  public string AUTHRESPONSE;

        @InvocableVariable  public string respMsg;
    }
}