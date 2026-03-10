import { LightningElement, api, wire, track,  } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import updateStatusToOnTrack from '@salesforce/apex/CaseTimerController.updateStatusToOnTrack';
import updateStatusToWarning from '@salesforce/apex/CaseTimerController.updateStatusToWarning';
import updateStatusToBreached from '@salesforce/apex/CaseTimerController.updateStatusToBreached';
import getSettingsSLA from '@salesforce/apex/CaseTimerController.getSettingsSLA';

import SLA_ACTIVE_FIELD from '@salesforce/schema/Case.SLA_Active__c';
import SLA_STATUS_FIELD from '@salesforce/schema/Case.SLA_Status__c';
import SLA_START_FIELD from '@salesforce/schema/Case.SLA_Start__c';
import SLA_PAUSED_FIELD from '@salesforce/schema/Case.SLA_Paused__c';
import SLA_PAUSE_START_FIELD from '@salesforce/schema/Case.Pause_Start__c';
import SLA_TOTAL_PAUSED_MINUTES_FIELD from '@salesforce/schema/Case.SLA_Total_Paused_Minutes__c';

export default class CaseTimer extends LightningElement {
    @api recordId;
    @track isLoading = true;
    @track formattedTimeSLA;
    @track formattedDiffToBreachSLA;
    @track breachDT;

    caseData;
    settingsSLA;
    error;

    timer;

    // @wire method to get the Case, on whose Record Page we are on
    @wire(getRecord, { recordId: '$recordId', fields: [SLA_ACTIVE_FIELD, SLA_STATUS_FIELD, SLA_START_FIELD, SLA_PAUSED_FIELD, SLA_PAUSE_START_FIELD, SLA_TOTAL_PAUSED_MINUTES_FIELD] })
    wiredRecord({ data, error }) {
        if (data) {
            this.caseData = data;
            this.isLoading = false;
            this.error = undefined;
        } else if (error) {     
            this.error = error;
            this.isLoading = false;
            
            const errorEvent = new ShowToastEvent({
                title: 'Error Retrieving Case',          
                message: error.body.message, 
                variant: 'error',                 // String: success, error, warning, info            
            });

            this.dispatchEvent(errorEvent);
        }
    }

    @wire(getSettingsSLA, {recordName: 'Case_Timer_Thresholds_Min'})
    wiredSettings({data, error}){
        if (data){
            this.settingsSLA = data;
            // aici considera is Loading-ul ca ar cam trb sa astepte si dupa asta
            this.error = undefined;
        }
        else if (error){
            this.error = error;
            const errorEvent = new ShowToastEvent({
                title: 'Error Retrieving SLA Configs',          
                message: error.body.message, 
                variant: 'error',                 // String: success, error, warning, info            
            });
            this.dispatchEvent(errorEvent);
        }
    }

    // Framework Methods

    // this method is ran by the framework every second, and we get to decide if we need to turn the component on/off
    renderedCallback(){
        // if SLA has been activated, and Timer isn't on already -- turn on
        if (!this.timer && this.isSlaActive){
            this.timer = setInterval(() => {this.calculateTime()}, 1000);
        }

        // if Timer is activated, and SLA is deactivated -- turn off
        if (this.timer && !this.isSlaActive){
            // clear interval and then assign null, zombie var if not
            clearInterval(this.timer);
            this.timer = null;
        }

        // call the APEX method here everytime to update the status every second
    }

    // this method is ran by the framework when the user leaves the page with the LWC, and stops the component to free up browser memory
    disconnectedCallback(){
        clearInterval(this.timer);
        this.timer = null;
    }

