public with sharing class LockValidator implements ILockValidator {
    
    public CanLockResult canLockObject(String sObjectId) {

        List<Object_Lock__c> locks = [
            SELECT Id, Expires_At__c, User__r.Name 
            FROM Object_Lock__c 
            WHERE sObject_Id__c = :sObjectId
        ];

        List<Object_Lock__c> activeLocks = new List<Object_Lock__c>();
        List<Object_Lock__c> expiredLocks = new List<Object_Lock__c>();

        for (Object_Lock__c lock : locks) {
            (lock.Expires_At__c > Datetime.now() ? activeLocks : expiredLocks).add(lock);
        }

        delete expiredLocks;

        if (activeLocks.size() != 0) {
            return new CanLockResult(false, activeLocks[0].User__r.Name);
        }

        return new CanLockResult(true);
    }

    public Boolean doesCurrentUserOwnLock(Object_Lock__c lock) {
        return lock.User__c == UserInfo.getUserId();
    }

    public Boolean isLockExpired(Object_Lock__c lock) {
        return lock.Expires_At__c <= Datetime.now();
    }

    public class CanLockResult extends BaseResult {
        public Boolean canLockRecord;
        public String lockedByUserDisplayName;

        public CanLockResult(Boolean canLockRecord) {
            this(canLockRecord, null);
        }

        public CanLockResult(Boolean canLockRecord, String lockedByUserDisplayName) {
            super(true);
            this.canLockRecord = canLockRecord;
            this.lockedByUserDisplayName = lockedByUserDisplayName;
        }
    }
}
