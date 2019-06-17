public with sharing class LockerUtil {

    public static Boolean doesCurrentUserOwnLock(Object_Lock__c lock) {
        return lock.User__c == UserInfo.getUserId();
    }

    public static Datetime getExpirationDatetime(String sObjectId) {
        LockerConfig.GetConfigResult result = LockerConfig.getObjectLockConfig(sObjectId);
        LockerConfig.ObjectConfig config = result.config;

        if (config.timeout != null || config.timeout > 0) {
            return Datetime.now().addMinutes(config.timeout);
        }

        return null;
    }

    public static Boolean isLockExpired(Object_Lock__c lock) {
        return lock.Expires_At__c <= Datetime.now();
    }
}
