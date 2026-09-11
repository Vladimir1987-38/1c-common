$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../.jira-devbase.ps1')

$jiraMcpHeaders = @{
    Authorization = "Bearer $JIRA_MCP_TOKEN"
    Accept = 'application/json'
}

# Step 1: Initialize session
$initBody = @{
    jsonrpc = '2.0'
    id = 1
    method = 'initialize'
    params = @{
        protocolVersion = '2025-03-26'
        capabilities = @{}
        clientInfo = @{ name = '1c-common'; version = '1.0' }
    }
} | ConvertTo-Json -Depth 30

$req1 = [System.Net.WebRequest]::Create('http://jira-mcp.teremok-spb.local:9000/mcp')
$req1.Method = 'POST'
$req1.ContentType = 'application/json; charset=utf-8'
$req1.Headers['Authorization'] = "Bearer $JIRA_MCP_TOKEN"
$body1 = [Text.Encoding]::UTF8.GetBytes($initBody)
$req1.ContentLength = $body1.Length
$req1.GetRequestStream().Write($body1, 0, $body1.Length)

$resp1 = $req1.GetResponse()
$reader1 = New-Object System.IO.StreamReader $resp1.GetResponseStream()
$responseText1 = $reader1.ReadToEnd()
$reader1.Close()
$resp1.Close()

# Extract session ID from response headers if present
$sessionId = $null
if ($resp1.Headers['Mcp-Session-Id']) {
    $sessionId = $resp1.Headers['Mcp-Session-Id']
}

Write-Host "Initialize response: $responseText1"
if ($sessionId) { Write-Host "Session ID: $sessionId" }

# Step 2: List tools
$toolsListBody = @{
    jsonrpc = '2.0'
    id = 2
    method = 'tools/list'
    params = @{}
} | ConvertTo-Json -Depth 30

$req2 = [System.Net.WebRequest]::Create('http://jira-mcp.teremok-spb.local:9000/mcp')
$req2.Method = 'POST'
$req2.ContentType = 'application/json; charset=utf-8'
$req2.Headers['Authorization'] = "Bearer $JIRA_MCP_TOKEN"
if ($sessionId) { $req2.Headers['Mcp-Session-Id'] = $sessionId }
$body2 = [Text.Encoding]::UTF8.GetBytes($toolsListBody)
$req2.ContentLength = $body2.Length
$req2.GetRequestStream().Write($body2, 0, $body2.Length)

$resp2 = $req2.GetResponse()
$reader2 = New-Object System.IO.StreamReader $resp2.GetResponseStream()
$responseText2 = $reader2.ReadToEnd()
$reader2.Close()
$resp2.Close()

Write-Host "Tools list response: $responseText2"
