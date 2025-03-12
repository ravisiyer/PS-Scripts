param ($InputFolder="")
#  7z a Test.zip Test
$Cmd = "7z a $InputFolder.zip $InputFolder"
Write-Host "Command to be executed: $Cmd"
Invoke-Expression $Cmd
Write-Host "Above command finished execution with exit code: $LastExitCode." `n

