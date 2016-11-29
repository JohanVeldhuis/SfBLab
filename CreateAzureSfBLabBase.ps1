<#
 Deploy the Azure Skype for Business Lab Machines
 Note: Requires the most recent AzureRM commandlets.  If you haven't recently installed the latest, you'd better do it now.

 This automation builds:

 DC - Domain Controller (contoso.com domain)
 FE - Front End server
 EDGE - Edge Server
 WAC - WAC server

 All servers except EDGE are members of contoso.com


.SYNOPSIS 
   This script is used to create a basic Skype foe Business lab      
#> 

# Sign into Azure

Login-AzureRmAccount
Get-AzureRmSubscription | Select-AzureRmSubscription 

# Note:
# If you have more than one subscription, you may need to comment out the "Get-AzureRmSubscription"
# Line Above and uncomment this one below to choose the subscription you want to use, rather 
# than some last-used default.
#Get-AzureRmSubscription -SubscriptionName "Your Subscription Name" | Select-AzureRmSubscription 



# collect initials for generating unique names

$init = Read-Host -Prompt "Please type your initials in lower case, and then press ENTER."


# Prompt for the Azure region in which to build the lab machines

Write-Host ""
Write-Host "Where in the world do you want to put these lab VMs?"
Write-Host "Carefully enter 'East US' or 'West US'"
$loc = Read-Host -Prompt "and then press ENTER."


# Variables 

$rgName = "RG-SfBLAB" + $init
# $deploymentName = $init + "SfBLab"  # Not required

# Use these if you want to drive the deployment from local template and parameter files..
#
# $localAssets = "D:\GitHub\AZInfraLabBase\"
# $templateFileLoc = $localAssets + "azuredeploy.json"
# $parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

# $assetLocation = "https://rawgit.com/KevinRemde/AZInfraLabBase/master/"  Wanted to use this, but sometimes it fails.
$assetLocation = "https://raw.githubusercontent.com/JohanVeldhuis/SfBLab/master/"
# If the rawgit.com path is not available, you can try un-commenting the following line instead...
# $assetLocation = "https://raw.githubusercontent.com/JohanVeldhuis/SfBLab/master/"
$templateFileURI  = $assetLocation + "azuredeploy.json"
$parameterFileURI = $assetLocation + "azuredeploy.parameters.json"


# Use Test-AzureRmDnsAvailability to create and verify unique DNS names.	
#
# Based on the initials entered, find unique DNS names for the four virtual machines.
# NOTE: You may be wondering why I'm not also looking for unique storage account names.  
# Those names are created by the template using randomly generated complex names, based on 
# the resource group ID.

$machine = "dc"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$init" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
        $dcDNSVMName = $dnsPrefix
    }
} 
	
$machine = "fe"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$init" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
        $feDNSVMName = $dnsPrefix
    }
} 

$machine = "edge"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$init" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
        $edgeDNSVMName = $dnsPrefix
    }
} 

$machine = "wac"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$init" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
        $wacDNSVMName = $dnsPrefix
    }
} 

# Populate the parameter object with parameter values for the azuredeploy.json template to use.

$parameterObject = @{
    "location" = "$loc"
    "dcDNSVMName" = $dcDNSVMName 
    "dcVMSize" = "Standard_D1"
    "adminDNSVMName" = $adminDNSVMName 
    "adminVMSize" = "Standard_D1"
    "edgeDNSVMName" = $edgeDNSVMName 
    "edgeVMSize" = "Standard_D2"
    "syncDNSVMName" = $syncDNSVMName 
    "syncVMSize" = "Standard_D1"
    "domainName" = "contoso.com"
    "domainUserName" = "labAdmin"
    "domainPassword" = "Passw0rd!"
    "vmUserName" = "labAdmin"
    "vmPassword" = "Passw0rd!"
    "assetLocation" = $assetLocation
}



# Create the resource group

New-AzureRMResourceGroup -Name $rgname -Location $loc

# Build the lab machines. 
# Note: takes approx. 30 minutes to complete.

Write-Host ""
Write-Host "Deploying the VMs.  This will take 30-45 minutes to complete."
Write-Host "Started at" (Get-Date -format T)
Write-Host ""

# THIS IS THE MAIN ONE YOU'LL launch to pull the template file from the repository, and use the created parameter object.
Measure-Command -expression {New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateUri $templateFileURI -TemplateParameterObject $parameterObject}

# use only if you want to use a local copy of the template file.
# Measure-Command -expression {New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $templateFileLoc -TemplateParameterObject $parameterObject}

# use only if you want to use Kevin's default parameters (not recommended)
# New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateUri $templateFileURI -TemplateParameterUri $parameterFileURI

Write-Host ""
Write-Host "Completed at" (Get-Date -format T)


# MORE EXAMPLES of what you may want to run later...

# Shut down all lab VMs in the Resource Group when you're not using them.
# Get-AzureRmVM -ResourceGroupName $rgName | Stop-AzureRmVM -Force

# Restart them when you're continuing the lab.
# Get-AzureRmVM -ResourceGroupName $rgName | Start-AzureRmVM 


# Delete the entire resource group (and all of its VMs and other objects).
# Remove-AzureRmResourceGroup -Name $rgName -Force


