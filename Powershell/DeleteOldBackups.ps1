# Delete SQL Server .bak and .trn files in the specified folder, older than the specified date threshold
# Always keeps the three newest .bak files (and their corresponding .trn files) regardless of their date
#
# Use -depth to control whether subdirectories are processed, where -depth 0 means no subdirectories
# By default, previews the files that would be deleted
# Actually delete them using -delete
#
# Example syntax:
#
# DeleteOldBackups.ps1 -folder F:\Temp\BackupTests -daysToKeep 90 -depth 0
# DeleteOldBackups.ps1 -folder F:\Temp\BackupTests -daysToKeep 90 -depth 1
# DeleteOldBackups.ps1 -folder F:\Temp\BackupTests -daysToKeep 90 -depth 1 -delete
#
#
# Written by Matthew Monroe for the Department of Energy (PNNL, Richland, WA) in 2016
# E-mail: matthew.monroe@pnnl.gov or matt@alchemistmatt.com
# Website: http://panomics.pnnl.gov/ or http://omics.pnl.gov or http://www.sysbio.org/resources/staff/
#

param (
    [Parameter(Mandatory=$true)][string]$folder,
    [int]$daysToKeep = 90,
    [int]$depth = 0,
    [switch]$delete = $false
 )

# Function to find and delete .bak and .trn files in the specified folder
function Delete-BakFiles {
    param (
        [Parameter(Mandatory=$true)][string]$folder,
        [int]$daysToKeep = 90,
        [int]$depth = 0,
        [switch]$delete = $false
     )

    write-output "Examine $folder"

    $bakFiles = Get-ChildItem $folder -filter "*.bak" -File | Sort-Object LastWriteTime -Descending

    $item = 0
    $dateThresholdToKeep = (Get-Date).AddDays(-$daysToKeep)
    $oldestRetainedBackup = (Get-Date).AddDays(-$daysToKeep)

    foreach($x in $bakFiles)
    {

            $item = $item + 1

            if ($item -le 3) {
                # Always keep the three newest .bak files (and their corresponding .trn files)
                $oldestRetainedBackup = $x.LastWriteTime
                write-output "  Skip $x"
                continue
            }

            if ($x.LastWriteTime -lt $dateThresholdToKeep )
            {
                if ($delete) {
                    write-output "  Delete $x"
                }
                else {
                    write-output "  Preview delete $x"
                }
            } else {
                $oldestRetainedBackup = $x.LastWriteTime
                write-output  "  Keep $x"
            }
    }

    $transactionLogDeleteThreshold = $oldestRetainedBackup.AddMinutes(-10)

    $trnFiles = Get-ChildItem $folder -filter "*.trn" -File | Sort-Object LastWriteTime -Descending

    foreach($x in $trnFiles)
    {
        if ($x.LastWriteTime -lt $transactionLogDeleteThreshold )
            {
                if ($delete) {
                    write-output "  Delete $x"
                }
                else {
                    write-output "  Preview delete $x"
                }
            } else {
                write-output "  Keep $x"
            }
    }

    if ($depth -gt 0) {
        $newDepth = $depth-1

        # For each subdir:        
        foreach($subDir in Get-ChildItem $folder -Directory) {
            write-output "Process subdir $subDir"
            Delete-BakFiles -folder $subDir.FullName -depth $newDepth -daysToKeep $daysToKeep -delete:$delete
        }
    }

}

# Process the initial folder and optionally subdirectories
Delete-BakFiles -folder $folder -depth $depth -daysToKeep $daysToKeep -delete:$delete
