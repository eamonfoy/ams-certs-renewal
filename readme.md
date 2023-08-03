# AMS 6.7 SSL Certs with Lets Encrypt

Please not that this is suitable only for dev/test and Sectigo should be used for production 

# Setup prerequisites

 1. Create folder `C:\Installs\AMS_Files\renew_certs`  
 2. Copy `renew_certs.ps1` to `C:\Installs\AMS_Files\renew_certs`
 3. Download win-acme.v2.2.5.1541.x64.pluggable from [Github](https://github.com/win-acme/win-acme/releases/download/v2.2.5.1541/win-acme.v2.2.5.1541.x64.
 pluggable.zip)
 4. Extract `win-acme.v2.2.5.1541.x64.pluggable.zip` to `C:\Installs\AMS_Files\renew_certs`


# Update RabbitMQ Advanced Config

 - Replace `C:\Users\amsweb-admin\AppData\Roaming\RabbitMQ\advanced.config` with the contents of 

```json
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

# Certification Renewal

Instructions:   
    - Please prepare a config.json    
    - Put it in the same folder as this powershell script.  
    - /Users/eamonfoy/Documents/dev/ams-ops-sandbox/renew_certs.ps1.  
    - See sample config.json below:   

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

Run the following command
```powershell
.\renew_certs.ps1
```

