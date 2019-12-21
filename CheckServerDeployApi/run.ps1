# Input bindings are passed in via param block.
param($Timer)

function SendSlackMessage {
    param (
        [string]$message
    )

    $SlackChannelUri = $env:SlackWebhookUri

    $BodyTemplate = @"
        {
            "channel": "#server",
            "username": "Azure Functions",
            "text": "*Deploy API is down* \n $message \nTime: $(Get-Date).",
            "icon_emoji":":ghost:"
        }
"@

    Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $BodyTemplate -ContentType 'application/json'

}

$number = Get-Random -Maximum 1000

try {
    $response = Invoke-WebRequest -Uri "$env:ApiDeployUri/heartbeat/$number" -ErrorAction Stop

    $binary = [Convert]::ToString($number,2)

    $responseContent = $response.Content

    if ($responseContent -ne $binary) {
        $message = "Didn't get expected value as response. Send: $binary got $responseContent "
    }
    else {
        Write-Host "ApiDeploy is running!"
    }
}
catch {
    $message = $_.Exception
}

SendSlackMessage $message

Write-Host $message