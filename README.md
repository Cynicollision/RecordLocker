# sObject Record Locker
WIP tool for locking and collaborating on high-traffic Salesforce records.


### Development Setup
Create a fresh scratch org if necessary:
```
sfdx force:org:create -a NewScratchOrgAlias -v DevHubOrgAlias -f config/project-scratch-def.json
```

Push the project:
```
sfdx force:source:push -u NewScratchOrgAlias
```

Open the scratch org:
```
sfdx force:org:open -u NewScratchOrgAlias
```

#### Notes
FlexiPages in the DX app are for development/testing purposes only and not to be included in the final product.

