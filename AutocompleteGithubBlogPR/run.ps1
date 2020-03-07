param($Timer)

Function Get-GitHubPR($ghToken) {
    $response = Invoke-WebRequest -Uri https://api.github.com/repos/michalchecinski/blog/pulls -Headers @{ 'Authorization' = "Bearer $ghToken" }
    return ($response.Content | ConvertFrom-Json)
}

Function Complete-GitHubPR($ghToken, $prNumber) {
    Write-Host "https://api.github.com/repos/michalchecinski/blog/pulls/$prNumber/merge"
    $response = Invoke-WebRequest -Method PUT -Uri "https://api.github.com/repos/michalchecinski/blog/pulls/$prNumber/merge" `
        -Headers @{ 'Authorization' = "Bearer $ghToken" }
        -Body @{ 'merge_method' = 'rebase' }
    return ($response.Content | ConvertFrom-Json)
}

Write-Host "Checking GitHub Token..."

$githubToken = $env:GithubPAT

if (!$githubToken -or $githubToken -eq "") {
    $githubToken = $env:GITHUB_TOKEN
}
if (!$githubToken -or $githubToken -eq "") {
    Write-Error "Github token is null."
    return
}

Write-Host "Getting all PRs..."

$prs = Get-GitHubPR($githubToken)

foreach ($pr in $prs) {
    $splitted = $pr.body.Split('@')
    if ($splitted.Length -eq 2 -and $splitted[0].ToLowerInvariant() -eq 'autocomplete') {
        try {
            $datetime = [datetime]::parseexact($splitted[1], 'yyyy-MM-ddTHH:mm', $null)
        }
        catch {
            Write-Host $_
        }

        $now = Get-Date
        if ($now -ge $datetime) {
            $prNumber = $pr.number
            Write-Host "Completing PR "$prNumber
            $completeMessage = Complete-GitHubPR $githubToken $prNumber
            Write-Host $completeMessage
        }
    }
}

Write-Host "DONE"
