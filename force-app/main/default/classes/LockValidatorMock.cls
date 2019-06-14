public with sharing class LockValidatorMock implements ILockValidator {
    private Boolean canLock;

    public LockValidatorMock(Boolean canLock) {
        this.canLock = canLock;
    }

    public LockValidator.CanLockResult canLockObject(String sObjectId) {
        return canLock ? new LockValidator.CanLockResult(true) : new LockValidator.CanLockResult(false, 'Mock User');
    }
}
