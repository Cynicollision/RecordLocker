@isTest
public with sharing class RecordLockerTest {
    private static final String testId = '000000000123123123';

    @isTest
    public static void test_getLockStatus() {
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);

        // Case 1: object is not locked.
        RecordLocker.StatusResult result = RecordLocker.getLockStatus(request);
        System.assertEquals(true, result.canLockRecord, 'Expected to be able to lock the record.');

        // Case 2: object is already locked.
        Object_Lock__c testLock = new Object_Lock__c(sObject_Id__c = testId, Expires_At__c = Datetime.now().addMinutes(5)); 
        insert testLock;

        result = RecordLocker.getLockStatus(request);
        System.assertEquals(false, result.canLockRecord, 'Expected to not be able to lock the record.');

        // Case 3: object is locked but the lock has expired.
        testLock.Expires_At__c = Datetime.now().addMinutes(-5);
        update testLock;

        result = RecordLocker.getLockStatus(request);
        Integer lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(true, result.canLockRecord, 'Expected to be able to lock the record.');
        System.assertEquals(0, lockCount, 'Expected expired lock to have been deleted.');
    }
    
    @isTest
    public static void test_lockRecord_success() {
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);
        
        RecordLocker.LockResult result = RecordLocker.lockRecord(request);

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
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);

        RecordLocker.LockResult result = RecordLocker.lockRecord(request);

        Integer lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(1, lockCount, 'Expected no Object Lock record(s) to be created.');
        System.assertEquals(true, result.didSucceed, 'Expected lock request to fail.');
    }

    @isTest
    public static void test_unlockRecord() {
        RecordLocker.LockRequest request = new RecordLocker.LockRequest(testId);

        RecordLocker.LockResult lockResult = RecordLocker.lockRecord(request);
        Integer lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(1, lockCount, 'Expected an initial Object Lock record to be created.');
        System.assertEquals(true, lockResult.didSucceed, 'Expected initial lock request to succeed.');

        RecordLocker.UnlockResult unlockResult = RecordLocker.unlockRecord(request);
        lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(0, lockCount, 'Expected the lock to have been released.');
        System.assertEquals(true, unlockResult.didSucceed, 'Expected unlock request to succeed.');
    }
}
