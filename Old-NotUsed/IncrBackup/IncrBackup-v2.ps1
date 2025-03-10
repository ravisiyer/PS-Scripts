# Does incremental backup of a source folder to a destination folder
# It uses robocopy command to do the main work.
# Usage: script-name Source-Folder-Name Destination-Folder-Name
# The script also strips trailing backslash from Source-Folder-Name and Destination-Folder-Name if present before generating but
# I am not sure if that is needed (it was there in CopyWoNmnxbld.ps1 which has been used as the base to create this script).
# 
param ($InputFolder="", $OutputFolder="", $Option="")
$WoExclOption = "wo-nmnxbld"
$ExclFolders = "/XD node_modules .next build .gradle"
function Usage {
  param ($cmdName)
  Write-Host Usage: $cmdName Source-Folder-Name Destination-Folder-Name [$WoExclOption]
}

if ( "" -eq $InputFolder  ) {
    write-host "Input folder not specified."
    Usage $myInvocation.InvocationName
    exit 1
  }

$InputFolder = $InputFolder.trim()

$len = $InputFolder.length
if ("\" -eq $InputFolder.substring($len-1,1)) {
  $InputFolder = $InputFolder.substring(0, $len-1)
  Write-Host "Input parameter (folder name) had trailing backslash which was stripped" 
}

if ( "" -eq $OutputFolder  ) {
    write-host "Output folder not specified."
    Usage $myInvocation.InvocationName
    exit 1
  }

$OutputFolder = $OutputFolder.trim()

$len = $OutputFolder.length
if ("\" -eq $OutputFolder.substring($len-1,1)) {
  $OutputFolder = $OutputFolder.substring(0, $len-1)
  Write-Host "Output parameter (folder name) had trailing backslash which was stripped" 
}

If ( -not (Test-Path -path $InputFolder -PathType Container)) {
  If (Test-Path -path $InputFolder) {
    Write-Host "Parameter specified: '$InputFolder' is not a directory. Aborting!"
  } Else {
    Write-Host "Parameter specified: '$InputFolder' does not exist. Aborting!"
  }
  Usage $myInvocation.InvocationName
  exit 1
}

Write-Host "Command (list only and not actual incremental backup) to be executed (for readability of below output, single quotes ..." 
Write-Host " are added around folder names but these added single quotes are not passed to robocopy command):", `n
Write-Host "robocopy '$InputFolder' '$OutputFolder' /E /XO /L "
if ( $Option -eq $WoExclOption  ) {
	Write-Host $ExclFolders
}
# Write-Host `n
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed?", $Choices, 1)

if (1 -eq $Choice)
{
    Write-Host "Aborted!"
    exit 1
}

if ( $Option -eq $WoExclOption  ) {
	robocopy $InputFolder $OutputFolder /E /XO /L /XD node_modules .next build .gradle
} Else {
	robocopy $InputFolder $OutputFolder /E /XO /L
}

Write-Host "Actual incremental backup command to be executed", `n
Write-Host "robocopy '$InputFolder' '$OutputFolder' /E /XO "
if ( $Option -eq $WoExclOption  ) {
	Write-Host $ExclFolders
}
# Write-Host `n
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed with actual incremental backup command?", $Choices, 1)

if (1 -eq $Choice)
{
    Write-Host "Aborted!"
    exit 1
}

if ( $Option -eq $WoExclOption  ) {
	robocopy $InputFolder $OutputFolder /E /XO /XD node_modules .next build .gradle
} Else {
	robocopy $InputFolder $OutputFolder /E /XO
}

