param (
    [Parameter(Mandatory)]
    [String]$jsonFilePath,
    [Parameter(Mandatory)]
    [String]$csvFilePath
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

Export-CsvFromJson $jsonFilePath $csvFilePath