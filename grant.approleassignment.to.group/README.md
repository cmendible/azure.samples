az ad sp create-for-rbac -n roleAssigner

Requires 2 Microsoft Graph application permissions:

Permission                      | Type        | Description
------------------------------- | ----------- | -----------------------------------------------------
AppRoleAssignment.ReadWrite.All | Application | Manage app permission grants and app role assignments
Directory.Read.All              | Application | Read directory data
