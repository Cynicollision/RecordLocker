@isTest
public with sharing class RecordLockerTest {
    private static final String testId = '000000000123123123';
    
    @isTest
    public static void test_lockRecord_success() {
        RecordLocker locker = new RecordLocker(new LockValidatorMock(true));
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);
        
        RecordLocker.LockResult result = locker.lockRecord(request);

        Object_Lock__c lock = [
            SELECT Id 
            FROM Object_Lock__c 
            WHERE sObject_Id__c = :testId 
                AND User__c = :UserInfo.getUserId()
            LIMIT 1
        ];

        System.assertEquals(true, result.didSucceed, 'Expected lock request to succeed.');
        System.assert(lock != null, 'Expected Object Lock record to be created.');
    }

    @isTest
    public static void test_lockRecord_fail() {
        RecordLocker locker = new RecordLocker(new LockValidatorMock(false));
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);

        RecordLocker.LockResult result = locker.lockRecord(request);

        Integer lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(0, lockCount, 'Expected no Object Lock record(s) to be created.');
        System.assertEquals(false, result.didSucceed, 'Expected lock request to fail.');
    }

    @isTest
    public static void test_unlockRecord() {
        RecordLocker locker = new RecordLocker(new LockValidatorMock(true));
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);

        RecordLocker.LockResult lockResult = locker.lockRecord(request);
        Integer lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(1, lockCount, 'Expected an initial Object Lock record to be created.');
        System.assertEquals(true, lockResult.didSucceed, 'Expected initial lock request to succeed.');

        RecordLocker.UnlockResult unlockResult = locker.unlockRecord(request);
        lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(0, lockCount, 'Expected the lock to have been released.');
        System.assertEquals(true, unlockResult.didSucceed, 'Expected unlock request to succeed.');
    }
}
