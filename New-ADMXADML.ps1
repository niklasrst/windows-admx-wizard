<#
.SYNOPSIS
   Create ADMX and ADML files from a CSV file with registry keys.

.DESCRIPTION
   Use this script to create ADMX and ADML files from a CSV file with registry keys.
   Those can then be used to deploy registry keys via Intune as Intune has no native functionality to deploy registry keys and sometimes a PowerShell script is too much for a single regsitry key.

.PARAMETER -Name
   Define the name that your admx and adml files should have.

.PARAMETER -CSVPath
   Set the path to the add-keys.csv file.
   The CSV file should contain the following columns:
    path,type,name,value

.PARAMETER -Verbose
   Enable verbose output.

.EXAMPLE
   .\New-ADMXADML.ps1 -Name "MyPolicy" -CSVPath "C:\path\to\add-keys.csv"
   This will create a new ADMX and ADML file set with the name "MyPolicy" and the registry keys defined in the add-keys.csv file.
   The files will be created on the Desktop.

.LINK
   https://github.com/niklasrst/windows-admx-wizard

.AUTHOR
   Niklas Rast
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,HelpMessage='Define the name that your admx and adml files should have.')]
    [string]$Name,
    [Parameter(Mandatory=$true,HelpMessage='Paste the full-qualified path to the add-keys.csv file.')]
    [string]$CSVpath
)

# Imported ADMX in Intune only supports a subset of registry paths.
$CSPForbiddenPrefixes = @(
    'system',
    'software\microsoft',
    'software\policies\microsoft'
)

$CSPAllowedExceptions = @(
    'software\policies\microsoft\office',
    'software\microsoft\office',
    'software\microsoft\windows\currentversion\explorer',
    'software\microsoft\internet explorer',
    'software\policies\microsoft\shared tools\proofing tools',
    'software\policies\microsoft\imejp',
    'software\policies\microsoft\ime\shared',
    'software\policies\microsoft\shared tools\graphics filters',
    'software\policies\microsoft\windows\currentversion\explore',
    'software\policies\microsoft\softwareprotectionplatform',
    'software\policies\microsoft\officesoftwareprotectionplatform',
    'software\policies\microsoft\windows\windows search\preferences',
    'software\policies\microsoft\exchange',
    'software\microsoft\shared tools\proofing tools',
    'software\microsoft\shared tools\graphics filters',
    'software\microsoft\windows\windows search\preferences',
    'software\microsoft\exchange',
    'software\policies\microsoft\vba\security',
    'software\microsoft\onedrive',
    'software\microsoft\edge',
    'software\microsoft\edgeupdate\'
)

function Test-CspCompatiblePolicyKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PolicyKey
    )

    $normalized = $PolicyKey.TrimStart('\\').ToLowerInvariant()

    foreach ($forbiddenPrefix in $CSPForbiddenPrefixes) {
        if ($normalized.StartsWith($forbiddenPrefix)) {
            if ($forbiddenPrefix -eq 'system') {
                return $false
            }

            foreach ($allowedPrefix in $CSPAllowedExceptions) {
                if ($normalized.StartsWith($allowedPrefix)) {
                    return $true
                }
            }

            return $false
        }
    }

    return $true
}

# Check if add-keys.csv exists
if (Test-Path $CSVpath) {
    Write-Host "add-keys.csv file found" -ForegroundColor Green
} else {
    Write-Host "add-keys.csv file not found." -ForegroundColor Red
    Write-Host "Creating add-keys.csv file at User Desktop..." -ForegroundColor Green
    New-Item -Path $ENV:USERPROFILE\Desktop -Name "add-keys.csv" -ItemType File
    "path,type,name,value" | Out-File -FilePath "$ENV:USERPROFILE\Desktop\add-keys.csv"
    if (Test-Path "$ENV:USERPROFILE\Desktop\add-keys.csv") {
        Write-Host "Please add the registry keys to the add-keys.csv file and run the script again." -ForegroundColor Yellow
        break
    } else {
        Write-Host "Could not create add-keys.csv file." -ForegroundColor Red
    }
}

# Initialize admx and adml files
Write-Host "Creating GUIDs..." -ForegroundColor Green
$PolicyGUID = (New-Guid).Guid
$ParentCategoryGUID = (New-Guid).Guid
$Language = "en-US"
$OutFileLocation = "$PSScriptRoot"
$FileName = $Name.ToUpper()

