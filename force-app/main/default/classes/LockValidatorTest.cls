@isTest
public with sharing class LockValidatorTest {
    private static final String testId = '000000000123123123';
    private static final String anotherTestId = '000000000456456456';

    @isTest
    public static void test_canLockObject() {
        LockValidator validator = new LockValidator();

        // Case 1: object is not locked.
        LockValidator.CanLockResult result = validator.canLockObject(testId);
        System.assertEquals(true, result.canLockRecord, 'Expected to be able to lock the record.');

        // Case 2: object is already locked.
        Object_Lock__c testLock = new Object_Lock__c(sObject_Id__c = testId, Expires_At__c = Datetime.now().addMinutes(5)); 
        insert testLock;

        result = validator.canLockObject(testId);
        System.assertEquals(false, result.canLockRecord, 'Expected to not be able to lock the record.');

        // Case 3: object is locked but the lock has expired.
        testLock.Expires_At__c = Datetime.now().addMinutes(-5);
        update testLock;

        result = validator.canLockObject(testId);
        Integer lockCount = [SELECT COUNT() FROM Object_Lock__c];

        System.assertEquals(true, result.canLockRecord, 'Expected to be able to lock the record.');
        System.assertEquals(0, lockCount, 'Expected expired lock to have been deleted.');
    }

    @isTest
    public static void test_currentUserOwnsLock() {
        LockValidator validator = new LockValidator();

        Object_Lock__c lock1 = new Object_Lock__c(sObject_Id__c = testId, User__c = UserInfo.getUserId());
        Object_Lock__c lock2 = new Object_Lock__c(sObject_Id__c = anotherTestId, User__c = null);
        insert new List<Object_Lock__c> { lock1, lock2 };

        // Case 1: current user owns the lock.
        System.assert(validator.doesCurrentUserOwnLock(lock1), 'Expected current user to own the first lock.');

        // Case 2: current user does not own the lock.
        System.assert(!validator.doesCurrentUserOwnLock(lock2), 'Expected current user to not own the second lock.');
    }

    @isTest
    public static void test_isLockExpired() {
        LockValidator validator = new LockValidator();

        Object_Lock__c lock1 = new Object_Lock__c(sObject_Id__c = testId, Expires_At__c = Datetime.now().addMinutes(2));
        Object_Lock__c lock2 = new Object_Lock__c(sObject_Id__c = testId, Expires_At__c = Datetime.now().addMinutes(-2));

        // Case 1: lock has not yet expired.
        System.assert(!validator.isLockExpired(lock1));

        // Case 2: lock has already expired.
        System.assert(validator.isLockExpired(lock2));
    }
}
