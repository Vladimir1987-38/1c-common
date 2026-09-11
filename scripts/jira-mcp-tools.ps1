$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
. (Join-Path $scriptDir '../.jira-devbase.ps1')

# Step 1: Initialize
$initObj = @{
    jsonrpc = '2.0'
    id = 1
    method = 'initialize'
    params = @{
        protocolVersion = '2025-03-26'
        capabilities = @{}
        clientInfo = @{ name = '1c-common'; version = '1.0' }
    }
} | ConvertTo-Json -Depth 30 -Compress

$req1 = [System.Net.WebRequest]::Create('http://jira-mcp.teremok-spb.local:9000/mcp')
$req1.Method = 'POST'
$req1.ContentType = 'application/json'
$req1.Headers['Authorization'] = "Bearer $JIRA_MCP_TOKEN"
$req1.Accept = 'application/json, text/event-stream'
$body1 = [Text.Encoding]::UTF8.GetBytes($initObj)
$req1.ContentLength = $body1.Length
$req1.GetRequestStream().Write($body1, 0, $body1.Length)

$resp1 = $req1.GetResponse()
$reader1 = New-Object System.IO.StreamReader $resp1.GetResponseStream()
$text1 = $reader1.ReadToEnd()
$reader1.Close()
$resp1.Close()

Write-Host "Init response: $text1"

# Parse SSE to extract session ID from response headers
# The session ID might be in the response headers
$sessionId = $null
$rawHeaders = $resp1.Headers
foreach ($key in $rawHeaders.AllKeys) {
    Write-Host "Header: $key = $($rawHeaders.Get($key))"
    if ($key -ilike '*session*') {
        $sessionId = $rawHeaders.Get($key)
    }
}

# Also try to extract from body if it contains session info
if (-not $sessionId) {
    # Parse SSE format: extract JSON from data lines
    $lines = $text1 -split "`n"
    foreach ($line in $lines) {
        if ($line -like 'data:*') {
            $data = $line -replace '^data:\s*', ''
            Write-Host "Data line: $data"
            try {
                $parsed = $data | ConvertFrom-Json
                if ($parsed.result -and $parsed.result.sessionId) {
                    $sessionId = $parsed.result.sessionId
                }
            } catch {}
        }
    }
}

Write-Host "Session ID: $sessionId"

# Step 2: tools/list (skip notifications for now)
$toolsObj = @{
    jsonrpc = '2.0'
    id = 3
    method = 'tools/list'
    params = @{}
} | ConvertTo-Json -Depth 30 -Compress

$req2 = [System.Net.WebRequest]::Create('http://jira-mcp.teremok-spb.local:9000/mcp')
$req2.Method = 'POST'
$req2.ContentType = 'application/json'
$req2.Headers['Authorization'] = "Bearer $JIRA_MCP_TOKEN"
$req2.Accept = 'application/json, text/event-stream'
if ($sessionId) { $req2.Headers['Mcp-Session-Id'] = $sessionId }
$body2 = [Text.Encoding]::UTF8.GetBytes($toolsObj)
$req2.ContentLength = $body2.Length
$req2.GetRequestStream().Write($body2, 0, $body2.Length)

try {
    $resp2 = $req2.GetResponse()
    $reader2 = New-Object System.IO.StreamReader $resp2.GetResponseStream()
    $text2 = $reader2.ReadToEnd()
    $reader2.Close()
    $resp2.Close()
    Write-Host "`nTools response: $text2"
    
    # Parse JSON-RPC response from SSE
    $lines2 = $text2 -split "`n"
    $jsonData = $null
    foreach ($line in $lines2) {
        if ($line -like 'data:*') {
            $data = $line -replace '^data:\s*', ''
            try {
                $jsonData = $data | ConvertFrom-Json
            } catch {}
        }
    }
    
    if ($jsonData.result.tools) {
        Write-Host "`nAvailable tools:"
        $jsonData.result.tools | ForEach-Object { Write-Host "  - $($_.name)" }
    }
} catch {
    Write-Host "Tools error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Host "Status: $($_.Exception.Response.StatusCode)"
        $errReader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        $errText = $errReader.ReadToEnd()
        $errReader.Close()
        Write-Host "Body: $errText"
    }
}
