import { LightningElement, api, track } from 'lwc';
import getObjectLockConfig from '@salesforce/apex/LockerConfig.getObjectLockConfig';

export default class LockerBase extends LightningElement {
    @api recordId;
    @track isDisabled = false;
    @track isLoading = false;
    @track isReady = false;
    @track disabledMessage = null;

    // Initialize component.
    connectedCallback() {
        this.isLoading = true;

        let request = {
            sObjectId: this.recordId,
        };

        getObjectLockConfig(request)
            .then(result => {
                this.isLoading = false;
                
                if (result.isLockingEnabled) {
                    this.isReady = true;
                }
                else {
                    this.isDisabled = true;
                    this.disabledMessage = result.message;
                }
            })
            .catch(result => {
                this.isDisabled = true;
                this.disabledMessage = result;
            });
    }
}