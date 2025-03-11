#
param ($InputFolder="", $ExcludeFolders="", $OutputSuffix="", $BackupFolder="")
$BackupFolderDefault = "E:\TempBack"
$ExcludeNoneFlag="ExcludeNone"
$OutputSuffixExclNoneDefault ="-Copy"
$OutputSuffixExclFldrDefault ="-XF"

function Usage {
  param ($cmdName)
  Write-Host "CopyWoXF + ZipFldrWDtTm + Move OutputZipFile to BackupFolder + Move CopyWoXF OutputFolder to MayDeleteLater folder"`n
  Write-Host Usage: $cmdName Input-Folder-Name [Exclude-Folders-List Output-Suffix Backup-Folder]`n
  Write-Host Backup-Folder is the final copy location. By default it is: $BackupFolderDefault
  Write-Host Exclude-Folders-List is a space separated list like: `"node_modules .next intermediates .gradle`"
  Write-Host Special value of $ExcludeNoneFlag can be passed as Exclude-Folders-List to not use exclude option at all [include all in copy]
  Write-Host Exclude-Folders-List is passed as given to CopyWoXF.ps1
  Write-Host If Exclude-Folders-List is omitted`, default value of - is passed to CopyWoXF.ps1
  Write-Host "Output folder name is generated by concatenating current date and time as yyyyMMdd-HHmm- as prefix to Input-Folder-Name"
  Write-Host "  and using Output-Suffix if specified or $OutputSuffixExclNoneDefault or $OutputSuffixExclFldrDefault as suffix."
  Write-Host "To skip optional parameters but specify a following parameter, use - (hyphen character)"
  Write-Host /? passed as first parameter shows this help message.`n
}

if ($InputFolder -eq "/?") { 
  Usage $myInvocation.InvocationName
  exit 0
}

if ( "" -eq $InputFolder  ) {
  write-error "Input folder not specified."
  Usage $myInvocation.InvocationName
  exit 1
}

if ( "" -eq $ExcludeFolders  ) {
  $ExcludeFolders = "-"
}

if (( "" -eq $OutputSuffix  ) -or ("-" -eq $OutputSuffix)) {
  if ( $ExcludeNoneFlag -eq $ExcludeFolders ) {
    $OutputSuffix = $OutputSuffixExclNoneDefault  
  } else {
    $OutputSuffix = $OutputSuffixExclFldrDefault
  }
}

if (( "" -eq $BackupFolder  ) -or ("-" -eq $BackupFolder)) {
    $BackupFolder = $BackupFolderDefault
}
$InputFolderLeaf = Split-Path -Path $InputFolder -Leaf
$InputFolderParent = Split-Path -Path $InputFolder -Parent
$NowDateTime = Get-Date -Format "yyyyMMdd-HHmm-"
if ("" -eq $InputFolderParent) {
  $OutputFolder = $NowDateTime + $InputFolderLeaf + $OutputSuffix
} else {
  $OutputFolder = $InputFolderParent + "\" + $NowDateTime + $InputFolderLeaf + $OutputSuffix
}

# CopyWoXF Usage: $cmdName Input-Folder-Name [Exclude-Folders-List MaxAge Output-Folder-Name LogFile]`n
$Cmd = "CopyWoXF $InputFolder $ExcludeFolders - $OutputFolder"
Write-Host "Executing:"
Write-Host $Cmd

Invoke-Expression $Cmd
if ($LASTEXITCODE -ne 0) {
  Write-Error "Above CopyWoXF script failed with exit code: $LastExitCode."
  exit 1
}

$Cmd ="ZipFldrWDtTm $OutputFolder N"
Write-Host `n"Executing: $Cmd"
Invoke-Expression $Cmd
if ($LASTEXITCODE -ne 0) {
  Write-Error "Above ZipFldrWDtTm script failed with exit code: $LastExitCode."
  exit 1
}

$OutputZipFile = $OutputFolder + ".zip"
$MoveCmd = "Move-Item -Path $OutputZipFile -Destination $BackupFolder"
Write-Host `n"Move OutputZipFile command to be executed:"
Write-Host $MoveCmd

$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed (or skip)?", $Choices, 1)

if (1 -eq $Choice)
{
  Write-Host "Skipped!"
} else {
  try {
    Invoke-Expression $MoveCmd
  }
  catch {
    Write-Error "Above command threw exception: $($PSItem.ToString())"
    exit 1
  }
}

$Cmd ="MoveToMDLWDtTm $OutputFolder N"
Write-Host `n"Executing: $Cmd"

Invoke-Expression $Cmd
if ($LASTEXITCODE -ne 0) {
  Write-Error "Above MoveToMDLWDtTm script failed with exit code: $LastExitCode."
  exit 1
}
Write-Host
exit 0
