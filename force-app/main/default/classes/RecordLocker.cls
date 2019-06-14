public with sharing class RecordLocker {
    private ILockValidator validator;

    public RecordLocker(ILockValidator validator) {
        this.validator = validator;
    }

    @AuraEnabled
    public static LockResult lock(LockRequest request) {
        return new RecordLocker(new LockValidator()).lockRecord(request);
    }

    @AuraEnabled
    public static UnlockResult unlock(LockRequest request) {
        return new RecordLocker(new LockValidator()).unlockRecord(request);
    }

    public LockResult lockRecord(LockRequest request) {
        try {
            LockValidator.CanLockResult result = validator.canLockObject(request.sObjectId);

            if (!result.canLockRecord) {
                return new LockResult(false, 'This record is locked by ' + result.lockedByUserDisplayName);
            }

            Datetime expiresAt = getExpirationDatetime(request.sObjectId);
            
            Object_Lock__c lock = new Object_Lock__c(sObject_Id__c = request.sObjectId, Expires_At__c = expiresAt, User__c = UserInfo.getUserId()); 
            insert lock;

            return new LockResult(true, new ObjectLock(lock));
        }
        catch (Exception e) {
            return new LockResult(false, 'An unexpected error happened: ' + e.getMessage());
        }
    }

    public UnlockResult unlockRecord(LockRequest request) {
        
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

    private Datetime getExpirationDatetime(String sObjectId) {
        LockerConfig.GetConfigResult result = LockerConfig.getObjectLockConfig(sObjectId);
        LockerConfig.ObjectConfig config = result.config;

        if (config.timeout != null || config.timeout > 0) {
            return Datetime.now().addMinutes(config.timeout);
        }

        return null;
    }

    public class LockRequest {
        public String sObjectId;

        public LockRequest(String sObjectId) {
            this.sObjectId = sObjectId;
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

    public class UnlockResult extends BaseResult {
        public UnlockResult(Boolean didSucceed) {
            this(didSucceed, null);
        }

        public UnlockResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
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
}
