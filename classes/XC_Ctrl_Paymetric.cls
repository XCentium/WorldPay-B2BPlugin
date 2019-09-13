global with sharing class XC_Ctrl_Paymetric {
    global Decimal totalAmount{get; set;}
    global Decimal cartSubtotal {get; set;}
    global Decimal taxAmount {get; set;}
    global String iframesrc{get;set;}
    global String accessToken{get;set;}
    global String baseURL{get;set;}
    global String signature{get;set;}
    global String errorMessage{get;set;}
    global String errorStyle{get;set;}
    global String merchatGUID{get; set;}
    global Boolean allowCC{get; set;}
    global Boolean allowPO{get; set;}
    global Boolean allowSaveCard{get; set;}
    global Boolean error{get; set;}
    global static final Map<String,String> responseErrorMap = new Map<String,String> {
            '-100' => 'an unexpected error occurred processing the server request',
            '-101' => 'the web request could not be created',
            '-102' => 'the attempt to retrieve the response failed',
            '-103' => 'no response packet was returned from the server',
            '-104' => 'the response packet was invalid and could not be deserialized',
            '100' => 'Internal DI eComm Error',
            '101' => 'Merchant GUID is Invalid',
            '102' => 'Signature Validation Failed',
            '103' => 'Request Packet is Invalid',
            '104' => 'DI eComm Session has Expired',
            '105' => 'DI eComm Session Error',
            '106' => 'Error Decrypting Data',
            '107' => 'Get Access Token Error',
            '108' => 'Requested type has not been purchased',
            '120' => 'XiSecure Error',
            '121' => 'XiSecure No Token',
            '122' => 'XiSecure Certificate Expired UID: {0}, Expiration Date {1}',
            '140' => 'Error Accessing Database',
            '200' => 'No MasterPass Configuration',
            '201' => 'Invalid MasterPass Credentials',
            '202' => 'Error Communicating with MasterPass',
            '203' => 'No Error, Customer Canceled MasterPass',
            '300' => 'Cardinal Commerce Response: {message provided by Cardinal}',
            '301' => 'No Cardinal Commerce Configuration',
            '302' => 'The Cardinal Commerce configuration is missing information',
            '401' => 'An attempt was made to load the payment page in an Iframe'
    };

    global static final Map<String,String> xiPayErrorMap = new Map<String,String> {
            '-1' => 'There was a general error with processing the request. Please try again later.',
            '-100' => 'There was a problem reaching the payment servers. Please try again later.',
            '-101' => 'Your credit card was declined. Please try with a different payment method or try again later.',
            '-200' => 'There was a problem with the catridge data. Please contact your payment processor for more details.',
            '-201' => 'There was a problem with the catridge data. Please contact your payment processor for more details.'
    };

    global static final XC_Paymetric_Setting__mdt settings = getPaymetricSettings();

    global XC_Ctrl_Paymetric() {
        error = false;
        allowPO = false;
        allowCC = true;
        allowSaveCard = false;
        merchatGUID = '';

        baseURL = system.URL.getCurrentRequestUrl().toExternalForm();

        if(settings != null){
            allowSaveCard = settings.XC_Save_Card__c;
            merchatGUID = settings.XI_Intercept_MerchantGUID__c;
            
            Map<String, String> paymetricValues = getAccessToken(settings.XI_Intercept_Domain__c, settings.XI_Intercept_MerchantGUID__c, settings.XI_Intercept_SharedKey__c);
            if(paymetricValues.get('Error') == null){
                ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'Got Success: getAccessToken' + paymetricValues.get('accessToken'));
                iframesrc = 'https://' +settings.XI_Intercept_Domain__c + '/DIEComm/view/iframe/' + settings.XI_Intercept_MerchantGUID__c + '/' + paymetricValues.get('accessToken') + '/true';
                accessToken = paymetricValues.get('accessToken');
                signature = paymetricValues.get('signature');
                allowCC = true;
                error = false;
            }
            else{
                ccrz.ccLog.log(System.LoggingLevel.DEBUG, 'Got Failure: getAccessToken - ' + paymetricValues.get('Error'));
                error = true;
                allowCC = false;
                errorMessage = paymetricValues.get('Error');
            }
        }
    }
    
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getTokenResults(final ccrz.cc_RemoteActionContext ctx, String signature, String accessToken, String storeCurrency, Boolean saveCard,
                                                                Map<String, Object> billingAddr, Map<String, Object> shippingAddr){
        ccrz.cc_CallContext.initRemoteContext(ctx);

        signature = EncodingUtil.urlEncode(generateHmacSHA256Signature(settings.XI_Intercept_SharedKey__c, accessToken), 'UTF-8');
        Map<String, Object> dataMap = new Map<String, Object>();
        Map<String,String> queryParams = ctx.queryParams;

        String cartGUID = queryParams.get('cartID');
        ccrz.cc_RemoteActionResult res = new ccrz.cc_RemoteActionResult();
        res.success = false;

        try{
            ccrz__E_Cart__c cart = [Select c.ccrz__TotalSurcharge__c,c.ccrz__ShipAmount__c, c.ccrz__Storefront__c, c.ccrz__User__c, c.ccrz__Contact__c, c.ccrz__Account__c, c.OwnerId, c.Name, c.Id, c.ccrz__TotalQuantity__c, c.ccrz__TotalDiscount__c, c.ccrz__TotalAmount__c, c.ccrz__TaxAmount__c, c.ccrz__SubtotalAmount__c, (Select Id,ccrz__AbsoluteDiscount__c, ccrz__PercentDiscount__c, ccrz__ItemTotal__c, ccrz__Price__c, ccrz__Product__r.ccrz__ShortDesc__c, ccrz__Product__r.ccrz__SKU__c, ccrz__Product__r.ccrz__Quantityperunit__c, ccrz__Product__r.ccrz__ProductType__c, ccrz__Product__r.ccrz__ProductId__c, ccrz__Product__r.ccrz__LongDesc__c, ccrz__Product__r.Name, ccrz__Quantity__c, ccrz__SubAmount__c From ccrz__E_CartItems__r)
            From ccrz__E_Cart__c c
            Where c.ccrz__EncryptedId__c =: cartGUID][0];

            Boolean isCSR = (!UserInfo.getUserId().startsWith(cart.ccrz__User__c));
            String cardDataSource = isCSR ? 'M' : 'E';
            Decimal cartSubtotal = (Decimal)cart.ccrz__SubtotalAmount__c;
            Decimal shippingUpcharge = cart.ccrz__TotalSurcharge__c != null ? cart.ccrz__TotalSurcharge__c.setScale(2) : 0;
            cartSubtotal += shippingUpcharge;

            Boolean showMinUpcharge = cartSubtotal < 50;
            Decimal upchargeAmount = 50 - cartSubtotal;
            Decimal totalAmount = (Decimal)cart.ccrz__TotalAmount__c;

            dataMap.put('subtotal', cartSubtotal); 
            dataMap.put('upcharge', '0.00');
            dataMap.put('totalAmount', totalAmount);

            //first need to get the tokenized credit card data
            res.success = false;
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Content-Length', '0');
            req.setMethod('GET'); 
            req.setTimeout(120000);

            req.setEndpoint('https://' + settings.XI_Intercept_Domain__c + '/DIEComm/ResponsePacket?MerchantGUID=' + settings.XI_Intercept_MerchantGUID__c + '&Signature=' + signature + '&AccessToken=' + accessToken);
            dataMap.put('PACKETREQ', req.getEndpoint());
            httpResponse response = null;
            Http http = new Http();
            String timeStamp = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX');
            response = http.send(req);
            dataMap.put('TIMESTAMP', timeStamp);
            dataMap.put('PACKETRESPONSE', response.getBody());

            String resXML = response.getBody();
            Dom.Document resDoc = new Dom.Document();
            resDoc.load(resXML);
            PaymentResponse pr = new PaymentResponse();
            Dom.XMLNode envelope = resDoc.getRootElement();

            // check for error
            if (envelope != null) {
                if(envelope.getName() == 'PaymetricResponse'){
                    Dom.XMLNode fields = envelope.getChildElement('Fields', null);
                    List<FormField> prFields = new List<FormField>();
                    for (Dom.XMLNode ff : fields.getChildElements()){
                        FormField f = parseFormField(ff);
                        prFields.add(f);
                    }
                    pr.status = 'success';
                    pr.formFields = prFields;
                }
                else if(envelope.getName() == 'RequestError'){
                    String statuscode = envelope.getChildElement('statuscode', null).getText();
                    pr.status = statuscode + ' - ';
                    if (responseErrorMap.containsKey(statuscode)){
                        pr.status += responseErrorMap.get(statuscode);
                    }
                    else {
                        pr.status += 'an unknown processor error has occurred';
                    }
                }
                else {
                    pr.status = 'an unknown page controller error has occurred';
                }
                dataMap.put('TokenizeERROR', pr.status);
            }
            dataMap.put('PaymentResponse', pr);

            ccrz.cc_hk_Payment.TransactionPaymentParams transact = new ccrz.cc_hk_Payment.TransactionPaymentParams();
            transact.accountType = 'wp';
            transact.subAccountNumber = 'worldpay';
            transact.transactionCode = cart.Id;
            transact.amount = (Decimal)cart.ccrz__TotalAmount__c; //Decimal.valueOf(amount);
            transact.requestAmount = transact.amount;            
            String storefront = system.URL.getCurrentRequestUrl().toExternalForm().split('/')[3];
            transact.storefront = storefront;
            if(saveCard){
				transact.saveAsStoredPayment = TRUE;                
            }else{
				transact.saveAsStoredPayment = FALSE;                      
            }
            String CardSecurityCode = '';

            if(pr.status == 'success') {
                for(FormField ff: pr.formFields){
                    if(ff.Name == 'Card Holder Name'){
                        transact.displayName = ff.Value;
                    }
                    if(ff.Name == 'Card Type'){
                        transact.paymentType = ff.Value;
                    }
                    if(ff.Name == 'Expiration Month'){
                        transact.expirationMonth = Decimal.valueOf(ff.Value);
                    }
                    if(ff.Name == 'Expiration Year'){
                        transact.expirationYear = Decimal.valueOf(ff.Value);
                    }
                    if(ff.Name == 'Card Number'){
                        System.debug('Card Number: ');
                        System.debug(ff.Value);
                        transact.token = ff.Value;
                        transact.accountNumber = '**********' + ff.Value.split('-')[2];
                    }
                    if(ff.Name == 'Card Security Code'){
                        CardSecurityCode = ff.Value;
                    }
                }


            }

            String cardExpirationDate = transact.expirationMonth + '/' + transact.expirationYear;

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
            XiPayXML += '<Amount>' + transact.amount + '</Amount>';
            XiPayXML += '<CardCVV2>' + CardSecurityCode + '</CardCVV2>';
            XiPayXML += '<CardExpirationDate>' + cardExpirationDate + '</CardExpirationDate>';
            XiPayXML += '<CardHolderName>' + transact.displayName + '</CardHolderName>';
            XiPayXML += '<CardHolderAddress1>' + (String)billingAddr.get('address1')  + '</CardHolderAddress1>';
            XiPayXML += '<CardHolderCity>' + (String)billingAddr.get('city')  + '</CardHolderCity>';
            XiPayXML += '<CardHolderCountry>' + (String)billingAddr.get('countryCode')  + '</CardHolderCountry>';
            XiPayXML += '<CardHolderState>' + (String)billingAddr.get('stateCode')  + '</CardHolderState>';
            XiPayXML += '<CardHolderZip>' + (String)billingAddr.get('postalCode')  + '</CardHolderZip>';
            XiPayXML += '<CardNumber>' + transact.token + '</CardNumber>';
            XiPayXML += '<CardType>' + transact.paymentType.toUpperCase() + '</CardType>';
            XiPayXML += '<CurrencyKey>' + 'USD' + '</CurrencyKey>';
            XiPayXML += '<MerchantID>US21_USD_VANTIV</MerchantID>';
            XiPayXML += '<CardDataSource>E</CardDataSource>';
            XiPayXML += '<PacketOperation>1</PacketOperation>';
            XiPayXML += '<CurrencyKey /><Preauthorized />';
            XiPayXML += '<InfoItems>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_ADDR1</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('address1')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_CITY</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('city')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_NAME1</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('firstName') + ' ' + (String)billingAddr.get('lastName') + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_STATE</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('stateCode')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_ZIP</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('postalCode')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '</InfoItems>';
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
            dataMap.put('XiPayXML', XiPayXML);
            Xireq.setMethod('POST');
            Xireq.setEndpoint(xiPayEndpoint);


            Map<String,String> headerMap = new Map<String,String>();
            headerMap.put('Content-Type','text/xml; charset=utf-8');
            headerMap.put('Content-Length', String.valueOf(XiPayXML.length()));

            HttpResponse xiResponse = httpObj.send(Xireq, headerMap);

            Dom.Document xiResponseXML = new Dom.Document();
            xiResponseXML.load(xiResponse.getBody());

            List<Dom.XmlNode> xiResponseNodes = xiResponseXML.getRootElement().getChildElements()[0].getChildren()[0].getChildren()[0].getChildren()[2].getChildren()[0].getChildren();
            String XiResponseReply = '';
            for(Dom.XmlNode node: xiResponseNodes){
                String nodeName = node.getName();
                String nodeText = node.getText();

                if(nodeName == 'AuthorizationCode' && nodeText != null){
                    transact.transactionSubcode = nodeText;
                    dataMap.put('Authorization Code', nodeText);
                }

                if(nodeName == 'StatusCode' && nodeText != null){
                    if(xiPayErrorMap.containsKey(nodeText)){
                        dataMap.put('ERROR', xiPayErrorMap.get(nodeText));
                    }
                }

                if(nodeName == 'TransactionID'){
                    if(nodeText != null){
                        transact.transactionCode = nodeText;
                        dataMap.put('Authorization Ref Code', nodeText);
                    }else{
                        transact.transactionSubcode = '123';
                        dataMap.put('Authorization Ref Code', 'No Ref Provided');
                    }
                }

                XiResponseReply += nodeName + ' : ' + nodeText + ' ';

            }

            ccrz.ccLog.log(xiResponse.getBody());
            dataMap.put('AUTH RESPONSE', xiResponse.getBody());
            dataMap.put('Num of Nodes', XiResponseReply);
            dataMap.put('txObject', transact);

        }
        catch(Exception e){
            ccrz.ccLog.log(System.LoggingLevel.DEBUG,'EXCEPTION',e);
            System.debug('\n\n ------------ InException Block: ---------------------: ' + e.getMessage());
            dataMap.put('ERROR', e.getCause() + '-----' + e.getMessage() + '----' + String.valueOf(e.getLineNumber()));
        }
        finally{
            ccrz.ccLog.log(res);
            res.data = dataMap;
        }
        return res;
    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult chargeStoredPayment(final ccrz.cc_RemoteActionContext ctx, String signature, String accessToken, String storeCurrency, Boolean saveCard,
                                                                Map<String, Object> billingAddr, Map<String, Object> shippingAddr, String storedPayId){
        
            ccrz.cc_RemoteActionResult res = new ccrz.cc_RemoteActionResult();
            res.success = false;
            Map<String, Object> dataMap = new Map<String, Object>();

            try{
            ccrz.cc_CallContext.initRemoteContext(ctx);
            Map<String,String> queryParams = ctx.queryParams;
            String cartGUID = queryParams.get('cartID');
            ccrz__E_Cart__c cart = [Select c.ccrz__TotalSurcharge__c,c.ccrz__ShipAmount__c, c.ccrz__Storefront__c, c.ccrz__User__c, c.ccrz__Contact__c, c.ccrz__Account__c, c.OwnerId, c.Name, c.Id, c.ccrz__TotalQuantity__c, c.ccrz__TotalDiscount__c, c.ccrz__TotalAmount__c, c.ccrz__TaxAmount__c, c.ccrz__SubtotalAmount__c, (Select Id,ccrz__AbsoluteDiscount__c, ccrz__PercentDiscount__c, ccrz__ItemTotal__c, ccrz__Price__c, ccrz__Product__r.ccrz__ShortDesc__c, ccrz__Product__r.ccrz__SKU__c, ccrz__Product__r.ccrz__Quantityperunit__c, ccrz__Product__r.ccrz__ProductType__c, ccrz__Product__r.ccrz__ProductId__c, ccrz__Product__r.ccrz__LongDesc__c, ccrz__Product__r.Name, ccrz__Quantity__c, ccrz__SubAmount__c From ccrz__E_CartItems__r)
                                            From ccrz__E_Cart__c c
                                            Where c.ccrz__EncryptedId__c =: cartGUID][0];

            Boolean isCSR = (!UserInfo.getUserId().startsWith(cart.ccrz__User__c));
            String cardDataSource = isCSR ? 'M' : 'E';
            Decimal cartSubtotal = (Decimal)cart.ccrz__SubtotalAmount__c;
            Decimal shippingUpcharge = cart.ccrz__TotalSurcharge__c != null ? cart.ccrz__TotalSurcharge__c.setScale(2) : 0;
            cartSubtotal += shippingUpcharge;

            Boolean showMinUpcharge = cartSubtotal < 50;
            Decimal upchargeAmount = 50 - cartSubtotal;
            Decimal totalAmount = (Decimal)cart.ccrz__TotalAmount__c;

            ccrz__E_StoredPayment__c stdPay = [Select Id, ccrz__Token__c, ccrz__DisplayName__c, ccrz__PaymentType__c, ccrz__ExpMonth__c, ccrz__ExpYear__c, ccrz__AccountNumber__c from ccrz__E_StoredPayment__c
                                                                        where Id =: storedPayId];

            ccrz.cc_hk_Payment.TransactionPaymentParams transact = new ccrz.cc_hk_Payment.TransactionPaymentParams();
            transact.accountType = 'wp';
            transact.subAccountNumber = 'worldpay';
            transact.transactionCode = cart.Id;
            transact.amount = (Decimal)cart.ccrz__TotalAmount__c; //Decimal.valueOf(amount);
            transact.requestAmount = transact.amount;            
            String storefront = system.URL.getCurrentRequestUrl().toExternalForm().split('/')[3];
            transact.storefront = storefront;
			transact.saveAsStoredPayment = FALSE;  

            transact.storedPaymentId = stdPay.Id;
            transact.displayName = stdPay.ccrz__DisplayName__c;
            transact.paymentType = stdPay.ccrz__PaymentType__c;
            transact.expirationMonth = stdPay.ccrz__ExpMonth__c;
            transact.expirationYear = stdPay.ccrz__ExpYear__c;
            transact.token = stdPay.ccrz__Token__c;
            transact.accountNumber = stdPay.ccrz__AccountNumber__c;

            String cardExpirationDate = transact.expirationMonth + '/' + transact.expirationYear;

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
            XiPayXML += '<Amount>' + transact.amount + '</Amount>';
            XiPayXML += '<CardExpirationDate>' + cardExpirationDate + '</CardExpirationDate>';
            XiPayXML += '<CardHolderName>' + transact.displayName + '</CardHolderName>';
            XiPayXML += '<CardHolderAddress1>' + (String)billingAddr.get('address1')  + '</CardHolderAddress1>';
            XiPayXML += '<CardHolderCity>' + (String)billingAddr.get('city')  + '</CardHolderCity>';
            XiPayXML += '<CardHolderCountry>' + (String)billingAddr.get('countryCode')  + '</CardHolderCountry>';
            XiPayXML += '<CardHolderState>' + (String)billingAddr.get('stateCode')  + '</CardHolderState>';
            XiPayXML += '<CardHolderZip>' + (String)billingAddr.get('postalCode')  + '</CardHolderZip>';
            XiPayXML += '<CardNumber>' + transact.token + '</CardNumber>';
            XiPayXML += '<CardType>' + transact.paymentType.toUpperCase() + '</CardType>';
            XiPayXML += '<CurrencyKey>' + 'USD' + '</CurrencyKey>';
            XiPayXML += '<MerchantID>US21_USD_VANTIV</MerchantID>';
            XiPayXML += '<CardDataSource>E</CardDataSource>';
            XiPayXML += '<PacketOperation>1</PacketOperation>';
            XiPayXML += '<CurrencyKey /><Preauthorized />';
            XiPayXML += '<InfoItems>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_ADDR1</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('address1')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_CITY</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('city')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_NAME1</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('firstName') + ' ' + (String)billingAddr.get('lastName') + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_STATE</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('stateCode')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '<InfoItem>';
            XiPayXML += '<Key>3_SHIP_TO_ZIP</Key>';
            XiPayXML += '<Value>' + (String)billingAddr.get('postalCode')  + '</Value>';
            XiPayXML += '</InfoItem>';
            XiPayXML += '</InfoItems>';
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
            dataMap.put('XiPayXML', XiPayXML);
            Xireq.setMethod('POST');
            Xireq.setEndpoint(xiPayEndpoint);


            Map<String,String> headerMap = new Map<String,String>();
            headerMap.put('Content-Type','text/xml; charset=utf-8');
            headerMap.put('Content-Length', String.valueOf(XiPayXML.length()));

            HttpResponse xiResponse = httpObj.send(Xireq, headerMap);

            Dom.Document xiResponseXML = new Dom.Document();
            xiResponseXML.load(xiResponse.getBody());

            List<Dom.XmlNode> xiResponseNodes = xiResponseXML.getRootElement().getChildElements()[0].getChildren()[0].getChildren()[0].getChildren()[2].getChildren()[0].getChildren();
            String XiResponseReply = '';
            for(Dom.XmlNode node: xiResponseNodes){
                String nodeName = node.getName();
                String nodeText = node.getText();

                if(nodeName == 'AuthorizationCode' && nodeText != null){
                    transact.transactionSubcode = nodeText;
                    dataMap.put('Authorization Code', nodeText);
                }

                if(nodeName == 'StatusCode' && nodeText != null){
                    if(xiPayErrorMap.containsKey(nodeText)){
                        dataMap.put('ERROR', xiPayErrorMap.get(nodeText));
                    }
                }

                if(nodeName == 'TransactionID'){
                    if(nodeText != null){
                        transact.transactionCode = nodeText;
                        dataMap.put('Authorization Ref Code', nodeText);
                    }else{
                        transact.transactionSubcode = '123';
                        dataMap.put('Authorization Ref Code', 'No Ref Provided');
                    }
                }

                XiResponseReply += nodeName + ' : ' + nodeText + ' ';

            }

            ccrz.ccLog.log(xiResponse.getBody());
            dataMap.put('AUTH RESPONSE', xiResponse.getBody());
            dataMap.put('Num of Nodes', XiResponseReply);
            dataMap.put('txObject', transact);
            res.success = true;

        }
        catch(Exception e){
            ccrz.ccLog.log(System.LoggingLevel.DEBUG,'EXCEPTION',e);
            System.debug('\n\n ------------ InException Block: ---------------------: ' + e.getMessage());
            dataMap.put('ERROR', e.getCause() + '-----' + e.getMessage() + '----' + String.valueOf(e.getLineNumber()));
        }
        finally{
            ccrz.ccLog.log(res);
            res.data = dataMap;
        }
        return res;
    }

    private static String generateHmacSHA256Signature(String saltValue, String packetXML) {
        String algorithmName = 'hmacSHA256';
        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueOf(packetXML), Blob.valueOf(saltValue));
        System.debug('Signature: ' + EncodingUtil.base64Encode(hmacData));
        return EncodingUtil.base64Encode(hmacData);
    }

    public Map<String, String> getAccessToken(String hostname, String MerchantID, String secretKey){

        Map<String, String> returnMap = new Map<String, String>();

        try{
            String SessionReqType = '1';
            String MerchantDevelopmentEnv = 'Salesforce';

            PageReference file_ref = PageReference.forResource('PaymetricCSS');
            String paymetricCSSURL = URL.getSalesforceBaseUrl().toExternalForm() + file_ref.getUrl();

            String externalBaseURL = system.URL.getCurrentRequestUrl().toExternalForm().split('/')[2];

            //iFrame            
			String PacketXML = '<?xml version="1.0" encoding="utf-8"?>';
            PacketXML += '<merchantHtmlPacketModel xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="Paymetric:XiIntercept:MerchantHtmlPacketModel">';
            PacketXML += '<iFramePacket>';
            PacketXML += '<hostUri>https://' + externalBaseURL + '</hostUri>';
            PacketXML += '<cssUri>' + paymetricCSSURL.split('\\?')[0] + '</cssUri>';
            PacketXML += '</iFramePacket>';
            /*
            PacketXML += '<templateHtml name="CreditCard">';
            PacketXML += '<paymentTypes>';
            //PacketXML += '<paymentType type="american express"/>';
            PacketXML += '<paymentType type="mastercard"/>';
            PacketXML += '<paymentType type="visa"/>';
            PacketXML += '</paymentTypes>';
            PacketXML += '</templateHtml>';
			*/
            PacketXML += '<merchantHtml>';  
            PacketXML += '<htmlSection class="merchant_paycontent">';  
            PacketXML += '<xiProperties error-class="xiInputError">';  
            PacketXML += '<errorTooltip class="errorTooltip" show-effect="fadeIn" show-duration="5000" hide-effect="fadeOut" hide-duration="5000" />';  
            PacketXML += '</xiProperties>';  
            PacketXML += '<cardDropdownSection>';  
            PacketXML += '<tag name="div" class="modal">';  
            PacketXML += '<tag name="div" class="modal__container">';  
            PacketXML += '<tag name="div" class="modal__content">';  
            PacketXML += '<tag name="div" class="paymentInfoHeader">Enter your Credit Card details</tag>';  
            PacketXML += '<tag name="div" class="form-list">';  
            PacketXML += '<tag name="div" class="form-list__row">';  
            PacketXML += '<label for="cardType" />';  
            PacketXML += '<ddlCardType id="cd">';  
            PacketXML += '<items>';  
            PacketXML += '<item for="american express" />';  
            PacketXML += '<item for="mastercard" />';  
            PacketXML += '<item for="visa" />';  
            PacketXML += '</items>';  
            PacketXML += '</ddlCardType>';  
            PacketXML += '</tag>';  
            PacketXML += '<tag name="div" class="form-list__row">';  
            PacketXML += '<label for="cardholderName" />';  
            PacketXML += '<tboxCardHolderName />';  
            PacketXML += '<validationMsg for="cardholderName" class="valmsg" />';  
            PacketXML += '</tag>';  
            PacketXML += '<tag name="div" class="form-list__row">';  
            PacketXML += '<label for="cardNumber" />';  
            PacketXML += '<tag name="div" class="input--cc" >';  
            PacketXML += '<tboxCardNumber tokenize="true" />';  
            PacketXML += '<validationMsg for="cardNumber" class="valmsg" />';  
            PacketXML += '</tag>';  
            PacketXML += '</tag>';  
            PacketXML += '<tag name="div" class="form-list__row form-list__row--inline">';  
            PacketXML += '<tag name="div">';  
            PacketXML += '<label for="expMonth" />';  
            PacketXML += '<tag name="div" class="form-list__input-inline">';  
            PacketXML += '<ddlExpMonth default-text="Exp. Month" class="merchant_combos" required="false" />';  
            PacketXML += '<ddlExpYear default-text="Exp. Year" class="merchant_combos" years-to-display="10" required="false" exp-date="true" />';  
            PacketXML += '</tag>';  
            PacketXML += '<validationMsg for="expMonth" class="valmsg" />';  
            PacketXML += '<validationMsg for="expYear" class="valmsg" />';  
            PacketXML += '</tag>';  
            PacketXML += '<tag name="div">';  
            PacketXML += '<label for="cvv" />';  
            PacketXML += '<tboxCvv />';  
            PacketXML += '<validationMsg for="cvv" class="valmsg" />';  
            PacketXML += '</tag>';  
            PacketXML += '</tag>';  
            PacketXML += '</tag>';  
            PacketXML += '</tag>';  
            PacketXML += '</tag>';  
            PacketXML += '</tag>';  
            PacketXML += '</cardDropdownSection>';  
            PacketXML += '</htmlSection>';  
            PacketXML += '</merchantHtml>';  
            PacketXML += '</merchantHtmlPacketModel>';  
			
            String signature = generateHmacSHA256Signature(secretKey, PacketXML);

            String payLoad = 'MerchantGuid=' + MerchantID +
                    '&SessionRequestType=' + SessionReqType +
                    '&Packet=' + EncodingUtil.urlEncode(PacketXML, 'UTF-8') +
                    '&Signature=' + EncodingUtil.urlEncode(signature, 'UTF-8') +
                    '&MerchantDevelopmentEnvironment=' +  MerchantDevelopmentEnv ;

            System.debug('Access Token Payload: ');
            System.debug(payLoad);

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + hostname + '/DIeComm/accesstoken');
            req.setHeader('content-type', 'application/x-www-form-urlencoded');
            req.setHeader('content-language', 'en-US');
            req.setMethod('POST');
            req.setBody(payLoad); 
            HttpResponse res = h.send(req);

            System.debug(res);
            System.debug(res.getBody());

            Dom.Document resDoc = res.getBodyDocument();

            System.debug(resDoc);

            Dom.XmlNode acctokenresppacket = resDoc.getRootElement();
            Dom.XmlNode ResPacket = acctokenresppacket.getChildElement('ResponsePacket', null);

            String AccessToken = ResPacket.getChildElement('AccessToken', null).getText();

            returnMap.put('accessToken', AccessToken);
        }
        catch (Exception e){
            returnMap.put('Error', e.getLineNumber() + e.getMessage());
        }


        return returnMap;
    }

    private static FormField parseFormField (Dom.XMLNode fFields){
        FormField ff = new FormField();
        ff.Name = addFormFieldChild(fFields,'Name');
        ff.Value = addFormFieldChild(fFields,'Value');
        ff.IsToTokenize = addFormFieldChild(fFields,'IsToTokenize');
        return ff;
    }

    private static string addFormFieldChild(Dom.XMLNode el, string val){
        if (el.getChildElement(val,null) != null){
            return el.getChildElement(val, null).getText();
        }
        else {
            return '';
        }
    }

    public class FormField { 
        String Name;
        String Value;
        String IsToTokenize;
    }

    public class PaymentResponse {
        String status;
        List<FormField> formFields;
    }

	public static XC_Paymetric_Setting__mdt getPaymetricSettings(){
        if(!Test.isRunningTest()){
            try{
            String storefront = system.URL.getCurrentRequestUrl().toExternalForm().split('/')[3];
		    XC_Paymetric_Setting__mdt setting = [Select Id, XC_Storefront__c, XC_Manual_Charge__c, XC_Save_Card__c, Environment__c, Label, XI_Intercept_Domain__c, XI_Intercept_MerchantGUID__c, XI_Intercept_SharedKey__c, XI_Pay_SharedKey__c, XI_Pay_Username__c, XIPay_HostName__c from XC_Paymetric_Setting__mdt 
                                                        where XC_Storefront__c =: storefront and XC_Active__c = true Limit 1];
            
            return setting;
            }catch(Exception e){
                return null;
            }
        }else{
            XC_Paymetric_Setting__mdt testSetting = new XC_Paymetric_Setting__mdt();
            return testSetting;
        }
	} 
}