    // METHODS
    calculateTime(){
        if (!this.caseData || !this.settingsSLA){
            return;
        }

        let timeSLA;
        const isPaused = getFieldValue(this.caseData, SLA_PAUSED_FIELD);
        const startSLA = new Date(getFieldValue(this.caseData, SLA_START_FIELD)).getTime();
        const totalPause = (getFieldValue(this.caseData, SLA_TOTAL_PAUSED_MINUTES_FIELD) || 0) * 60000;
        const statusSLA = getFieldValue(this.caseData, SLA_STATUS_FIELD);

        const warningValueSLA = (this.settingsSLA.Warning_Hours__c) * 60000; // even though field says hours it;s minutes, must be fixed
        const breachValueSLA = (this.settingsSLA.Breach_Hours__c) * 60000;
        
        // if currently paused, we just show the 
        if (isPaused){
            const startPauseSLA = getFieldValue(this.caseData, SLA_PAUSE_START_FIELD).getTime();
            timeSLA = (startPauseSLA - startSLA) - totalPause;       // time in ms
        }
        else {
            const now = new Date().getTime();
            timeSLA = (now - startSLA) - totalPause;       // time in ms
        }

        if (timeSLA > 0){
            this.formattedTimeSLA = this.formatTime(timeSLA);
        }
        else{
            this.formattedTimeSLA = "00:00:00";
        }

        if (timeSLA >= warningValueSLA && timeSLA < breachValueSLA){
            if (statusSLA != 'Warning'){
                updateStatusToWarning({ recordId: this.recordId })
                .then(() => {
                    console.log('Status updated to "Warning"!');
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                })
                .catch(error => console.error(error));
            }

            let diffToBreach = breachValueSLA - timeSLA;
            this.formattedDiffToBreachSLA = this.formatTime(diffToBreach);
        }
        if (timeSLA < warningValueSLA){
            if (statusSLA != 'On Track'){
                updateStatusToOnTrack({ recordId: this.recordId })
                .then(() => {
                    console.log('Status updated to "On Track"!');
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                })
                .catch(error => console.error(error));
            }
        }
        if (timeSLA >= breachValueSLA){
            if (statusSLA != 'Breached'){
                updateStatusToBreached({recordId : this.recordId})
                .then(() => {
                    console.log('Status updated to "Breached"!');
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                })
                .catch(error => console.error(error));
            }
            
            if (!this.breachDT) {
                const breachTimestampMs = startSLA + breachValueSLA + totalPause;
                this.breachDT = this.formatDateTime(new Date(breachTimestampMs));
            }

            let diffToBreach = timeSLA - breachValueSLA;
            this.formattedDiffToBreachSLA = this.formatTime(diffToBreach);
        }
    }

    formatTime(ms){
        let totalSeconds = Math.floor(ms / 1000);                // get total SLA time in seconds
        let hours = Math.floor(totalSeconds / 3600);             // get number of hours 
        let minutes = Math.floor((totalSeconds % 3600) / 60);    // get number of remaining minutes
        let seconds = totalSeconds % 60;                         // get number of remaing seconds

        const hh = String(hours).padStart(2, '0');
        const mm = String(minutes).padStart(2, '0');
        const ss = String(seconds).padStart(2, '0');

        const timeString = `${hh}:${mm}:${ss}`;

        return timeString;
    }

    formatDateTime(inputDate) {
        const d = new Date(inputDate);
    
        const day = String(d.getDate()).padStart(2, '0');
        const month = String(d.getMonth() + 1).padStart(2, '0'); 
        const year = String(d.getFullYear()).slice(-2); 
    
        const hours = String(d.getHours()).padStart(2, '0');
        const minutes = String(d.getMinutes()).padStart(2, '0');
        const seconds = String(d.getSeconds()).padStart(2, '0');
    
        return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
    }

    // GETTERS
    get isSlaActive(){
        return getFieldValue(this.caseData, SLA_ACTIVE_FIELD);
    }

    get statusLabel(){
        return this.caseData ? getFieldValue(this.caseData, SLA_STATUS_FIELD) : null; // avoid "undefined" situation
    }

    get badgeClass() {
        const status = this.statusLabel;
        if (status === 'Breached') return 'slds-theme_error';
        if (status === 'Warning') return 'slds-theme_warning';
        if (status === 'On Track') return 'slds-theme_success';
        return 'slds-theme_info';
    }

    get isWarning(){
        const status = this.statusLabel;
        return status === 'Warning';
    }

    get isBreached(){
        const status = this.statusLabel;
        return status === 'Breached';
    }

    get needleTransform() {
        let rotation = -60; 
        const status = this.statusLabel;
     
        if (status === 'On Track') {
            rotation = -60; 
        } 
        else if (status === 'Warning') {
            rotation = 0;   
        } 
        else if (status === 'Breached') {
            rotation = 60;  
        }
    
        return `rotate(${rotation} 100 100)`;
    }
}
