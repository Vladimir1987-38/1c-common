@echo off
setlocal

if not exist ".1c-devbase.bat" (
    echo Missing .1c-devbase.bat. Run from the project root.
    exit /b 1
)

call ".1c-devbase.bat"
if not defined ONEC_PATH exit /b 1
if not defined ONEC_REPOSITORY_PATH exit /b 1
if not defined ONEC_REPOSITORY_USER exit /b 1

if defined ONEC_SERVER (
    start "" "%ONEC_PATH%" DESIGNER /S"%ONEC_SERVER%\%ONEC_BASE%" /N"%ONEC_USER%" /P"%ONEC_PASSWORD%" /ConfigurationRepositoryF"%ONEC_REPOSITORY_PATH%" /ConfigurationRepositoryN"%ONEC_REPOSITORY_USER%" /ConfigurationRepositoryP"%ONEC_REPOSITORY_PASSWORD%"
) else (
    if not defined ONEC_FILEBASE_PATH exit /b 1
    start "" "%ONEC_PATH%" DESIGNER /F"%ONEC_FILEBASE_PATH%" /N"%ONEC_USER%" /P"%ONEC_PASSWORD%" /ConfigurationRepositoryF"%ONEC_REPOSITORY_PATH%" /ConfigurationRepositoryN"%ONEC_REPOSITORY_USER%" /ConfigurationRepositoryP"%ONEC_REPOSITORY_PASSWORD%"
)

echo Designer started with repository connection parameters.
exit /b 0
