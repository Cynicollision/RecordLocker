public abstract class BaseResult {
    @AuraEnabled
    public Boolean didSucceed;

    @AuraEnabled
    public String message;

    public BaseResult() {
    }
    
    public BaseResult(Boolean didSucceed) {
        this(didSucceed, null);
    }

    public BaseResult(Boolean didSucceed, String message) {
        this.didSucceed = didSucceed;
        this.message = message;
    }
}
