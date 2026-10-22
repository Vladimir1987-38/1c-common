# ---> SPB/Bulatov.V 16.10.2026 PRJ-4263 (фрагмент ДОБАВЛЕН) выполнено полностью codex
<#
.SYNOPSIS
Creates the project's Vanessa folders and client binding without launching 1C.
.PARAMETER ProjectRoot
Existing project directory.
.PARAMETER ProfileName
Client profile name for a new binding; defaults to the project folder name.
An existing binding is preserved. A conflicting explicit name causes an error.
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$ProjectRoot,

	[ValidateNotNullOrEmpty()]
	[string]$ProfileName
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Get-Item -LiteralPath $ProjectRoot
if (-not $projectDirectory.PSIsContainer) {
	throw 'ProjectRoot must be an existing directory.'
}

# ---> SPB/Bulatov.V 22.10.2026 PRJ-4051 (фрагмент ИЗМЕНЕН) выполнено полностью codex
# $vanessaDirectory = Join-Path $projectDirectory.FullName 'Vanessa'
$legacyVanessaDirectory = Join-Path $projectDirectory.FullName 'Vanessa'
if (Test-Path -LiteralPath $legacyVanessaDirectory) {
	throw 'Legacy Vanessa directory exists. Merge it into tests/vanessa and update links before initializing; no files were changed.'
}
$vanessaDirectory = Join-Path $projectDirectory.FullName 'tests/vanessa'
$readmeTemplate = Join-Path $PSScriptRoot '../../../инструкции разработчику/шаблоны/tests-README.md.template'
if (-not (Test-Path -LiteralPath $readmeTemplate -PathType Leaf)) {
	throw 'Shared tests README template is missing.'
}
# <--- SPB/Bulatov.V 22.10.2026 PRJ-4051
$bindingPath = Join-Path $vanessaDirectory 'project.json'
$createdBinding = -not (Test-Path -LiteralPath $bindingPath)
$encoding = New-Object System.Text.UTF8Encoding($false)

if ($createdBinding) {
	if (-not $PSBoundParameters.ContainsKey('ProfileName')) {
		$ProfileName = $projectDirectory.Name
	}
	if ([string]::IsNullOrWhiteSpace($ProfileName)) {
		throw 'ProfileName must not be blank.'
	}

	$binding = [ordered]@{
		schemaVersion = 1
		projectName = $projectDirectory.Name
		scenariosPath = 'Scenarios'
		testClient = [ordered]@{
			profileName = $ProfileName
			status = 'pending'
			verifiedAt = $null
		}
	}
} else {
	$binding = [IO.File]::ReadAllText($bindingPath) | ConvertFrom-Json
	if ($binding.schemaVersion -ne 1 -or
		$binding.projectName -cne $projectDirectory.Name -or
		$binding.scenariosPath -cne 'Scenarios' -or
		$binding.testClient.profileName -isnot [string] -or
		[string]::IsNullOrWhiteSpace($binding.testClient.profileName) -or
		$binding.testClient.status -cnotin @('pending', 'verified')) {
		# ---> SPB/Bulatov.V 22.10.2026 PRJ-4051 (фрагмент ИЗМЕНЕН) выполнено полностью codex
		# throw 'Invalid Vanessa/project.json; review the project binding before initializing.'
		throw 'Invalid tests/vanessa/project.json; review the project binding before initializing.'
		# <--- SPB/Bulatov.V 22.10.2026 PRJ-4051
	}
	if ($binding.testClient.status -ceq 'verified') {
		$verifiedDate = [datetime]::MinValue
		if (-not [datetime]::TryParseExact(
			[string]$binding.testClient.verifiedAt, 'yyyy-MM-dd',
			[Globalization.CultureInfo]::InvariantCulture,
			[Globalization.DateTimeStyles]::None, [ref]$verifiedDate)) {
			throw 'A verified client requires verifiedAt in yyyy-MM-dd format.'
		}
	} elseif ($null -ne $binding.testClient.verifiedAt) {
		throw 'A pending client must have verifiedAt set to null.'
	}
	if ($PSBoundParameters.ContainsKey('ProfileName') -and
		$ProfileName -cne $binding.testClient.profileName) {
		throw 'ProfileName differs from the existing binding; update project.json explicitly.'
	}
}

[IO.Directory]::CreateDirectory($vanessaDirectory) | Out-Null
$scenariosDirectory = Join-Path $vanessaDirectory 'Scenarios'
[IO.Directory]::CreateDirectory($scenariosDirectory) | Out-Null
if ($createdBinding) {
	[IO.File]::WriteAllText($bindingPath, (($binding | ConvertTo-Json -Depth 5) + [Environment]::NewLine), $encoding)
}
$keepPath = Join-Path $scenariosDirectory '.gitkeep'
if (-not (Test-Path -LiteralPath $keepPath)) {
	[IO.File]::WriteAllText($keepPath, '', $encoding)
}

# ---> SPB/Bulatov.V 22.10.2026 PRJ-4051 (фрагмент ДОБАВЛЕН) выполнено полностью codex
$testsReadme = Join-Path $projectDirectory.FullName 'tests/README.md'
if (-not (Test-Path -LiteralPath $testsReadme)) {
	Copy-Item -LiteralPath $readmeTemplate -Destination $testsReadme
}
# <--- SPB/Bulatov.V 22.10.2026 PRJ-4051

[PSCustomObject]@{
	Project = $projectDirectory.Name
	ProfileName = $binding.testClient.profileName
	Status = $binding.testClient.status
	CreatedBinding = $createdBinding
}
# <--- SPB/Bulatov.V 16.10.2026 PRJ-4263