# Create admx and adml files
Write-Host "Creating $FileName ADMX and $FileName ADML file set at $ENV:USERPROFILE\Desktop..." -ForegroundColor Green
New-Item -Path "$OutFileLocation" -ItemType File -Name "$($FileName).admx" -Force | Out-Null
New-Item -Path "$OutFileLocation" -ItemType File -Name "$($FileName).adml" -Force | Out-Null

# Add header to admx file
#Write-Host "Initializing $FileName ADMX file..." -ForegroundColor Green
@"
<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright (c) NIKLAS RAST. All rights reserved.  -->
<policyDefinitions xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" revision="1.0" schemaVersion="1.0" xmlns="http://schemas.microsoft.com/GroupPolicy/2006/07/PolicyDefinitions">
<policyNamespaces>
    <target prefix="$FileName" namespace="MSC.Policies.$PolicyGUID"/>
    <using prefix="windows" namespace="Microsoft.Policies.Windows"/>
</policyNamespaces>
<resources minRequiredRevision="1.0" fallbackCulture="$Language"/>
<categories>
    <category name="CAT_XML_2_ADMXL" displayName="`$(string.CAT_XML_2_ADMXL)" explainText="`$(string.CAT_XML_2_ADMXL_HELP)"/>
    <category name="CAT_$ParentCategoryGUID" displayName="`$(string.CAT_$($ParentCategoryGUID))" explainText="`$(string.CAT_$($ParentCategoryGUID)_HELP)">
        <parentCategory ref="CAT_XML_2_ADMXL"/>
    </category>
</categories>
<policies>
"@ | Out-File -FilePath "$OutFileLocation\$FileName.admx" -Append

# Add header to adml file
#Write-Host "Initializing $FileName ADML file..." -ForegroundColor Green
@"
<?xml version="1.0"?>
<!-- Copyright (c) NIKLAS RAST. All rights reserved.  -->
<policyDefinitionResources xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" revision="1.0" schemaVersion="1.0" xmlns="http://schemas.microsoft.com/GroupPolicy/2006/07/PolicyDefinitions">
<displayName>$FileName</displayName>
<description>Configurations for $FileName</description>
<resources>
    <stringTable>
        <string id="CAT_XML_2_ADMXL">$FileName</string>
        <string id="CAT_XML_2_ADMXL_HELP">Configuration section</string>
        <string id="CAT_$ParentCategoryGUID">$ParentCategoryGUID</string>
        <string id="CAT_$($ParentCategoryGUID)_HELP">Configurations for $ParentCategoryGUID</string>
"@ | Out-File -FilePath "$OutFileLocation\$($FileName).adml" -Append


