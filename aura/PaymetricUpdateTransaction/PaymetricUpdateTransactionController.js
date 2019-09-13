({
	reverseAuth: function (component, event, helper) {
        var recId = component.get("v.recordId");
        console.log(recId);
        var action = component.get("c.reverseTrans");
		action.setParams({ txId : recId });
		action.setCallback(this, function(response) {
            var resp = response.getReturnValue();
            if(resp.StatusCode > 0){
        		helper.callToast(resp.respMsg, 'success', 'Transaction Processed');
            }else{
                helper.callToast(resp.respMsg, 'error', 'Error Processing Transaction'); 
            }
        });
        $A.enqueueAction(action);
    },
    chargeTrans: function (component, event, helper) { 
        var recId = component.get("v.recordId");
        console.log(recId);
        var action = component.get("c.chargeTranx");
		action.setParams({ txId : recId });
		action.setCallback(this, function(response) {
            var resp = response.getReturnValue();
            if(resp.StatusCode > 0){
        		helper.callToast(resp.respMsg, 'success', 'Transaction Processed');
            }else{
                helper.callToast(resp.respMsg, 'error', 'Error Processing Transaction'); 
            }
        });
        $A.enqueueAction(action);
    }
})