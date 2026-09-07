param([Parameter(Mandatory=$true)][string]$ProjectRoot)
$ErrorActionPreference = 'Stop'
$commonRoot = Split-Path -Parent $PSScriptRoot
$project = (Get-Item -LiteralPath $ProjectRoot).FullName
$expectedCommon = Join-Path (Split-Path -Parent $project) '1c-common'
if ($expectedCommon -ne $commonRoot) { throw 'Project must be a sibling of 1c-common.' }
$encoding = New-Object System.Text.UTF8Encoding($false)
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $commonRoot 'skills') -Directory) {
    $source = Join-Path $skill.FullName 'SKILL.md'
    $body = [IO.File]::ReadAllText($source)
    $frontmatter = [regex]::Match($body, '(?s)\A\uFEFF?---\r?\n.*?\r?\n---')
    if (-not $frontmatter.Success) { throw ('Missing skill frontmatter: ' + $skill.Name) }
    $destDir = Join-Path $project ('.agents/skills/' + $skill.Name)
    if (Test-Path -LiteralPath $destDir) {
        $extra = @(Get-ChildItem -LiteralPath $destDir -Force | Where-Object { $_.Name -ne 'SKILL.md' })
        if ($extra.Count -gt 0) { throw 'Existing skill implementation must be migrated before connecting.' }
    }
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $link = '../../../../1c-common/skills/' + $skill.Name + '/SKILL.md'
    $text = $frontmatter.Value + "`r`n`r`n" + '# Shared skill entry' + "`r`n`r`n"
    $text += 'Before performing the task, read the [shared skill](' + $link + '). Resolve its scripts and references relative to the shared skill directory. Run project operations from the target project root.' + "`r`n`r`n"
    $text += 'Edit the implementation only in 1c-common. Regenerate this entry with 1c-common/tools/connect-project.ps1 after changing skill discovery metadata.' + "`r`n"
    [IO.File]::WriteAllText((Join-Path $destDir 'SKILL.md'), $text, $encoding)
}
Write-Output ('Connected: ' + (Split-Path -Leaf $project))
