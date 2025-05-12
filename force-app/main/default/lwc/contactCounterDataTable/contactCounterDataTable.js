/*********************************************************************************************************
  @description       : Holds the js/controller facing side of the contactCounterDataTable component
  @author            : spoorthi.marakkini
  @last modified on  : 05-12-2025
  @last modified by  : spoorthi.marakkini@aasw.asn.au
  @Modifications Log :
  @Version	Date Modified	ModifiedBy						Description
  @V.1		5/11/2025		spoorthi.marakkini	            Initial Version
***********************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import getContactList from '@salesforce/apex/ContactCounterController.getContactList';
import createContactCountRecords from '@salesforce/apex/ContactCounterController.createContactCountRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Type', fieldName: 'Type__c', type: 'text' },
    { label: 'State', fieldName: 'MailingState', type: 'text' },
    { label: 'Contact Count', fieldName: 'conCount', type: 'number' },
];

export default class ContactCounterDataTable extends LightningElement {

    @api recordId;
    @api excludeStates;
    @api showOnlyStates;
    @api excludeTypes;
    @api showOnlyTypes;
    @track error;
    @track selectedRows = [];
    @track selectedRowVals = [];
    @track contactList = [];
    @api contactTypeList = [];

    columns = columns;

    connectedCallback(){
        this.getContactTypeInfo();
    }

    //Calls the apex controller function to get exisiting contacts to the passed account Id
    getContactTypeInfo(){
        getContactList({accountId: this.recordId, excludeStates: this.excludeStates, showOnlyStates: this.showOnlyStates, excludeTypes: this.excludeTypes, showOnlyTypes: this.showOnlyTypes})
        .then(result => {
            if(result != undefined && result != null){
                this.contactList = result;
            }
        });
    }

    //handles the row selection click and adds values into selectedRows
    handleRowSelection(event){
        const selectedRows = event.detail.selectedRows;
        this.selectedRowVals = selectedRows;
    }

    //save function called on save button click
    handleSave(){
        if(this.selectedRowVals != undefined && this.selectedRowVals != null && this.selectedRowVals.length > 0){
            createContactCountRecords({accountId: this.recordId, contactInfo: JSON.stringify(this.selectedRowVals)})
            .then(result => {
                if(result == 'Success'){
                    this.showToast('Success!','Contact Type Count Records Upserted', 'success');
                }else{
                    this.error = result;
                    this.showToast('Error!','Oops! Looks like something went wrong - '+result, 'error');
                }
            });
        }else{
            this.showToast('Error!','No rows have been selected', 'error');
        }
    }

    //shows a alert popup for any error or success messages
    showToast(title, msg, type) {
        const event = new ShowToastEvent({
            title: title,
            variant: type, 
            message: msg,
        });
        this.dispatchEvent(event);
    }
}