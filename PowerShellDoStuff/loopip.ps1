$filePath = ".\iplist.txt"
$fileContent = Get-Content $filePath

foreach ($line in $fileContent) {
    $index = $line.IndexOf("/")

    if ($index -ge 0) {
        $result = $line.Substring(0, $index)
    } else {
        $result = $line
    }
    if (Test-IPInUS $result) {
        Write-Host $line
    }
}