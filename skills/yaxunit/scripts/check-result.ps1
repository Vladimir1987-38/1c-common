# ---> SPB/Bulatov.V 19.10.2026 PRJ-4263 (фрагмент ДОБАВЛЕН) выполнено полностью codex
# Reads local YAxUnit jUnit/result files; never starts 1C or modifies files.
[CmdletBinding()]
param(
	[Parameter(Mandatory=$true)][string]$ReportPath,
	[Parameter(Mandatory=$true)][string]$ResultPath,
	[Parameter(Mandatory=$true)][DateTimeOffset]$StartedAt,
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string[]]$ExpectedTests
)
$ErrorActionPreference = 'Stop'
if (@($ExpectedTests | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
	throw 'ExpectedTests must contain explicit non-empty test names.'
}
foreach ($path in @($ReportPath, $ResultPath)) {
	$item = Get-Item -LiteralPath $path -ErrorAction Stop
	if ($item.PSIsContainer -or $item.Length -eq 0) { throw "Missing or empty result file: $path" }
	if ($item.LastWriteTimeUtc -lt $StartedAt.UtcDateTime) { throw "Stale result file: $path" }
}
$resultText = [IO.File]::ReadAllText((Get-Item -LiteralPath $ResultPath).FullName).Trim()
if ($resultText -notmatch '\A[01]\z') { throw 'Invalid YAxUnit result code; expected 0 or 1.' }
$settings = New-Object System.Xml.XmlReaderSettings
$settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
$settings.XmlResolver = $null
$reader = [Xml.XmlReader]::Create((Get-Item -LiteralPath $ReportPath).FullName, $settings)
try {
	$report = New-Object System.Xml.XmlDocument
	$report.XmlResolver = $null
	$report.Load($reader)
} finally {
	$reader.Dispose()
}
if ($report.DocumentElement.LocalName -notin @('testsuite', 'testsuites')) {
	throw 'Unsupported jUnit root element.'
}
$cases = @($report.SelectNodes('//*[local-name()="testcase"]'))
if ($cases.Count -eq 0) { throw 'Zero tests executed; this is not a successful run.' }
$issues = New-Object 'System.Collections.Generic.List[string]'
if ($resultText -ne '0') { $issues.Add('YAxUnit result code is 1') }
$badNodes = @($report.SelectNodes('//*[local-name()="failure" or local-name()="error" or local-name()="skipped"]'))
if ($badNodes.Count -gt 0) { $issues.Add('Report contains failures, errors or skipped tests') }
foreach ($suite in $report.SelectNodes('//*[local-name()="testsuite" or local-name()="testsuites"]')) {
	foreach ($attribute in @('failures', 'errors', 'skipped', 'disabled')) {
		if ($suite.HasAttribute($attribute)) {
			$count = 0
			if (-not [int]::TryParse($suite.GetAttribute($attribute), [ref]$count) -or $count -lt 0) {
				throw "Invalid jUnit counter: $attribute"
			}
			if ($count -gt 0) { $issues.Add("Suite counter $attribute is nonzero") }
		}
	}
}
$names = @($cases | ForEach-Object { $_.GetAttribute('name') })
if (@($names | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
	throw 'A test case has no name.'
}
foreach ($name in $ExpectedTests) {
	if ($names -cnotcontains $name) { $issues.Add("Expected test did not execute: $name") }
}
foreach ($name in $names) {
	if ($ExpectedTests -cnotcontains $name) { $issues.Add("Unexpected test executed: $name") }
}
if ($issues.Count -gt 0) { throw ($issues -join '; ') }
[PSCustomObject]@{
	Status = 'Passed'
	Tests = $cases.Count
	Names = $names
	StartedAtUtc = $StartedAt.UtcDateTime.ToString('o')
	Report = (Get-Item -LiteralPath $ReportPath).FullName
}
# <--- SPB/Bulatov.V 19.10.2026 PRJ-4263
