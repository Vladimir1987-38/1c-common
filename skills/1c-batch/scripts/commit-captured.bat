@echo off
setlocal

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage
if not exist ".1c-devbase.bat" exit /b 1

call ".1c-devbase.bat"
if not defined ONEC_PATH exit /b 1
if not defined ONEC_REPOSITORY_PATH exit /b 1
if not defined ONEC_REPOSITORY_USER exit /b 1

set "OBJECTS_FILE=%~f1"
set "COMMIT_COMMENT=%~2"
if not exist "%OBJECTS_FILE%" exit /b 1
for %%A in ("%OBJECTS_FILE%") do if %%~zA EQU 0 exit /b 1

if defined ONEC_SERVER (
    "%ONEC_PATH%" DESIGNER /S"%ONEC_SERVER%\%ONEC_BASE%" /N"%ONEC_USER%" /P"%ONEC_PASSWORD%" /ConfigurationRepositoryF"%ONEC_REPOSITORY_PATH%" /ConfigurationRepositoryN"%ONEC_REPOSITORY_USER%" /ConfigurationRepositoryP"%ONEC_REPOSITORY_PASSWORD%" /ConfigurationRepositoryCommit -Objects "%OBJECTS_FILE%" -comment "%COMMIT_COMMENT%" /DisableStartupDialogs
) else (
    if not defined ONEC_FILEBASE_PATH exit /b 1
    "%ONEC_PATH%" DESIGNER /F"%ONEC_FILEBASE_PATH%" /N"%ONEC_USER%" /P"%ONEC_PASSWORD%" /ConfigurationRepositoryF"%ONEC_REPOSITORY_PATH%" /ConfigurationRepositoryN"%ONEC_REPOSITORY_USER%" /ConfigurationRepositoryP"%ONEC_REPOSITORY_PASSWORD%" /ConfigurationRepositoryCommit -Objects "%OBJECTS_FILE%" -comment "%COMMIT_COMMENT%" /DisableStartupDialogs
)

exit /b %ERRORLEVEL%

:usage
echo Usage: commit-captured.bat ^<OBJECTS_FILE^> ^<COMMENT^>
exit /b 1
