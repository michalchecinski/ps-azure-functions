# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$stKey =  $env:LocalServerBackupStorageKey
$stContext = New-AzStorageContext -StorageAccountName "hasslocalserverbackup" -StorageAccountKey $stKey

$containers = Get-AzStorageContainer -Prefix "backup-" -Context $stContext

Write-Host ($containers | select Name)

foreach ($container in $containers) {

    $dirName = $container.Name.Replace("backup-", "")

    # Variable for directory date
    [datetime]$dirDate = New-Object DateTime

    # Check that directory name could be parsed to DateTime
    if ([DateTime]::TryParseExact($dirName.Name, "yyyy-MM-dd",
                                  [System.Globalization.CultureInfo]::InvariantCulture,
                                  [System.Globalization.DateTimeStyles]::None,
                                  [ref]$dirDate))
    {
        if (([DateTime]::Today - $dirDate).TotalDays -ge 31)
        {
            Write-Host "Removing $container.Name"
            Remove-AzStorageContainer -Name $container.Name -StorageAccountKey $stKey -Force
        }
    }
}

Write-Host "Ended"
