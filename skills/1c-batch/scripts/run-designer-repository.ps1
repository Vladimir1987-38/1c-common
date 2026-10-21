# Запуск конфигуратора 1С с подключением к хранилищу (неблокирующий).
# Использование: run-designer-repository.ps1
# Требует .1c-devbase.ps1 в текущем каталоге с заполнёнными ONEC_REPOSITORY_*.
. "$PSScriptRoot\_common.ps1"
. (Get-DevBasePath)

foreach ($Name in 'ONEC_PATH', 'ONEC_REPOSITORY_PATH', 'ONEC_REPOSITORY_USER') {
    if (-not (Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue)) {
        throw "Не заполнена настройка $Name."
    }
}

# ---> SPB/Bulatov.V 20.10.2026 PRJ-4051 (фрагмент ИЗМЕНЕН) выполнено полностью codex
# $arguments = @('DESIGNER') + (Get-IBArgs) + (Get-AuthArgs)
# $arguments += "/ConfigurationRepositoryF$ONEC_REPOSITORY_PATH"
# $arguments += "/ConfigurationRepositoryN$ONEC_REPOSITORY_USER"
# if ($null -ne $ONEC_REPOSITORY_PASSWORD) { $arguments += "/ConfigurationRepositoryP$ONEC_REPOSITORY_PASSWORD" }
$arguments = @('DESIGNER') + (Get-IBArgs) + (Get-AuthArgs) + (Get-RepositoryArgs)
# <--- SPB/Bulatov.V 20.10.2026 PRJ-4051

Write-Host 'Запуск конфигуратора с подключением к хранилищу...'
Start-Process -FilePath $ONEC_PATH -ArgumentList (ConvertTo-ArgString $arguments)
Write-Host 'Конфигуратор запущен с параметрами подключения к хранилищу.'
