import { LightningElement, api, track } from 'lwc';
import getObjectLockConfig from '@salesforce/apex/LockerConfig.getObjectLockConfig';
import getStatus from '@salesforce/apex/RecordLocker.getLockStatus';
import requestWait from '@salesforce/apex/RecordLocker.requestWait';
import lockRecord from '@salesforce/apex/RecordLocker.lockRecord';
import unlockRecord from '@salesforce/apex/RecordLocker.unlockRecord';


export default class Locker extends LightningElement {
    @api recordId;
    @track lock = null;

    // UI State
    @track isDisabled = false;
    @track isLoading = false;
    @track isLockUnlockDisabled = true;
    @track isReady = false;
    @track isRequestWaitDisabled = true;
    @track isWaiting = false;
    @track errorMessage = '';
    @track statusMessage = '';

    get lockUnlockButtonText() {
        return this.hasLock ? 'Unlock' : 'Lock';
    }

    get lockUnlockButtonIcon() {
        return this.hasLock ? 'utility:unlock' : 'utility:lock';
    }

    get hasError() {
        return this.errorMessage && this.errorMessage.length;
    }

    // Initialize component.
    connectedCallback() {
        this.isLoading = true;

        getObjectLockConfig(this.recordId)
            .then(result => {
                if (result.isLockingEnabled) {
                    this.initializeUI();
                }
                else {
                    this.isDisabled = true;
                    this.disabledMessage = result.message;
                }
            })
            .catch(error => {
                this.isDisabled = true;
                this.setError(error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    initializeUI() {
        this.isLoading = true;

        getStatus(this.recordId)
            .then(statusResult => {
                if (!statusResult.didSucceed) {
                    this.setError(statusResult.message);
                }
                else if (statusResult.lockedByUserName) {
                    this.setLockedByOther('This record is unlocked.');
                }
                else if (statusResult.canLockRecord) {
                    this.setCanLock();
                }
            })
            .catch(error => {
                this.setError(`Unexpected error getting lock status: ${error.body.message}`);
            })
            .finally(() => {
                this.isLoading = false;
                this.isReady = true;
            });
    }

    onClickLockUnlock() {
        this.isLoading = true;

        let isLocking = !this.lock;

        if (isLocking) {
            this.lockRecord()
        }
        else {
            this.unlockRecord();
        }
    }

    lockRecord() {
        this.isLoading = true;

        getStatus(this.recordId)
            .then(statusResult => {
                if (!statusResult.didSucceed) {
                    this.setError(statusResult.message);
                }

                if (!statusResult.canLockRecord && statusResult.lockedByUserName) {
                    this.setLockedByOtherMessage(statusResult.lockedByUserName);
                    return;
                }
                
                lockRecord(this.recordId)
                    .then(lockResult => {
                        if (!lockResult.didSucceed) {
                            this.setError(lockResult.message);
                            return;
                        }

                        this.lock = lockResult.lock;
                    });
            })
            .catch(error => {
                this.setError(`Unexpected error locking record: ${error.body.message}`);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    unlockRecord() {

        unlockRecord(this.recordId)
            .then(unlockResult => {
                if (!unlockResult.didSucceed) {
                    this.setError(unlockResult.message);
                    return;
                }

                this.lock = null;
            })
            .catch(error => {
                this.setError(`Unexpected error unlocking record: ${error.body.message}`);
            });
    }

    onClickRequestNotification() {
        this.isLoading = true;

        requestWait(this.recordId)
            .then(waitResult => {
                if (!waitResult.didSucceed) {
                    this.setError(waitResult.message);
                    return;
                }

                this.isWaiting = true
            })
            .catch(error => {
                this.setError(`Unexpected error waiting for record lock: ${error.body.message}`);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    onClickRefresh() {
        this.initializeUI();
    }

    // UI State helpers
    setCanLock() {
        this.statusMessage = 'This record is unlocked';
        this.isLockUnlockDisabled = false;
    }

    setError(errorMsg) {
        this.errorMessage = errorMsg;
    }

    setLockedByOther(lockedByUserName) {
        this.statusMessage = `This record is currently locked by ${lockedByUserName}.`;
        this.isLockUnlockDisabled = true;
    }

    setWaiting() {
        this.isLockUnlockDisabled = true;
    }
}
