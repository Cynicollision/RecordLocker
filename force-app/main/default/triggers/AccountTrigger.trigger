trigger AccountTrigger on Account (before update, before delete) {
    LockedObjectTriggerHandler.handle((Map<Id, SObject>)Trigger.newMap);
}