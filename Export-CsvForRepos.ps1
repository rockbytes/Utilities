param (
    [Parameter(Mandatory)]
    [String]$repoRoot,
    [Parameter(Mandatory)]
    [String]$csvRoot
)

function Export-CsvFromJson {
    param (
        $jsonMessageFilePath,
        $csvFilePath
    )

    $messageJson = Get-Content $jsonMessageFilePath -Encoding "utf8" | Out-String | ConvertFrom-Json

    New-Item $csvFilePath -ItemType File -Force

    $counter = 0

    ForEach ($msg in $messageJson.PSObject.Properties) {
        $line = New-Object PSObject -Property @{ MessageKey = $msg.Name; MessageId = $msg.Value.id; OriginalMessage = $msg.Value.defaultMessage -replace "\n","\n"; NewMessage = "" }
        $line | Select-Object MessageKey, MessageId, OriginalMessage, NewMessage | Export-Csv -Encoding "utf8" -Path $csvFilePath -Append -NoTypeInformation

        $counter = $counter + 1
    }

    $logging = "$counter messages have been exported to file $csvFilePath"

    $numOfLines = (Get-Content $csvFilePath).Length - 1 # exclude the head
    if ($numOfLines -ne $counter) {
        $logging = $logging + "`nWARNING: the number of exported messages ($counter) does not match the number of message lines ($numOfLines) in the CSV file $csvFilePath"
    }

    Write-Output "$logging`n"
}

function Export-CsvForSingleRepo {
    param (
        $repoRootDirPath,
        $repoName,
        $csvDirPath
    )

    $repoPath = [IO.Path]::Combine($repoRootDirPath, $repoName)
    $memTransConfig = "translation.memsource.config.json"

    $configDirPath = [IO.Path]::Combine($repoPath, "config")
    if ($repoName -eq 'zeno-travel-header') {
        $configDirPath = [IO.Path]::Combine($repoPath, "src/ui/config")
    }

    $translateConfigPath = [IO.Path]::Combine($configDirPath, $memTransConfig)
    if (!(Test-Path $translateConfigPath))
    {
        #Write-Output "File Not Exist: $translateConfigPath`n"
        return
    }

    $configJson = Get-Content $translateConfigPath | Out-String | ConvertFrom-Json

    $jsonMessagePath = [IO.Path]::Combine($repoPath, $configJson.sourceMessagePath)
    $csvFilePath = [IO.Path]::Combine($csvDirPath, $repoName + ".csv")

    Export-CsvFromJson $jsonMessagePath $csvFilePath
}

function Export-CsvForRepos {
    param (
        [String]$repoRootDirPath,
        [String]$csvRootDirPath
    )

    $repoNames = Get-ChildItem -Path $repoRootDirPath -Directory -Name
    ForEach ($repo in $repoNames) {
        Export-CsvForSingleRepo $repoRootDirPath $repo $csvRootDirPath
    }
}


Export-CsvForRepos $repoRoot $csvRoot
