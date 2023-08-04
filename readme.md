# AMS 6.7 SSL Certs with Lets Encrypt

Please note that this is suitable only for dev/test and Sectigo should be used for production 

# Setup prerequisites

 1. Create folder `C:\Installs\AMS_Files\renew_certs`  
 2. Copy `renew_certs.ps1` to `C:\Installs\AMS_Files\renew_certs`
 3. Download win-acme.v2.2.5.1541.x64.pluggable from [Github](https://github.com/win-acme/win-acme/releases/download/v2.2.5.1541/win-acme.v2.2.5.1541.x64.
 pluggable.zip)
 4. Extract `win-acme.v2.2.5.1541.x64.pluggable.zip` to `C:\Installs\AMS_Files\renew_certs`
 5. Update RabbitMQ Advanced Config. Replace `C:\Users\amsweb-admin\AppData\Roaming\RabbitMQ\advanced.config` with the contents of 

```
[
{rabbit, [
     {tcp_listeners, []},
     {ssl_listeners, [5671]},
     {ssl_options, [{cacertfile,"C:\\Installs\\AMS_Files\\Certs_latest\\rabbitmq-chain.pem"},
                    {certfile,"C:\\Installs\\AMS_Files\\Certs_latest\\rabbitmq-crt.pem"},
                    {keyfile,"C:\\Installs\\AMS_Files\\Certs_latest\\rabbitmq-key.pem"},
		    {password,  "secure password"}]}
]}
].
```
6. Note the same `Secure Password` is used by both Rabbit and renew_cers.ps1. It must be the same password in both.
7. Next create a config.json which will be used by the renew_certs.ps1 to renew the LetsEncrypt Certs
8. Put the config.json it in the same folder as this powershell script `renew_certs.ps1`.  
9. See sample config.json below:   
```json
{
        "CERTS": {
                "domain": "ams-web-ams7-operations-sandbox.westeurope.cloudapp.azure.com",
                "OutputPath": "C:\\Installs\\AMS_Files\\Certs_latest",
                "Password": "secure password",
                "BackupPath": "C:\\Installs\\AMS_Files\\cert_backups",
                "PathToExe": "C:\\Installs\\renew_certs\\win-acme.v2.2.5.1541.x64.pluggable",
                "ExeName": "wacs.exe"
        },
        "AMS": {
                "PathToRestAPI": "C:\\Program Files\\WorkBridge\\AMS_TLS_6.7.2\\AMS REST API 1",
                "PathToSoapAPI": "C:\\Program Files\\WorkBridge\\AMS_TLS_6.7.2\\AMS Web API Server 1",
                "RestAPIServiceName": "WorkBridge AMS_TLS_6.7.2 AMS REST API 1",
                "SoapAPIServiceName": "WorkBridge AMS_TLS_6.7.2 AMS Web API Server 1",
                "AMSFlightProcessingServiceName": "WorkBridge AMS_TLS_6.7.2 Seasonal Flight Processing Service",
                "AMSServerServiceName": "WorkBridge AMS_TLS_6.7.2 AMS Server 1",
                "AMSDWServiceName": "WorkBridge AMS_TLS_6.7.2 AMS Data Warehouse Server 1",
                "RabbitMQServiceName": "RabbitMQ"
        }
}
```

## Running renew_certs.ps1

Run the following command to renew the Lets encrypt certificates. Note it defaults to reading in config.json in the same directory as the powerschell script 
```powershell
.\renew_certs.ps1 
```

Use -ConfigFile paremeter If you want to use a different file name    
```powershell
.\renew_certs.ps1 -ConfigFile config-ams-web-ams7-operations-sandbox.json
```

Once the script is run does the following:
1. Backs up the old certificates in to a zip file and stores in the BackupPath defined in the confg.json
2. Generates a Pem Certificate set of files used by RabbitMQ and stores in the OutputPath defined in the confg.json
3. Generates a PFX Certificate used by AMS and stores in the OutputPath defined in the confg.json
4. Copies the PFX files to the RestAPPathToRestAPI defined in the config.json
5. Copies the PFX files to the PathToSoapAPI defined in the config.json
           
6. Restarts RabbitMQ service defined as `RabbitMQServiceName` in config.json 
6. Restarts AMS components defined as `AMSFlightProcessingServiceName, RestAPIServiceName, SoapAPIServiceName, AMSServerServiceName, AMSFlightProcessingServiceName` in config.json 

### Generated Certificates

The folowing is a list of the certificates Generated:
```
PS C:\Installs\AMS_Files\Certs_latest> ls


    Directory: C:\Installs\AMS_Files\Certs_latest


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       31/07/2023     21:51           7022 cert.pfx
-a----       31/07/2023     21:44           3810 rabbitmq-chain-only.pem
-a----       31/07/2023     21:44           5908 rabbitmq-chain.pem
-a----       31/07/2023     21:44           2098 rabbitmq-crt.pem
-a----       31/07/2023     21:44           2588 rabbitmq-key.pem

```

