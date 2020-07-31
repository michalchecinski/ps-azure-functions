# Input bindings are passed in via param block.
param($Timer)

function SendSlackMessage {
    param (
        [string]$message
    )

    $SlackChannelUri = $env:SlackWebhookUri

    $BodyTemplate = @"
        {
            "text": "*Removed backups:* \n $message \nTime: $(Get-Date).",
        }
"@

    Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $BodyTemplate -ContentType 'application/json'

}

$stKey = $env:LocalServerBackupStorageKey
$stContext = New-AzStorageContext -StorageAccountName "hasslocalserverbackup" -StorageAccountKey $stKey

$containers = Get-AzStorageContainer -Prefix "backup-" -Context $stContext

Write-Host ($containers | Select-Object Name)

if ($containers.count -gt 5 ) {
    $message = ''

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
                    $message = $message + "$containerName\n"

                    Write-Host "Removing $containerName"
                    Remove-AzStorageContainer -Name $containerName -Context $stContext -Force
                }
            }
        }
    }

    if ($message) {
        SendSlackMessage $message
    }
}

Write-Host "Ended"
