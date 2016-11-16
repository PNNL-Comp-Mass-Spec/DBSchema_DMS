param(
	[string]$filePath = "TestLog.txt"
)

[environment]::commandline | Out-File $filePath
$version = $PSVersionTable.PSVersion
"Version: $version" | Out-File $filePath -Append
[string]$executionPolicy = Get-ExecutionPolicy
"Execution Policy: $executionPolicy" | Out-File $filePath -Append