# Write keys to admx and adml
$RegKeys = Import-Csv -Path "$CSVpath"
$SkippedPolicies = New-Object System.Collections.Generic.List[Object]
foreach ($RegKey in $RegKeys) {
    $type = $RegKey.type
    $name = $RegKey.name
    $value = $RegKey.value
    $keyguid = (New-Guid).Guid

    if ($type -ieq "DWORD" -and $value -notmatch '^[0-9]+$') {
        throw "Invalid DWORD value '$value' for '$name'. Use an unsigned integer in add-keys.csv."
    }

    $scope = ""
    $path = ""

    if ($RegKey.path.StartsWith("HKEY_LOCAL_MACHINE")) {
        $scope = "Machine"
        $path = $RegKey.path -replace("HKEY_LOCAL_MACHINE\\", "")
    } elseif ($RegKey.path.StartsWith("HKEY_CURRENT_USER")) {
        $scope = "User"    
        $path = $RegKey.path -replace("HKEY_CURRENT_USER\\", "")
    } else {
        $scope = "Both"    
    }

    if (-not (Test-CspCompatiblePolicyKey -PolicyKey $path)) {
        Write-Warning "Skipping '$name' because '$($RegKey.path)' is not compatible with Imported ADMX CSP restrictions."
        $SkippedPolicies.Add([PSCustomObject]@{
            Path  = $RegKey.path
            Type  = $type
            Name  = $name
            Value = $value
        }) | Out-Null
        continue
    }


    switch ($type) {
        String { 
            Write-Host "Adding $name ($type) with $keyguid to $FileName ADMX file..." -ForegroundColor Green
@"
    <!-- $name [$type] -->
    <policy name="POL_$keyguid" displayName="`$(string.POL_$keyguid)" explainText="`$(string.POL_$($keyguid)_HELP)" key="$path" class="$scope" presentation="`$(presentation.ADML_STRING)">
        <parentCategory ref="CAT_$ParentCategoryGUID"/>
        <supportedOn ref="windows:SUPPORTED_Windows_10_0" />
        <elements>
            <text id="ADML_STRING" valueName="$name"/>
        </elements>
    </policy>
"@  | Out-File -FilePath "$OutFileLocation\$FileName.admx" -Append
            Write-Host "Adding $name ($type) with $keyguid to $FileName ADML file..." -ForegroundColor Green
@"
        <string id="POL_$keyguid">$name</string>
        <string id="POL_$($keyguid)_HELP">Set the value for $name</string>
"@ | Out-File -FilePath "$OutFileLocation\$($FileName).adml" -Append
     }
        DWORD { 
            Write-Host "Adding $name ($type) with $keyguid to $FileName ADMX file..." -ForegroundColor Green
@"
    <!-- $name [$type] -->
    <policy name="POL_$($keyguid)" displayName="`$(string.POL_$($keyguid))" explainText="`$(string.POL_$($keyguid)_HELP)" key="$path" valueName="$name" class="$scope">
    <parentCategory ref="CAT_$ParentCategoryGUID"/>
        <supportedOn ref="windows:SUPPORTED_Windows_10_0" />
        <enabledValue>
            <decimal value="$value"/>
        </enabledValue>
        <disabledValue>
            <delete/>
        </disabledValue>
    </policy>
"@ | Out-File -FilePath "$OutFileLocation\$FileName.admx" -Append
            Write-Host "Adding $name ($type) with $keyguid to $FileName ADML file..." -ForegroundColor Green
@"
        <string id="POL_$keyguid">$name</string>
        <string id="POL_$($keyguid)_HELP">Set the value for $name</string>
"@ | Out-File -FilePath "$OutFileLocation\$($FileName).adml" -Append
    }
        BINARY { 
            Write-Host "Adding $name ($type) with $keyguid to $FileName ADMX file..." -ForegroundColor Green
@"
    <!-- $name [$type] -->
    <policy name="POL_$($keyguid)" displayName="`$(string.POL_$($keyguid))" explainText="`$(string.POL_$($keyguid)_HELP)" key="$path" class="$scope" presentation="`$(presentation.POL_$($keyguid))">
        <parentCategory ref="CAT_$ParentCategoryGUID"/>
        <supportedOn ref="windows:SUPPORTED_Windows_10_0" />
        <elements>
            <text id="HXT_$($keyguid)" valueName="$name"/>
        </elements>
    </policy>
"@ | Out-File -FilePath "$OutFileLocation\$FileName.admx" -Append
            Write-Host "Adding $name ($type) with $keyguid to $FileName ADML file..." -ForegroundColor Green

@"
        <string id="POL_$keyguid">$name</string>
        <string id="POL_$($keyguid)_HELP">Set the value for $name</string>
"@ | Out-File -FilePath "$OutFileLocation\$($FileName).adml" -Append
    }
}

}

# Close admx and adml files
Write-Host "Closing $FileName ADMX file..." -ForegroundColor Green
@"       
</policies>
</policyDefinitions>
"@ | Out-File -FilePath "$OutFileLocation\$FileName.admx" -Append

Write-Host "Closing $FileName ADML file..." -ForegroundColor Green
@"
    </stringTable>
    <presentationTable>
        <presentation id="ADML_STRING">
            <textBox refId="ADML_STRING">
                <label>Value of the parameter</label>
            </textBox>
        </presentation>
        <presentation id="POL_$($keyguid)">
            <textBox refId="HXT_$($keyguid)">
                <label>Value of the parameter</label>
            </textBox>
        </presentation>
    </presentationTable>
</resources>
</policyDefinitionResources>
"@ | Out-File -FilePath "$OutFileLocation\$($FileName).adml" -Append

if ($SkippedPolicies.Count -gt 0) {
    Write-Host "Skipped $($SkippedPolicies.Count) key(s) due to Imported ADMX CSP restrictions:" -ForegroundColor Yellow
    $SkippedPolicies | ForEach-Object {
        Write-Host " - [$($_.Type)] $($_.Name) -> $($_.Path)"
    }
}