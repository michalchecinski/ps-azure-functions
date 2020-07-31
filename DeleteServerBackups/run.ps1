# Input bindings are passed in via param block.
param($Timer)

$stKey = $env:LocalServerBackupStorageKey
$stContext = New-AzStorageContext -StorageAccountName "hasslocalserverbackup" -StorageAccountKey $stKey

$containers = Get-AzStorageContainer -Prefix "backup-" -Context $stContext

if ($containers.count -gt 5 ) {
    foreach ($container in $containers) {
        $containers = Get-AzStorageContainer -Prefix "backup-" -Context $stContext
        if ($containers.count -gt 5 ) {

            $dirName = $container.Name.Replace("backup-", "")

            # Variable for directory date
            [datetime]$dirDate = New-Object DateTime

            # Check that directory name could be parsed to DateTime
            if ([DateTime]::TryParseExact($dirName, "yyyy-MM-dd",
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$dirDate)) {
                if (([DateTime]::Today - $dirDate).TotalDays -gt 14) {
                    $containerName = $container.Name

                    Write-Host "Removing $containerName"
                    Remove-AzStorageContainer -Name $containerName -Context $stContext -Force
                }
            }
        }
    }
}

Write-Host "Ended"
