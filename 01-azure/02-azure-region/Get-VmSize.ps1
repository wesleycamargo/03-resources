# .\Get-VmSize.ps1 -location "swedencentral" -vmSize "Standard_DS1_v2"


<#
.SYNOPSIS
    Fetches and filters the available VM sizes in a specified Azure region.

.DESCRIPTION
    This script uses the Azure CLI to list the available VM sizes in a specified Azure region
    and filters the results based on the specified VM size. The comparison is case-insensitive.
    The output is formatted as a table showing the Name, NumberOfCores, MemoryInMb, and MaxDataDiskCount properties.

.PARAMETER location
    The Azure region to list the VM sizes from. The default value is "swedencentral".

.PARAMETER vmSize
    The name of the VM size to filter by. The comparison is case-insensitive. The default value is "Standard_DS1_v2".

.EXAMPLE
    .\Get-VmSize.ps1 -location "swedencentral" -vmSize "Standard_DS1_v2"
    This example fetches and displays the VM sizes in the "swedencentral" region, filtering for "Standard_DS1_v2" (case-insensitive).
#>



param (
    [string]$location = "swedencentral",
    [string]$vmSize = "Standard_DS1_v2"
)
# Fetch VM sizes from the specified location and filter by the specified VM size (case-insensitive)
if ([string]::IsNullOrEmpty($vmSize)) {
    $vmSizes = az vm list-sizes --location $location -o json | ConvertFrom-Json
} else {
    $vmSizes = az vm list-sizes --location $location -o json | ConvertFrom-Json | Where-Object { $_.Name.ToLower() -eq $vmSize.ToLower() }
}

# Display the filtered results in table format
$vmSizes | Format-Table -Property Name, NumberOfCores, MemoryInMb, MaxDataDiskCount
