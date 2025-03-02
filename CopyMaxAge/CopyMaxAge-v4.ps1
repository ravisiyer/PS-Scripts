# Copies contents of a folder/directory based on maxage
# It uses robocopy command to do the main work.
# Usage: script-name Source-Folder-Name [MaxAge]
# Output folder name is generated by concatenating script defined suffix to 
# Source-Folder-Name. The script checks if file/folder of this generated name exists and if so
# gives a suitable error message and then aborts.
# The script also strips trailing backslash from Source-Folder-Name if present before generating 
# output folder name. Note that Powershell adds trailing backslash by default to folder names when
# tab is used to step through files and folders being specified in a command on console.
#
param ($InputFolder="", $MaxAge="1")
$OutputFolder = ""
$OutputSuffix ="-maxage"
function Usage {
  param ($cmdName)
  Write-Host Usage: $cmdName Source-Folder-Name [MaxAge]
  Write-Host Usage: If MaxAge is not specified, default value of 1 (day) is used
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

# Write-Host "Input parameter (folder name) is: '$InputFolder'" 
# Write-Host "Note that Powershell strips enclosing quote characters of parameters when passing them to script."

If ( -not (Test-Path -path $InputFolder -PathType Container)) {
  If (Test-Path -path $InputFolder) {
    Write-Host "Parameter specified: '$InputFolder' is not a directory. Aborting!"
  } Else {
    Write-Host "Parameter specified: '$InputFolder' does not exist. Aborting!"
  }
  Usage $myInvocation.InvocationName
  exit 1
}

$OutputFolder = $InputFolder + $OutputSuffix
If (Test-Path -path $OutputFolder) {
  Write-Host "Output folder/directory name with auto suffix: '$OutputFolder' already exists. Aborting!"
  exit 1
} 

Write-Host "Command (list only and not actual incremental backup) to be executed (for readability of below output, single ..." 
Write-Host "quotes are added around folder names but these added single quotes are not passed to robocopy command):", `n
Write-Host "robocopy '$InputFolder' '$OutputFolder' /S /MAXAGE:$MaxAge /NDL /L", `n
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed?", $Choices, 1)

if (1 -eq $Choice)
{
    Write-Host "Aborted!"
    exit 1
}

robocopy $InputFolder $OutputFolder /S /MAXAGE:$MaxAge /NDL /L

Write-Host "Actual copy (list option not used) command to be executed :", `n
Write-Host "robocopy '$InputFolder' '$OutputFolder' /S /MAXAGE:$MaxAge /NDL", `n
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed?", $Choices, 1)

if (1 -eq $Choice)
{
    Write-Host "Aborted!"
    exit 1
}

robocopy $InputFolder $OutputFolder /S /MAXAGE:$MaxAge /NDL
