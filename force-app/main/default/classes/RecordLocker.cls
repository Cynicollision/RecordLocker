public with sharing class RecordLocker {

    public class LockRequest {
        public String sObjectId;

        public LockRequest(String sObjectId) {
            this.sObjectId = sObjectId;
        }
    }

    public class ObjectLock {
        public String sObjectId;
        public String userId;
        public Datetime expiresAt;

        public ObjectLock(Object_Lock__c lock) {
            this.sObjectId = lock.sObject_Id__c;
            this.userId = lock.User__c;
            this.expiresAt = lock.Expires_At__c;
        }
    }

    @AuraEnabled
    public static LockStatusResult getLockStatus(LockRequest request) {
        return new RecordLocker().getStatus(request);
    }

    public LockStatusResult getStatus(LockRequest request) {
        try {
            List<Object_Lock__c> locks = [
                SELECT Id, Expires_At__c, User__r.Name 
                FROM Object_Lock__c 
                WHERE sObject_Id__c = :request.sObjectId
            ];

            List<Object_Lock__c> activeLocks = new List<Object_Lock__c>();
            List<Object_Lock__c> expiredLocks = new List<Object_Lock__c>();

            for (Object_Lock__c lock : locks) {
                (lock.Expires_At__c > Datetime.now() ? activeLocks : expiredLocks).add(lock);
            }

            delete expiredLocks;

            if (activeLocks.size() == 1) {
                return new LockStatusResult(true, false, activeLocks[0].User__r.Name);
            }

            return new LockStatusResult(true, true);
        }
        catch (Exception e) {
            return new LockStatusResult(false, 'An unexpected error happened: ' + e.getMessage());
        }
    }

    public class LockStatusResult extends BaseResult {
        @AuraEnabled
        public String lockedByUserName;

        @AuraEnabled
        public Boolean canLockRecord;

        public LockStatusResult(Boolean didSucceed, Boolean canLockRecord, String lockedByUserName) {
            this(didSucceed, (String)null);
            this.canLockRecord = canLockRecord;
            this.lockedByUserName = lockedByUserName;
        }

        public LockStatusResult(Boolean didSucceed, Boolean canLockRecord) {
            this(didSucceed, (String)null);
            this.canLockRecord = canLockRecord;
            this.lockedByUserName = lockedByUserName;
        }

        public LockStatusResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
        }
    }

    @AuraEnabled
    public static LockResult lockRecord(LockRequest request) {
        return new RecordLocker().lock(request);
    }

    public LockResult lock(LockRequest request) {
        try {
            LockStatusResult result = getStatus(request);

            if (!result.canLockRecord) {
                return new LockResult(false, 'This record is locked by ' + result.lockedByUserName);
            }

            Datetime expiresAt = LockerUtil.getExpirationDatetime(request.sObjectId);
            
            Object_Lock__c lock = new Object_Lock__c(sObject_Id__c = request.sObjectId, Expires_At__c = expiresAt, User__c = UserInfo.getUserId()); 
            insert lock;

            return new LockResult(true, new ObjectLock(lock));
        }
        catch (Exception e) {
            return new LockResult(false, 'An unexpected error happened: ' + e.getMessage());
        }
    }

    public class LockResult extends BaseResult {
        @AuraEnabled
        public ObjectLock lock;

        public LockResult(Boolean didSucceed, ObjectLock lock) {
            this(didSucceed, (String)null);
            this.lock = lock;
        }

        public LockResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
        }
    }

    @AuraEnabled
    public static UnlockResult unlockRecord(LockRequest request) {
        return new RecordLocker().unlock(request);
    }

    public UnlockResult unlock(LockRequest request) {
        
        try {
            List<Object_Lock__c> locks = [
                SELECT Id
                FROM Object_Lock__c 
                WHERE sObject_Id__c = :request.sObjectId 
                    AND User__c = :UserInfo.getUserId()
            ];

            delete locks;

            return new UnlockResult(true);
        }
        catch (Exception e) {
            return new UnlockResult(false, 'An unexpected error happened: ' + e.getMessage());
        }
    }

    public class UnlockResult extends BaseResult {
        public UnlockResult(Boolean didSucceed) {
            this(didSucceed, null);
        }

        public UnlockResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
        }
    }
}
