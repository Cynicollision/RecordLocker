import { LightningElement, api, track } from 'lwc';
import lockRecord from '@salesforce/apex/RecordLocker.lock';
import unlockRecord from '@salesforce/apex/RecordLocker.unlock';

export default class Locker extends LightningElement {
    @api recordId;
    @track errorMessage = '';
    @track isLoading = false;
    @track isLockUnlockDisabled = false;
    @track hasLock = false;
    @track hasLockWait = false;
    @track lockExpiresIn = null;
    @track lockStatusMessage = null;

    get lockUnlockButtonText() {
        return this.hasLock ? 'Unlock' : 'Lock';
    }

    get lockUnlockButtonIcon() {
        return this.hasLock ? 'utility:unlock' : 'utility:lock';
    }

    get canRequestLockWait() {
        return !this.hasLockWait;
    }

    get hasError() {
        return errorMessage && errorMessage.length;
    }

    // Initialize component.
    connectedCallback() {
        // TODO: Query for existing locks on this record, then set: isLockUnlockDisabled, hasLock, hasLockWait, lockExpiresIn, lockStatusMessage
        this.lockStatusMessage = 'This record is unlocked.';
    }

    onClickLockUnlock() {
        this.isLoading = true;

        let params = {
            sObjectId: this.recordId,
        };

        let isLocking = !this.hasLock;
        let promise = isLocking ? lockRecord(params) : unlockRecord(params);

        promise.then(result => {
            this.isLoading = false;

            if (result.didSucceed) {
                this.hasLock = true;
                this.hasLockwait = false;
                this.lockExpiresIn = result.lock.expiresAt;
            }
            else if (result.lockedByUserName) {
                this.hasLock = false;
                this.hasLockwait = false;
                this.isLockUnlockDisabled = true;
                this.lockStatusMessage = `This record is currently locked by ${lockedByUserName}.`;
            }
            else {
                this.handleError(result.message);
            }
        });

        // TODO: Attempt to lock record.
        // If successful: hasLock -> true, lockExpiresIn -> (time until result.lock.Expires_At__c)
        // If not: lockedByUserName -> 
        // setTimeout(() => {
        //     this.hasLock = !this.hasLock;
        //     this.isLoading = false;
        // }, 2000);
    }

    onClickRequestNotification() {
        this.isLoading = true;

        // TODO:
        setTimeout(() => {
            this.isLoading = false;
            this.hasLockWait = true;
        }, 2000);
    }

    onClickExtend() {
        this.isLoading = true;

        // TODO:
        setTimeout(() => {
            this.isLoading = false;
        }, 2000);
    }

    onClickRefresh() {
        this.isLoading = true;

        // TODO:
        setTimeout(() => {
            this.isLoading = false;
        }, 2000);
    }

    handleError(errorMessage) {
        this.errorMessage = errorMessage;
    }
}