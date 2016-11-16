# Delete SQL Server .bak and .trn files in the specified folder, older than the specified date threshold
# Always keeps the three newest .bak files (and their corresponding .trn files) regardless of their date
#
# Use -depth to control whether subdirectories are processed, where -depth 0 means no subdirectories
# By default, previews the files that would be deleted
# Actually delete them using -delete

# Use -msgLevel # to change the console messaging level (0 for minimal, 1 for normal, 2 for detailed, 3 for verbose); default is 2
# Use -logLevel # to change the log file level; default is 1
#
# Example syntax:
#
# DeleteOldBackups.ps1 -folder \\MyServer\DBBackups\ -daysToKeep 90 -depth 0
# DeleteOldBackups.ps1 -folder \\MyServer\DBBackups\ -daysToKeep 90 -depth 1 -msgLevel 1
# DeleteOldBackups.ps1 -folder \\MyServer\DBBackups\ -daysToKeep 90 -depth 1 -delete
# DeleteOldBackups.ps1 -folder \\MyServer\DBBackups\ -daysToKeep 90 -depth 1 -delete -msgLevel 2 -logLevel 2 
#
#
# Written by Matthew Monroe for the Department of Energy (PNNL, Richland, WA) in 2016
#
# E-mail: matthew.monroe@pnnl.gov or matt@alchemistmatt.com
# Website: http://panomics.pnnl.gov/ or http://omics.pnl.gov or http://www.sysbio.org/resources/staff/
#

param (
    [Parameter(Mandatory=$true)][string]$folder,
    [int]$daysToKeep = 90,
    [int]$depth = 0,
    [switch]$delete = $false,
    [int]$msgLevel = 2,
    [int]$logLevel = 1
 )

function Log-File {
	param (
	    [Parameter(Mandatory=$true)][string]$message,
        [int]$msgLevel = 1,
        [switch]$noTimeStamp = $false
	 )

    if ($msgLevel -le $script:consoleMsgLevel) {
        Write-Output $message
    }

    if ($msgLevel -gt $script:logMsgLevel) {
        return;        
    }

	$timeStamp = Get-Date -format "yyyy-MM-dd hh:mm:ss tt"

    if ($noTimeStamp) {
        Add-Content -path $script:logFilePath -Value $message
    } else {
        Add-Content -path $script:logFilePath -Value "$timeStamp - $message"
    }
	
}

# Function to find and delete .bak and .trn files in the specified folder
function Delete-BakFiles {
    param (
        [Parameter(Mandatory=$true)][string]$folder,
        [int]$daysToKeep = 90,
        [int]$depth = 0,
        [switch]$delete = $false,
        [switch]$verboseLog = $false
     )

	Log-File -message "Examining $folder" -msgLevel 2

    $bakFiles = Get-ChildItem $folder -filter "*.bak" -File | Sort-Object LastWriteTime -Descending

	# Require $daysToKeep to be at least 7
	if ($daysToKeep -lt 7) {
		Log-File -message "Parameter -daysToKeep must be at least 7; auto-updating from $daysToKeep to 7"
		$daysToKeep = 7
	}

    $item = 0
    $dateThresholdToKeep = (Get-Date).AddDays(-$daysToKeep)
    $oldestRetainedBackup = (Get-Date).AddDays(-$daysToKeep)

    foreach($x in $bakFiles)
    {

            $item = $item + 1

            if ($item -le 3) {
                # Always keep the three newest .bak files (and their corresponding .trn files)
                $oldestRetainedBackup = $x.LastWriteTime
                Log-File -message "    Skip $x" -msgLevel 3
                continue
            }

            if ($x.LastWriteTime -lt $dateThresholdToKeep )
            {
                $fullName = $x.FullName
                if ($delete) {
                    Log-File -message "  Delete $fullName" -msgLevel 0
                    Remove-Item $x.FullName
                }
                else {
                    Log-File -message "  Preview delete $fullName" -msgLevel 1
                }
            } else {
                $oldestRetainedBackup = $x.LastWriteTime
                Log-File -message "    Keep $x" -msgLevel 3
            }
    }

    $transactionLogDeleteThreshold = $oldestRetainedBackup.AddMinutes(-10)
    if ($transactionLogDeleteThreshold -gt $dateThresholdToKeep) {
        $transactionLogDeleteThreshold = $dateThresholdToKeep
    }

    $trnFiles = Get-ChildItem $folder -filter "*.trn" -File | Sort-Object LastWriteTime -Descending

    foreach($x in $trnFiles)
    {        
        if ($x.LastWriteTime -lt $transactionLogDeleteThreshold )
            {
                $fullName = $x.FullName
                if ($delete) {
                    Log-File -message "  Delete $fullName" -msgLevel 0
                    Remove-Item $x.FullName
                }
                else {
                    Log-File -message "  Preview delete $fullName" -msgLevel 1
                }
            } else {
                Log-File -message "    Keep $x" -msgLevel 3
            }
    }

    if ($depth -gt 0) {
        $newDepth = $depth-1

        # For each subdir:        
        foreach($subDir in Get-ChildItem $folder -Directory) {
            Delete-BakFiles -folder $subDir.FullName -depth $newDepth -daysToKeep $daysToKeep -delete:$delete
        }
    }

}

# When running this Powershell script using a SQL Server Agent job, we need to use Set-Location in order to access files on a remote path via a UNC
# This bug is described at https://connect.microsoft.com/SQLServer/feedback/details/2865564/sqlps-exes-sqlserver-provider-causes-invalid-path-errors-with-filesystem-cmdlets

# If the script is local, use $PSScriptRoot
# If the script is remote, use C:\
Set-Location $PSScriptRoot

$script:logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "BackupDeletionLog.txt"
$script:consoleMsgLevel = $msgLevel
$script:logMsgLevel     = $logLevel

Write-Output "Logging to $script:logFilePath"

Log-File -message "Finding old backups in $folder" -msgLevel 1

# Process the initial folder and optionally subdirectories
Delete-BakFiles -folder $folder -depth $depth -daysToKeep $daysToKeep -delete:$delete
