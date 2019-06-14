public with sharing class LockedObjectTriggerHandler {
    
    public static SaveResult handle(Map<Id, SObject> sObjects) {

        List<Object_Lock__c> locks = [
            SELECT sObject_Id__c, Expires_At__c, User__c
            FROM Object_Lock__c 
            WHERE sObject_Id__c IN :sObjects.keySet()
        ];

        List<Object_Lock__c> locksToDelete = new List<Object_Lock__c>();
        LockValidator validator = new LockValidator();
        SaveResult result = new SaveResult(true);

        for (Object_Lock__c lock : locks) {
            if (validator.doesCurrentUserOwnLock(lock) || validator.isLockExpired(lock)) {
                locksToDelete.add(lock);
            }
            else {
                result = new SaveResult(false, 'Unable to save due to one or more locked records.');
                sObjects.get(lock.sObject_Id__c).addError('Cannot save locked record.');
            }
        }

        if (locksToDelete.size() > 0) {
            delete locksToDelete;
        }

        return result;
    }

    public class SaveResult extends BaseResult {
        public SaveResult(Boolean didSucceed) {
            this(didSucceed, null);
        }

        public SaveResult(Boolean didSucceed, String message) {
            super(didSucceed, message);
        }
    }
}
