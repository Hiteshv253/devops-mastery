icacls "D:\Azure-Resource\devops-mastery-vm-key.pem" /inheritance:r
icacls "D:\Azure-Resource\devops-mastery-vm-key.pem" /grant:r "%username%:(R)"
icacls "D:\Azure-Resource\devops-mastery-vm-key.pem" /remove "NT AUTHORITY\Authenticated Users"
icacls "D:\Azure-Resource\devops-mastery-vm-key.pem" /remove "BUILTIN\Users"
icacls "D:\Azure-Resource\devops-mastery-vm-key.pem" /remove "BUILTIN\Administrators"
icacls "D:\Azure-Resource\devops-mastery-vm-key.pem" /remove "NT AUTHORITY\SYSTEM"


ssh -i "D:\Azure-Resource\devops-mastery-vm-key.pem" azureuser@20.10.8.70



# Specific resource group ke resources
az resource list --resource-group my-resource-group-azure --output table