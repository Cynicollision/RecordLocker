import { LightningElement, track } from 'lwc';
import getStatus from '@salesforce/apex/RecordLocker.getLockStatus';
import requestWait from '@salesforce/apex/RecordLocker.requestWait';
import lockRecord from '@salesforce/apex/RecordLocker.lockRecord';
import unlockRecord from '@salesforce/apex/RecordLocker.unlockRecord';

class UIState {
    isLoading = false;
    isLockUnlockDisabled = true;
    isRequestWaitDisabled = true;
    isWaiting = false;
    errorMessage = '';
    lockMessage = '';

    setCanLock() {
        this.lockMessage = 'This record is unlocked';
        this.isLockUnlockDisabled = false;
    }

    setError(errorMsg) {
        this.errorMessage = errorMsg;
    }

    setLockedByOther(lockedByUserName) {
        this.lockMessage = `This record is currently locked by ${lockedByUserName}.`;
        this.isLockUnlockDisabled = true;
    }

    setWaiting() {
        this.isLockUnlockDisabled = true;
    }
}

export default class Locker extends LightningElement {
    @track foo;

    @track lock = null;
    @track uiState = new UIState();

    // TODO: move to UIState
    get lockUnlockButtonText() {
        return this.hasLock ? 'Unlock' : 'Lock';
    }

    get lockUnlockButtonIcon() {
        return this.hasLock ? 'utility:unlock' : 'utility:lock';
    }

    get hasError() {
        return this.uiState.errorMessage && this.uiState.errorMessage.length;
    }

    // Initialize component.
    connectedCallback() {
        this.initializeUI();
    }

    initializeUI() {
        let lockRequest = {
            sObjectId: this.recordId,
        };

        getStatus(lockRequest).then(statusResult => {
            if (!statusResult.didSucceed) {
                this.uiState.setError(statusResult.message);
            }
            else if (statusResult.lockedByUserName) {
                this.uiState.setLockedByOther('This record is unlocked.');
            }
            else if (statusResult.canLockRecord) {
                this.uiState.setCanLock();
            }
        });
    }

    onClickLockUnlock() {
        this.isLoading = true;

        let lockRequest = {
            sObjectId: this.recordId,
        };
        
        let isLocking = !!this.lock;

        let promise = isLocking ? this.lockRecord(lockRequest) : this.unlockRecord(lockRequest);
        promise.finally(() => {
            this.isLoading = false;
        });
    }

    lockRecord(lockRequest) {

        getStatus(lockRequest).then(statusResult => {
            if (!statusResult.didSucceed) {
                this.uiState.setError(statusResult.message);
            }

            if (!statusResult.canLockRecord && statusResult.lockedByUserName) {
                this.uiState.setLockedByOtherMessage(statusResult.lockedByUserName);
                return;
            }
            
            lockRecord(lockRequest).then(lockResult => {
                if (!lockResult.didSucceed) {
                    this.uiState.setError(lockResult.message);
                    return;
                }

                this.lock = lockResult.lock;
            });
        });
    }

    unlockRecord(lockRequest) {

        unlockRecord(lockRequest).then(unlockResult => {
            if (!unlockResult.didSucceed) {
                this.uiState.setError(unlockResult.message);
                return;
            }

            this.lock = null;
        });
    }

    onClickRequestNotification() {
        this.isLoading = true;

        let lockRequest = {
            sObjectId: this.recordId,
        };

        requestWait(lockRequest).then(waitResult => {
            if (!waitResult.didSucceed) {
                this.uiState.setError(waitResult.message);
                return;
            }

            this.uiState.isWaiting = true
        });
    }

    onClickRefresh() {
        this.initializeUI();
    }
}
