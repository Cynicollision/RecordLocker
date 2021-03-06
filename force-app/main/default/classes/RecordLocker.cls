public with sharing class RecordLocker {

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
    public static StatusResult getLockStatus(String sObjectId) {
        return new RecordLocker().getStatus(sObjectId);
    }

    public StatusResult getStatus(String sObjectId) {
        try {
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

            if (activeLocks.size() == 1) {
                String userName = activeLocks[0].User__r != null ? activeLocks[0].User__r.Name : 'UNKNOWN';
                return new StatusResult(true, false, userName);
            }

            return new StatusResult(true, true);
        }
        catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
        }
    }

    public class StatusResult extends BaseResult {
        @AuraEnabled
        public String lockedByUserName;

        @AuraEnabled
        public Boolean canLockRecord;

        public StatusResult(Boolean didSucceed, Boolean canLockRecord, String lockedByUserName) {
            this(didSucceed, (String)null);
            this.canLockRecord = canLockRecord;
            this.lockedByUserName = lockedByUserName;
        }

        public StatusResult(Boolean didSucceed, Boolean canLockRecord) {
            this(didSucceed, (String)null);
            this.canLockRecord = canLockRecord;
            this.lockedByUserName = lockedByUserName;
        }

        public StatusResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
        }
    }

    @AuraEnabled
    public static LockResult lockRecord(String sObjectId) {
        return new RecordLocker().lock(sObjectId);
    }

    public LockResult lock(String sObjectId) {
        try {
            StatusResult result = getStatus(sObjectId);

            if (!result.canLockRecord) {
                return new LockResult(false, 'This record is locked by ' + result.lockedByUserName);
            }

            Datetime expiresAt = LockerUtil.getExpirationDatetime(sObjectId);
            
            Object_Lock__c lock = new Object_Lock__c(sObject_Id__c = sObjectId, Expires_At__c = expiresAt, User__c = UserInfo.getUserId()); 
            insert lock;

            return new LockResult(true, new ObjectLock(lock));
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
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
    public static UnlockResult unlockRecord(String sObjectId) {
        try {
            List<Object_Lock__c> locks = [
                SELECT Id
                FROM Object_Lock__c 
                WHERE sObject_Id__c = :sObjectId 
                    AND User__c = :UserInfo.getUserId()
            ];

            delete locks;

            return new UnlockResult(true);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
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

    @AuraEnabled
    public static WaitResult requestWait(String sObjectId) {
        try {
            // TODO: 
            // Integer lockWaitCount = [SELECT COUNT() FROM Object_Lock_Wait__c WHERE sObject_Id__c = :request.sObjectId];
            // if (lockWaitCount != 0) {
            //     return new WaitResult(true, false);
            // }
            return new WaitResult(true, true);
        }
        catch (Exception e) {
            return new WaitResult(false, 'An unexpected error happened: ' + e.getMessage());
        }
    }

    public class WaitResult extends BaseResult {
        @AuraEnabled
        public Boolean canWait;

        public WaitResult(Boolean didSucceed, Boolean canWait) {
            this(didSucceed, (String)null);
            this.canWait = canWait;
        }

        public WaitResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
            this.canWait = false;
        }
    }
}
