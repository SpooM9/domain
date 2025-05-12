/**
 * @description       : Controller class for the contactCounter LWC Component - handles the upsertion of Contact Type Count Records.
 * @author            : spoorthi.marakkini
 * @group             : 
 * @last modified on  : 05-11-2025
 * @last modified by  : spoorthi.marakkini@aasw.asn.au
**/
public with sharing class ContactCounterController {
    
    /*
    * @purpose: Gets related unqiue contacts based on the type and state.
    * @parameters: String accountId
    * @return Type: List<AggregateResult>
    */
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getContactList(String accountId) {
        return [SELECT AccountId, Type__c, MailingState, Count(Id) conCount
                FROM Contact 
                WHERE AccountId =: accountId AND Type__c != null AND MailingState != null 
                GROUP BY AccountId, Type__c, MailingState];
    }


    /*
    * @purpose: Upserts contactTypeCount records based on the selected rows of objectinfo passed from the datatable
    * @parameters: String accountId, String contactInfo
    * @return Type: String
    */
    @AuraEnabled
    public static String createContactCountRecords(String accountId, String contactInfo){

        try{
            List<ContactTypeWrapper> conWrapList = (List<ContactTypeWrapper>) JSON.deserialize(contactInfo.replaceAll('__c',''), List<ContactTypeWrapper>.class);
            Map<String, ContactType_Count__c> existingConTypeMap = new Map<String, ContactType_Count__c>();
            List<ContactType_Count__c> contactTypeList = new List<ContactType_Count__c>();
            List<ContactType_Count__c> existingConTypeList = [SELECT Id, Account__c, Type__c, State__c, Contact_Count__c FROM ContactType_Count__c WHERE Account__c =:accountId];
            
            if(!existingConTypeList.isEmpty()){
                for(ContactType_Count__c conTypeRec: existingConTypeList){
                    String conKey = conTypeRec.Account__c+':'+conTypeRec.Type__c+':'+conTypeRec.State__c;
                    existingConTypeMap.put(conKey, conTypeRec);
                }
            }
            
            if(!conWrapList.isEmpty()){
                for(ContactTypeWrapper conRec: conWrapList){
                    String objKey = conRec.AccountId+':'+conRec.Type+':'+conRec.MailingState;
                    if(existingConTypeMap.containsKey(objKey)){
                        ContactType_Count__c existingConTypeRec = existingConTypeMap.get(objKey);
                        existingConTypeRec.Contact_Count__c = conRec.conCount;
                        contactTypeList.add(existingConTypeRec);
                    }else{
                        ContactType_Count__c conTypeCountRec = new ContactType_Count__c();
                        conTypeCountRec.Account__c = conRec.AccountId;
                        conTypeCountRec.Type__c = conRec.Type;
                        conTypeCountRec.State__c = conRec.MailingState;
                        conTypeCountRec.Contact_Count__c = conRec.conCount;
                        contactTypeList.add(conTypeCountRec);
                    }
                }
            }

            if(!contactTypeList.isEmpty()){
                upsert contactTypeList;
            }
            return 'Success';
        }catch(Exception ex){
            if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'))
                return 'Contact Count cannot be greater than 5';
            else
                return ex.getMessage();
        }
    }

    //ContactTypeWrapper wrapper class that holds object information that is passed from the js file.
    public class ContactTypeWrapper {

        @AuraEnabled
        public String AccountId {get;set;}
        @AuraEnabled
        public String Type {get;set;}
        @AuraEnabled
        public String MailingState {get; set;}
        @AuraEnabled
        public Decimal conCount {get; set;}
    }
}