## SonarQube

``` powershell
az group create --name Sonar --location <region>
az container create -g Sonar --name sonarqubeaci --image sonarqube --ports 9000 --dns-name-label sonarci --cpu 2 --memory 3.5
```

