@isTest
public with sharing class LockedObjectTriggerHandlerTest {
    
    @isTest
    public static void test_afterUpdate_lockExpired() {
        Account testAccount = insertTestAccount();

        RecordLocker locker = new RecordLocker(new LockValidatorMock(true));
        locker.lockRecord(new RecordLocker.LockRequest(testAccount.Id));

        // Find the lock and update it to have been expired.
        Object_Lock__c testLock = [SELECT Expires_At__c FROM Object_Lock__c LIMIT 1];
        testLock.Expires_At__c = Datetime.now().addMinutes(-5);
        update testLock;

        Test.startTest();

        testAccount.Description = 'Test description';
        update testAccount;

        Test.stopTest();

        System.assert(true, 'Expected to be able to save the record with our own expired lock.');
    }

    @isTest
    public static void test_afterUpdate_lockedByOther() {
        Account testAccount = insertTestAccount();

        RecordLocker locker = new RecordLocker(new LockValidatorMock(true));
        locker.lockRecord(new RecordLocker.LockRequest(testAccount.Id));

        // Find the lock and update it to not be owned by the current user.
        Object_Lock__c testLock = [SELECT User__c FROM Object_Lock__c LIMIT 1];
        testLock.User__c = null;
        update testLock;

        Test.startTest();

        try {
            testAccount.Description = 'Test description';
            update testAccount;

            System.assert(false, 'Expected to get an error attempting to save the record locked by another user.');
        }
        catch (DmlException e) {
            System.assert(true);
        }

        Test.stopTest();
    }

    @isTest
    public static void test_afterUpdate_lockedByOtherExpire() {
        Account testAccount = insertTestAccount();

        RecordLocker locker = new RecordLocker(new LockValidatorMock(true));
        locker.lockRecord(new RecordLocker.LockRequest(testAccount.Id));

        // Find the lock and update it to have been expired and to not be owned by the current user.
        Object_Lock__c testLock = [SELECT Expires_At__c, User__c FROM Object_Lock__c LIMIT 1];
        testLock.Expires_At__c = Datetime.now().addMinutes(-5);
        testLock.User__c = null;
        update testLock;

        Test.startTest();

        testAccount.Description = 'Test description';
        update testAccount;

        Test.stopTest();

        System.assert(true, 'Expected to be able to save the record with the expired lock.');
    }

    private static Account insertTestAccount() {
        Account a = new Account(Name = 'Test Account');
        insert a;

        return a;
    }
}
