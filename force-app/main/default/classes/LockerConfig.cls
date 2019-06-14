public with sharing class LockerConfig {

    @AuraEnabled
    public static GetConfigResult getObjectLockConfig(String sObjectId) {
        String objectName = getObjectAPIName(sObjectId);

        List<Locker_Config__mdt> configs = [
            SELECT Active__c, Timeout__c 
            FROM Locker_Config__mdt 
            WHERE MasterLabel = :objectName
        ];

        if (Test.isRunningTest()) {
            configs = getTestConfigs();
        }

        if (configs.size() == 0) {
            return new GetConfigResult(false, 'Record Locking has not been configured for the ' + objectName + ' object. Please contact your administrator.');
        }

        Locker_Config__mdt config = configs[0];

        if (!config.Active__c) {
            return new GetConfigResult(false, 'Record Locking is disabled for the ' + objectName + ' object. Please contact your administrator.');
        }

        return new GetConfigResult(true, new ObjectConfig(config));
    }

    private static String getObjectAPIName(String sObjectId) {
        String prefix = sObjectId.substring(0,3);

         for (Schema.SObjectType obj : Schema.getGlobalDescribe().Values()) {
            if (obj.getDescribe().getKeyPrefix() == prefix) {
                return obj.getDescribe().getName();
            }
         }

         if (Test.isRunningTest()) {
             return 'TestObject';
         }

         return null;
    }

    private static List<Locker_Config__mdt> getTestConfigs() {
        return new List<Locker_Config__mdt> {
            new Locker_Config__mdt(MasterLabel = 'TestObject', Active__c = true, Timeout__c = 5)
        };
    }

    public class GetConfigResult extends BaseResult {
        @AuraEnabled
        public Boolean isLockingEnabled;

        public ObjectConfig config;

        public GetConfigResult(Boolean isLockingEnabled, ObjectConfig config) {
            super(true);
            this.isLockingEnabled = isLockingEnabled;
            this.config = config;
        }

        public GetConfigResult(Boolean isLockingEnabled, String message) {
            super(true, message);
            this.isLockingEnabled = isLockingEnabled;
        }
    }

    public class ObjectConfig {
        public Boolean active;
        public Integer timeout;

        public ObjectConfig(Locker_Config__mdt config) {
            this.active = config.Active__c;
            this.timeout = config.Timeout__c != null ? ((Decimal)config.Timeout__c).intValue() : 0;
        }
    }
}
