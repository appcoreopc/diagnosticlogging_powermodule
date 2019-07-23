#########################################
# az monitor diagnostic-settings create -n "lalala" --resource "devkvpmtengine" -g "devrgpmtengine" --resource-type "Microsoft.KeyVault/vaults" --workspace "devlgspaceapp" --metrics '[{"category": "AllMetrics","enabled": true,"retentionPolicy": {"enabled": false, "days": 0 }}]'
#########################################
# Event hub scenarios 
#  Finally got this to work 
# az monitor diagnostic-settings create -n "lalala" --resource "/subscriptions/1049bcd7-a271-4ab4-a57d-c57b7afd8393/resourceGroups/devrgbachofilecreate/providers/Microsoft.EventHub/namespaces/devehnspmtbachofilecreate" -g "devrgpmtengine" --workspace "/subscriptions/1049bcd7-a271-4ab4-a57d-c57b7afd8393/resourcegroups/devrgpmtengine/providers/microsoft.operationalinsights/workspaces/devlgspaceapp" --metrics '[{"category": "AllMetrics","enabled": true,"retentionPolicy": {"enabled": false, "days": 0 }}]'

# Without resource 
# az monitor diagnostic-settings create -n "lalala" --resource "/subscriptions/1049bcd7-a271-4ab4-a57d-c57b7afd8393/resourceGroups/devrgbachofilecreate/providers/Microsoft.EventHub/namespaces/devehnspmtbachofilecreate" --workspace "/subscriptions/1049bcd7-a271-4ab4-a57d-c57b7afd8393/resourcegroups/devrgpmtengine/providers/microsoft.operationalinsights/workspaces/devlgspaceapp" --metrics '[{"category": "AllMetrics","enabled": true,"retentionPolicy": {"enabled": false, "days": 0 }}]'

# Got this to work with resource group - when using even hub, it is a must to provide FULL resource id to the vault 
# az monitor diagnostic-settings create -n "lalala" --resource "devehnspmtbachofilecreate" -g "devrgbachofilecreate" --resource-type "Microsoft.EventHub/namespaces" --workspace "/subscriptions/1049bcd7-a271-4ab4-a57d-c57b7afd8393/resourcegroups/devrgpmtengine/providers/microsoft.operationalinsights/workspaces/devlgspaceapp" --metrics '[{"category": "AllMetrics","enabled": true,"retentionPolicy": {"enabled": false, "days": 0 }}]'

# Included for clarity, What the workspace id looks like :-
# "/subscriptions/5fb9f7d2-1e23-42ca-9763-52081ba0d2ae/resourcegroups/sbrgpmtengine/providers/microsoft.operationalinsights/workspaces/devlgspaceapp"
# "/subscriptions/5fb9f7d2-1e23-42ca-9763-52081ba0d2ae/resourcegroups/sbrgpmtengine/providers/microsoft.operationalinsights/workspaces/sbloganalyticsworkspace"


#### Sample query 
# AzureDiagnostics | distinct _ResourceId
# AzureDiagnostics | where ResourceProvider == "MICROSOFT.KEYVAULT" | distinct OperationName
# AzureDiagnostics | where ResourceGroup  == "SBRGBACHOFILECREATE" 

# Login 
az login --service-principal -u $env:clientid -p $env:clientsecret --tenant $env:tenant_id
az account set --subscription $env:subscription

## Some variables definition ##
## Workspace definiton
$defaultLogWorkspace = "/subscriptions/$env:subscription/resourcegroups/$env:Environment$env:shared_resource_group_name/providers/microsoft.operationalinsights/workspaces/$env:Environment$env:LogWorkspaceName"

# Flags supported by KeyVaults diagnostic logging
$jmetricsVault = '[{\"category\": \"AllMetrics\",\"enabled\": true,\"retentionPolicy\": {\"enabled\": false, \"days\": 1 }}]'
$logEventVault = '[{\"category\": \"AuditEvent\",\"enabled\": true,\"retentionPolicy\": {\"enabled\": false, \"days\": 1 }}]'

# Flags supported by Event hub diagnostic logging
$logEventEventHub = '[{\"category\": \"ArchiveLogs\",\"enabled\": true,\"retentionPolicy\": {\"enabled\": false, \"days\": 1 }}, {\"category\": \"OperationalLogs\",\"enabled\": true,\"retentionPolicy\": {\"enabled\": false, \"days\": 1 }},{\"category\": \"AutoScaleLogs\",\"enabled\": true,\"retentionPolicy\": {\"enabled\": false, \"days\": 1 }}]'

function EnableDiagnosticForVault($diagnosticName, $resourceNameOrId, $resourceGroup, $resourceType) {
    EnableDiagnostic $diagnosticName $resourceNameOrId $resourceGroup $resourceType $jmetricsVault $logEventVault
}

