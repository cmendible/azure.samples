resource_group=$(terraform output -raw resource_group)
mysql_name=$(terraform output -raw mysql_name)
mysql_user=$(terraform output -raw administrator_login)
mysql_password=$(terraform output -raw administrator_password)

az mysql flexible-server db create --resource-group $resource_group --server-name $mysql_name --database-name failover_database

az mysql flexible-server connect -n $mysql_name -u $mysql_user -p $mysql_password -d failover_database
