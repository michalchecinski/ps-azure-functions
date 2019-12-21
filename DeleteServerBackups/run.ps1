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

$stKey =  $env:LocalServerBackupStorageKey
$stContext = New-AzStorageContext -StorageAccountName "hasslocalserverbackup" -StorageAccountKey $stKey

$containers = Get-AzStorageContainer -Prefix "backup-" -Context $stContext

Write-Host ($containers | Select-Object Name)

$message = ""

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
            $containerName = $container.Name
            $message = $message + "$containerName\n"

            Write-Host "Removing $containerName"
            Remove-AzStorageContainer -Name $containerName -StorageAccountKey $stKey -Force
        }
    }
}

SendSlackMessage $message

Write-Host "Ended"