function EnableDiagnosticForEventHub($diagnosticName, $resourceNameOrId, $resourceGroup, $resourceType) {
    EnableDiagnostic $diagnosticName $resourceNameOrId $resourceGroup $resourceType $jmetricsVault $logEventEventHub  
}
function EnableDiagnostic($diagnosticName, $resourceNameOrId, $resourceGroup, $resourceType, $metrics, $logs) {

    $diagnosticsExist = $false

    try { 
        $diaglogResult = az monitor diagnostic-settings list --resource $resourceNameOrId -g $resourceGroup --resource-type $resourceType 
        $jsonVal = $diaglogResult | ConvertFrom-Json
        
        if ($jsonVal.value.length -gt 0)
        {
            $diagnosticsExist = $true
        }
    }
    catch {
        Write-Host("Resource might not exists")
        $diagnosticsExist = $false
    }

    Write-Host("Diagnostic already exist : $diagnosticsExist")
    # create 

    if ($diagnosticsExist -eq $false) {

        Write-Host("Creating diagnostic setings for [$resourceNameOrId] [$resourceGroup] [$resourceType]")
        $result = az monitor diagnostic-settings create --name $diagnosticName --resource $resourceNameOrId -g $resourceGroup --resource-type $resourceType --workspace $defaultLogWorkspace --metrics $metrics --logs $logs
        Write-Host("Result value : $result")
    }
    else { 
        Write-Host("No change for $resourceNameOrId")       
    }
}

#### Keyvault diagnostic setup ####

EnableDiagnosticForVault "$($env:Environment)kvpmtengine-diagnosticlog" "$($env:Environment)kvpmtengine" "$($env:Environment)rgpmtengine" "Microsoft.KeyVault/vaults"
EnableDiagnosticForVault "$($env:Environment)kvpmtengineexternal-diagnosticlog" "$($env:Environment)kvpmtengineexternal" "$($env:Environment)rgpmtengine" "Microsoft.KeyVault/vaults"
EnableDiagnosticForVault "$($env:Environment)kvpmtengineshared-diagnosticlog" "$($env:Environment)kvpmtengineshared" "$($env:Environment)rgpmtengine" "Microsoft.KeyVault/vaults"

#### Event hub diagnostic setup ####

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtexceptions-diagnosticlog" "$($env:Environment)ehnspmtexceptions" "$($env:Environment)rgpmtengine" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtbachofilecreate-diagnosticlog" "$($env:Environment)ehnspmtbachofilecreate" "$($env:Environment)rgbachofilecreate" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtbatchapprovalidentification-diagnosticlog" "$($env:Environment)ehnspmtbatchapprovalidentification" "$($env:Environment)rgbatchapprovalidentification" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtbatchreconciliationcheck-diagnosticlog" "$($env:Environment)ehnspmtbatchreconciliationcheck" "$($env:Environment)rgbatchreconciliationcheck" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtbatchrelease-diagnosticlog" "$($env:Environment)ehnspmtbatchrelease" "$($env:Environment)rgbatchrelease" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtbusinesserrors-diagnosticlog" "$($env:Environment)ehnspmtbusinesserrors" "$($env:Environment)rgbusinesserrors" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtmt9batchtransformer-diagnosticlog" "$($env:Environment)ehnspmtmt9batchtransformer" "$($env:Environment)rgmt9batchtransformer" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtmt9debatcher-diagnosticlog" "$($env:Environment)ehnspmtmt9debatcher" "$($env:Environment)rgmt9debatcher" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtmt9filevalidator-diagnosticlog" "$($env:Environment)ehnspmtmt9filevalidator" "$($env:Environment)rgmt9filevalidator" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtmt9paymenttransformer-diagnosticlog" "$($env:Environment)ehnspmtmt9paymenttransformer" "$($env:Environment)rgmt9pmttransformer" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtpaymentstoreaggregate-diagnosticlog" "$($env:Environment)ehnspmtpaymentstoreaggregate" "$($env:Environment)rgpaymentaggregate" "Microsoft.EventHub/namespaces"

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtpaymentstorehistory-diagnosticlog" "$($env:Environment)ehnspmtpaymentstorehistory" "$($env:Environment)rgpaymenthistory" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtpaymentstorebatch-diagnosticlog" "$($env:Environment)ehnspmtpaymentstorebatch" "$($env:Environment)rgpaymentstore" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtpaymentstorecompensatingpayment-diagnosticlog" "$($env:Environment)ehnspmtpaymentstorecompensatingpayment" "$($env:Environment)rgpaymentstore" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmtpaymentstorepayment-diagnosticlog" "$($env:Environment)ehnspmtpaymentstorepayment" "$($env:Environment)rgpaymentstore" "Microsoft.EventHub/namespaces" 

EnableDiagnosticForEventHub "$($env:Environment)ehnspmttracking-diagnosticlog" "$($env:Environment)ehnspmttracking" "$($env:Environment)rgtracking" "Microsoft.EventHub/namespaces" 

## Prevent this script from throwing errors 

exit 0

az logout 