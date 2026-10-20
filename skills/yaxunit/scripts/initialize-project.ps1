# ---> SPB/Bulatov.V 19.10.2026 PRJ-4263 (фрагмент ДОБАВЛЕН) выполнено полностью codex
# Создаёт только файлы проекта; не запускает 1С и не подключается к базе.
param(
	[Parameter(Mandatory=$true)][string]$ProjectRoot
)
$ErrorActionPreference = 'Stop'
$commonRoot = (Get-Item -LiteralPath (Join-Path $PSScriptRoot '../../..')).FullName
$project = (Get-Item -LiteralPath $ProjectRoot).FullName
$expectedCommon = Join-Path (Split-Path -Parent $project) '1c-common'
if ($expectedCommon -ne $commonRoot -or $project -eq $commonRoot) {
	throw 'Project must be a sibling of 1c-common, not the library itself.'
}
$engineSource = Join-Path $commonRoot 'YAxUnit/engine/25.12/YAXUNIT'
$templateRoot = Join-Path $commonRoot 'YAxUnit/template'
$templateSource = Join-Path $templateRoot 'extensions/Tests'
$runtimeSource = Join-Path $templateRoot 'tests/yaxunit'
$engineTarget = Join-Path $project 'extensions/YAXUNIT'
$testsTarget = Join-Path $project 'tests/yaxunit'
$extensionTarget = Join-Path $project 'extensions/Tests'
$legacyTarget = Join-Path $testsTarget 'extension'
$encoding = New-Object System.Text.UTF8Encoding($false)

# Проверить весь комплект до создания файлов целевого проекта.
foreach ($source in @(
	(Join-Path $engineSource 'Configuration.xml'),
	(Join-Path $engineSource 'LICENSE'),
	(Join-Path $templateSource 'Configuration.xml'),
	(Join-Path $templateSource 'Languages/Русский.xml'),
	(Join-Path $runtimeSource 'test-config.example.json'),
	(Join-Path $runtimeSource 'README.md'),
	(Join-Path $runtimeSource '.gitignore')
)) {
	if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
		throw ('Shared YAxUnit package is incomplete: ' + $source + '. Restore the package using https://wiki.spb.teremok.ru/pages/viewpage.action?pageId=163548690 (1c-common/YAxUnit/README.md).')
	}
}
[xml]$engine = [IO.File]::ReadAllText((Join-Path $engineSource 'Configuration.xml'))
if ($engine.MetaDataObject.Configuration.Properties.Name -ne 'YAXUNIT' -or
	$engine.MetaDataObject.Configuration.Properties.Version -ne '25.12') {
	throw 'Expected shared YAXUNIT version 25.12.'
}
[xml]$template = [IO.File]::ReadAllText((Join-Path $templateSource 'Configuration.xml'))
if ($template.MetaDataObject.Configuration.Properties.Name -ne 'Tests' -or
	@($template.MetaDataObject.Configuration.ChildObjects.ChildNodes | Where-Object { $_.LocalName -ne 'Language' }).Count -gt 0 -or
	@(Get-ChildItem -LiteralPath $templateSource -Recurse -File -Filter '*.bsl').Count -gt 0) {
	throw 'Tests template must contain only language metadata and no test modules.'
}
$runConfig = [IO.File]::ReadAllText((Join-Path $runtimeSource 'test-config.example.json')) | ConvertFrom-Json

# Отказ до записи при неоднозначной структуре или конфликте файлов/каталогов.
if ((Test-Path -LiteralPath $legacyTarget) -and (Test-Path -LiteralPath $extensionTarget)) {
	throw 'Both tests/yaxunit/extension and extensions/Tests exist; resolve them without overwriting tests.'
}
foreach ($existing in @($testsTarget, $extensionTarget, $legacyTarget)) {
	if ((Test-Path -LiteralPath $existing) -and -not (Test-Path -LiteralPath $existing -PathType Container)) {
		throw ('Expected directory; existing item was not changed: ' + $existing)
	}
}
foreach ($existing in @($extensionTarget, $legacyTarget)) {
	if (Test-Path -LiteralPath $existing) {
		$configurationPath = Join-Path $existing 'Configuration.xml'
		if (-not (Test-Path -LiteralPath $configurationPath -PathType Leaf)) {
			throw ('Tests extension is incomplete; it was not overwritten: ' + $existing)
		}
		[xml]$existingConfiguration = [IO.File]::ReadAllText($configurationPath)
		if ($existingConfiguration.MetaDataObject.Configuration.Properties.Name -ne 'Tests') {
			throw ('Expected extension Tests: ' + $existing)
		}
	}
}
$engineState = 'preserved'
if (-not (Test-Path -LiteralPath $engineTarget)) {
	New-Item -ItemType Directory -Path (Split-Path -Parent $engineTarget) -Force | Out-Null
	Copy-Item -LiteralPath $engineSource -Destination $engineTarget -Recurse
	$engineState = 'created'
} elseif (-not (Test-Path -LiteralPath $engineTarget -PathType Container) -or
	-not (Test-Path -LiteralPath (Join-Path $engineTarget 'Configuration.xml') -PathType Leaf)) {
	throw 'Existing extensions/YAXUNIT is incomplete; it was not overwritten.'
}

$extensionState = 'preserved'
if (Test-Path -LiteralPath $legacyTarget) {
	$sourcePath = (Get-Item -LiteralPath $legacyTarget).FullName
	$destinationPath = [IO.Path]::GetFullPath($extensionTarget)
	foreach ($movePath in @($sourcePath, $destinationPath)) {
		if (-not $movePath.StartsWith($project + '\', [StringComparison]::OrdinalIgnoreCase)) {
			throw 'Tests move target is outside the project.'
		}
		$ancestor = $movePath
		while ($ancestor -ne $project) {
			if ((Test-Path -LiteralPath $ancestor) -and
				((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
				throw 'Tests move through a reparse point requires explicit review.'
			}
			$ancestor = Split-Path -Parent $ancestor
		}
	}
	New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
	Move-Item -LiteralPath $sourcePath -Destination $destinationPath
	$extensionState = 'moved'
} elseif (-not (Test-Path -LiteralPath $extensionTarget)) {
	New-Item -ItemType Directory -Path (Split-Path -Parent $extensionTarget) -Force | Out-Null
	Copy-Item -LiteralPath $templateSource -Destination $extensionTarget -Recurse
	$extensionState = 'created-empty'
}
$testsState = 'preserved'
if (-not (Test-Path -LiteralPath $testsTarget)) {
	New-Item -ItemType Directory -Path (Split-Path -Parent $testsTarget) -Force | Out-Null
	Copy-Item -LiteralPath $runtimeSource -Destination $testsTarget -Recurse
	$runConfig.workspacePath = $testsTarget
	[IO.File]::WriteAllText((Join-Path $testsTarget 'test-config.local.json'),
		($runConfig | ConvertTo-Json -Depth 8) + "`r`n", $encoding)
	$testsState = 'created'
} elseif (-not (Test-Path -LiteralPath $testsTarget -PathType Container)) {
	throw 'Existing tests/yaxunit is not a directory; it was not overwritten.'
}
[pscustomobject]@{
	Project = Split-Path -Leaf $project
	EngineFiles = $engineState
	TestFiles = $extensionState
	RunFiles = $testsState
	Database = 'not-accessed'
}
# <--- SPB/Bulatov.V 19.10.2026 PRJ-4263
