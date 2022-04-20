## Deploy Solution

``` powershell
terraform init 
terraform apply --auto-approve
```

> Remember to change DirectLineExtensionKey in the web app.

## Deploy the bot to the web app

``` powershell
az webapp deployment source config-zip -g $resourceGroup -n $webappName -p "bot.zip"
```

## Get Bot Token

``` powershell
curl -X POST -H "Authorization: Bearer <DIRECTLINE_CHANNEL_SECRET>" https://<WEB_SITE_NAME>.azurewebsites.net/.bot/v3/directline/tokens/generate
```

## Generate dotnet project

``` powershell
dotnet new -i Microsoft.Bot.Framework.CSharp.EchoBot
dotnet new -i Microsoft.Bot.Framework.CSharp.CoreBot
dotnet new -i Microsoft.Bot.Framework.CSharp.EmptyBot
dotnet new echobot
az bot prepare-deploy --lang Csharp --code-dir "." --proj-file-path ".\DirectLineEchoBot.csproj"
```
