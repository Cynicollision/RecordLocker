import { LightningElement, api, track } from 'lwc';

export default class Locker extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track isLockUnlockDisabled = false;
    @track hasLock = false;
    @track hasLockWait = false;
    // @track lockExpiresIn = null;
    @track lockStatusMessage = null;

    get lockUnlockButtonText() {
        return this.hasLock ? 'Unlock' : 'Lock';
    };

    get lockUnlockButtonIcon() {
        return this.hasLock ? 'utility:unlock' : 'utility:lock';
    };

    get canRequestLockWait() {
        return !this.hasLockWait;
    }

    // Initialize component.
    connectedCallback() {
        // TODO: Query for existing locks on this record, then set: isLockUnlockDisabled, hasLock, hasLockWait, lockExpiresIn, lockStatusMessage
        this.lockStatusMessage = 'This record is unlocked.';
    }

    onClickLockUnlock() {
        this.isLoading = true;

        // TODO: Attempt to lock record.
        // If successful: hasLock -> true, lockExpiresIn -> (time until result.lock.Expires_At__c)
        // If not: lockedByUserName -> 
        setTimeout(() => {
            this.hasLock = !this.hasLock;
            this.isLoading = false;
        }, 2000);
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
}