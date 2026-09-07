param(
    [Parameter(Mandatory = $true)][string]$ObjectsFile,
    [Parameter(Mandatory = $true)][string]$Comment
)

$ErrorActionPreference = "Stop"
$ConfigPath = Join-Path (Get-Location).Path ".1c-devbase.ps1"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Не найден .1c-devbase.ps1. Используйте BAT-вариант или создайте PowerShell-настройку из шаблона."
}

. $ConfigPath

foreach ($Name in "ONEC_PATH", "ONEC_REPOSITORY_PATH", "ONEC_REPOSITORY_USER") {
    if (-not (Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue)) {
        throw "Не заполнена настройка $Name."
    }
}

$ObjectsFile = (Resolve-Path -LiteralPath $ObjectsFile -ErrorAction Stop).Path
if ((Get-Item -LiteralPath $ObjectsFile).Length -eq 0) {
    throw "Файл списка объектов пуст. Помещение без явного списка запрещено."
}
if ([string]::IsNullOrWhiteSpace($Comment)) {
    throw "Комментарий помещения обязателен."
}

$Arguments = @("DESIGNER")
if ($ONEC_SERVER) {
    $Arguments += "/S$ONEC_SERVER\$ONEC_BASE"
} elseif ($ONEC_FILEBASE_PATH) {
    $Arguments += "/F$ONEC_FILEBASE_PATH"
} else {
    throw "Не настроено подключение к информационной базе."
}

if ($ONEC_USER) { $Arguments += "/N$ONEC_USER" }
if ($null -ne $ONEC_PASSWORD) { $Arguments += "/P$ONEC_PASSWORD" }
$Arguments += "/ConfigurationRepositoryF$ONEC_REPOSITORY_PATH"
$Arguments += "/ConfigurationRepositoryN$ONEC_REPOSITORY_USER"
if ($null -ne $ONEC_REPOSITORY_PASSWORD) { $Arguments += "/ConfigurationRepositoryP$ONEC_REPOSITORY_PASSWORD" }
$Arguments += "/ConfigurationRepositoryCommit"
$Arguments += "-Objects"
$Arguments += $ObjectsFile
$Arguments += "-comment"
$Arguments += $Comment
$Arguments += "/DisableStartupDialogs"

& $ONEC_PATH @Arguments
if ($LASTEXITCODE -ne 0) {
    throw "Помещение объектов завершилось с кодом $LASTEXITCODE."
}
