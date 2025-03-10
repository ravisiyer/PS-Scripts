# Copies contents of a folder/directory excluding specified/default folders (e.g. node_modules and .next folders).
# It uses robocopy command to do the main work.
# If Output folder name not specified, it is generated by concatenating script defined suffix to 
# Input-Folder-Name. The script checks if file/folder of this generated name exists and if so
# gives a suitable message about how /XO option of robcopy that will be used, will work.
# The script also strips trailing backslash from Input-Folder-Name if present.
# Note that Powershell adds trailing backslash by default to folder names when
# tab is used to step through files and folders being specified in a command on console.
#
param ($InputFolder="", $ExcludeFolders="", $MaxAge="", $OutputFolder="", $LogFile="")
$OutputSuffixDefault ="-XF"
$ExcludeFoldersDefault="node_modules .next intermediates .gradle target"
$ExcludeNoneFlag="ExcludeNone"

# If MaxAge is specified, /S is better option than /E as we don't want empty directories to be copied
# But if MaxAge is not specified and destination folder is not existing or empty (it is a full fresh copy), /e may be better.
$CopySubDirOption = "/E"
function Usage {
  param ($cmdName)
  Write-Host "Copy contents of a folder excluding specified/default folders (e.g. node_modules and .next folders)."`n
  Write-Host Usage: $cmdName Input-Folder-Name [Exclude-Folders-List MaxAge Output-Folder-Name LogFile]`n
  Write-Host Exclude-Folders-List is a space separated list like: `"node_modules .next intermediates .gradle`"
  Write-Host Special value of $ExcludeNoneFlag can be passed as Exclude-Folders-List to not use exclude option at all [include all in copy]
  Write-Host "MaxAge is a positive integral number"
  Write-Host "If Output folder name is not specified, it is generated by concatenating" $OutputSuffixDefault "to Input-Folder-Name."
  Write-Host "LogFile is a filename to which the robocopy log will be appended in addition to log being shown on output (terminal)"
  Write-Host "To skip optional parameters but specify a following parameter, use - (hyphen character) to skip"
}

$InputFolder = $InputFolder.trim()
if ( "" -eq $InputFolder  ) {
    write-host "Input folder not specified."
    Usage $myInvocation.InvocationName
    exit 1
  }

# Special flag to not specify Exclude Directories option at all  
if ( $ExcludeNoneFlag -eq $ExcludeFolders )  {
    $ExcludeFolders = "" 
} elseif (( "" -eq $ExcludeFolders  ) -or ("-" -eq $ExcludeFolders)) {
    $ExcludeFolders = $ExcludeFoldersDefault
}

if (( "" -eq $MaxAge  ) -or ("-" -eq $MaxAge)) {
    write-host "MaxAge is not specified"
    $MaxAge =""
  } else {
  write-host "Max age of $MaxAge is specified."
  $MaxAge ="/MAXAGE:$MaxAge"
  $CopySubDirOption = "/S" # We don't want empty subdirectories to be copied in this case.
}
  
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

if (( "" -eq $OutputFolder  ) -or ("-" -eq $OutputFolder)) {
  $OutputFolder = $InputFolder + $OutputSuffixDefault
}
write-host "OutputFolder is:" $OutputFolder

If (Test-Path -path $OutputFolder) {
  Write-Host "Note that Output folder/directory: '$OutputFolder' already exists. Newer/new files from source/input folder will be copied."
} 

$LogOption = ""
if (( "" -eq $LogFile  ) -or ("-" -eq $LogFile)) {
  Write-Host "Log file not specified."
  $LogFile = ""
} else {
  $LogOption = " /LOG+:" + $LogFile + " /tee "
  Write-Host "Log will be appended to file:" $LogFile
}

Write-Host "Command (list only and not actual copy) to be executed [for readability of below output, single quotes ..."
Write-Host " are added around folder names but these added single quotes are not passed to robocopy command]:", `n
if ("" -ne $LogOption) {
  Write-Host "Log file is excluded in list only command."
}

$Cmd ="robocopy '$InputFolder' '$OutputFolder' $CopySubDirOption /XO /XX /TS $MaxAge /NDL "
if ("" -ne $ExcludeFolders) {
  $Cmd = $Cmd + "/XD $ExcludeFolders "
}

$ListCmd = $Cmd + " /L"
# Write-Host "Switches are used to skip everything but timestamps and paths of files which will be copied if list switch is not used"
# $ListCmd = $Cmd + " /NS /NC /NJH /NJS /L"
Write-Host $ListCmd , `n
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed?", $Choices, 1)

if (1 -eq $Choice)
{
    Write-Host "Aborted!"
    exit 1
}

Invoke-Expression $ListCmd

$Cmd = $Cmd + $LogOption
Write-Host "Actual copy command to be executed", `n
Write-Host $Cmd, `n

$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&yes", "&no")
$Choice = $host.UI.PromptForChoice("", "Proceed?", $Choices, 1)

if (1 -eq $Choice)
{
    Write-Host "Aborted!"
    exit 1
}

Invoke-Expression $Cmd
