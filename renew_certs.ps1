[CmdletBinding()]
param (
   [Parameter()]
   [System.String]
   $ConfigFile
)


$jsonConfig = "{}"
$global:testRun = $true

function PrintInstructions() {

	$jsonSample = @"
{
	"CERTS": {
		"domain": "ams-web-ams7-operations-sandbox.westeurope.cloudapp.azure.com",
		"OutputPath": "C:\\Installs\\AMS_Files\\Certs_latest",
		"Password": "a secure password",
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
"@
	  Write-Host "`nInstructions:`n - Please prepare a config.json `n - Put it in the same folder as this powershell script" -ForegroundColor Yellow
	  Write-Host " - $PSCommandPath" -ForegroundColor Yellow
	  Write-Host " - See sample config.json below:" -ForegroundColor Yellow
	  Write-Host "`n$jsonSample`n" -ForegroundColor DarkCyan
}

function ReadConfig() {
	 
    if ( $ConfigFile ) {
		Write-Host "`n`nAttempting to read ConfigFile: $ConfigFile" -ForegroundColor Blue

		if (  -not( Test-Path -Path $ConfigFile -PathType Leaf)) { 
		
			Write-Host "ERROR: The parameter -ConfigFile: $ConfigFile does not exist" -ForegroundColor Red
			PrintInstructions
			Exit 0	
		}
	} else {
		Write-Host "`n`nAttempting to read ConfigFile: config.json" -ForegroundColor Blue
		if (-not(Test-Path -Path 'config.json' -PathType Leaf)) {
		   
		   Write-Host "ERROR: The config.json does not exist" -ForegroundColor Red
		   PrintInstructions
		   Exit 0
	   
	    }
	}
	
	$global:jsonConfig = Get-Content -Path 'config.json' | ConvertFrom-Json
    Write-Host " - Contents of config.json`n" -ForegroundColor Yellow
    $global:jsonConfig  | ConvertTo-Json 
}

function BackupOldCerts() {
   Write-Host "`n`nCreating Backup of old certs" -ForegroundColor Blue
   
   $filenameFormat = "cert_backup-$(((get-date).ToUniversalTime()).ToString("yyyyMMddTHHmmssZ")).zip"
   if (-not $global:testRun) {  
   		Compress-Archive -Path $($global:jsonConfig.CERTS.OutputPath) -DestinationPath "$($global:jsonConfig.CERTS.BackupPath)\$($filenameFormat)"
   }  
   Write-Host " - Storing Backup in : $($global:jsonConfig.CERTS.BackupPath)\$($filenameFormat)"
   Write-Host " - Waiting 3 seconds" 
   Start-Sleep -Seconds 3
}

function CreateRabbitPemCert() {
	Write-Host "`n`nCreating Rabbit Pem Certificate" -ForegroundColor Blue
    # Generate - Rabbit Pem Certificate
    $ParamList = "--source manual --host $($global:jsonConfig.CERTS.domain) --validation selfhosting --validationport 80 --store pemfiles --pemfilespath $($global:jsonConfig.CERTS.OutputPath) --pempassword $($global:jsonConfig.CERTS.Password) --pemfilesname rabbitmq"
	$cmd  = "$($global:jsonConfig.CERTS.PathToExe)\wacs.exe $($ParamList)"
	Write-Output " - Command: $cmd"
	Write-Output "global:testRun: $global:testRun"
	if (-not $global:testRun) { 
	 	Write-Host " - Creating" 
		Invoke-Expression -Command "$cmd"
	}
	Write-Host " - Waiting 3 seconds" 
	Start-Sleep -Seconds 3
}

function CreateAMSPfxCert() {
	Write-Host "`n`nCreating AMS Pfx Cert" -ForegroundColor Blue
	# Generate - AMS PFX Certificate
	$ParamList = "--source manual --host $($global:jsonConfig.CERTS.domain) --validation selfhosting --validationport 80 --store pfxfile --pfxfilepath $($global:jsonConfig.CERTS.OutputPath) --pfxpassword $($global:jsonConfig.CERTS.Password) --pfxfilename cert"
	$cmd  = "$($global:jsonConfig.CERTS.PathToExe)\wacs.exe $($ParamList)"
	Write-Output " - Command: $cmd"
	if (-not $global:testRun) { 
		Invoke-Expression -Command "$cmd"
    }
    Write-Host " - Waiting 3 seconds" 
    Start-Sleep -Seconds 3
}

function CopyCertsToAMS() {
	Write-Host "`n`nCopying Certs To AMS" -ForegroundColor Blue
	Write-output " - Copying pfx to RestAPI folder: $($global:jsonConfig.AMS.PathToRestAPI)"
    if (-not $global:testRun) {   
	    Copy-Item -Path "$($global:jsonConfig.CERTS.OutputPath)\cert.pfx"  -Destination "$($global:jsonConfig.AMS.PathToRestAPI)\"
	}
	Write-output " - Copying pfx to SoapAPI folder: $($global:jsonConfig.AMS.PathToSoapAPI)"
	if (-not $global:testRun) {   
	    Copy-Item -Path "$($global:jsonConfig.CERTS.OutputPath)\cert.pfx"  -Destination "$($global:jsonConfig.AMS.PathToSoapAPI)\"
	} 
	Write-Host " - Waiting 3 seconds" 
	Start-Sleep -Seconds 3
}

function RestartAMSComponents() {
	Write-Host "`n`Restarting AMS Components" -ForegroundColor Blue
	Write-output " - Restarting Rest API: $($global:jsonConfig.AMS.RestAPIServiceName)"
    if (-not $global:testRun) {   
	  Restart-Service "$($global:jsonConfig.AMS.RestAPIServiceName)" -PassThru
	}
	Write-output " - Restarting Soap API: $($global:jsonConfig.AMS.SoapAPIServiceName)"
	if (-not $global:testRun) {  
	  Restart-Service "$($global:jsonConfig.AMS.SoapAPIServiceName)" -PassThru
	}

	#Write-output "Restarting Flight Processing Service"
	#Restart-Service "$($global:jsonConfig.AMS.AMSFlightProcessingServiceName)" -PassThru
	#Write-output "Restarting AMS Server Service"
	#Restart-Service "$($global:jsonConfig.AMS.AMSServerServiceName)" -PassThru
	#Write-output "Restarting AMS DW Service"
	#Restart-Service "$($global:jsonConfig.AMS.AMSDWServiceName)" -PassThru		
	Write-Host " - Waiting 3 seconds" 
	Start-Sleep -Seconds 3
}

function RestartRabbitComponents() {
	Write-Host "`n`nRestarting RabbitMQ" -ForegroundColor Blue
	if ($global:testRun -Eq $false) {  
      Restart-Service "$($global:jsonConfig.AMS.RabbitMQServiceName)" -PassThru
	}
	Write-Host " - Waiting 3 seconds" 
	Start-Sleep -Seconds 3
}

if (-not $global:testRun) {
Write-Host "testRun: $global:testRun"
}

ReadConfig
BackupOldCerts
CreateRabbitPemCert
CreateAMSPfxCert
CopyCertsToAMS
RestartRabbitComponents
RestartAMSComponents








