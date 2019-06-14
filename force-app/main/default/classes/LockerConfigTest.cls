@isTest
public with sharing class LockerConfigTest {
    private static final String testId = '000000000123123123';

    @isTest 
    public static void test_getObjectLockConfig() {
        LockerConfig.GetConfigResult result = LockerConfig.getObjectLockConfig(testId);
        
        System.assert(result.isLockingEnabled, 'Expected locking to be configured for Test Object.');
        System.assert(result.config.active, 'Expected locking to be enabled for Test Object.');
        System.assertEquals(5, result.config.timeout, 'Expected locking to configured to expire after 5 minutes for Test Object.');
    }
}
