param()

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

Start-Process -FilePath $ONEC_PATH -ArgumentList $Arguments
Write-Host "Конфигуратор запущен с параметрами подключения к хранилищу."
