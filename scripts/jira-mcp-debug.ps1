$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
. (Join-Path $scriptDir '../.jira-devbase.ps1')

# Initialize - try without Accept header
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

$req = [System.Net.WebRequest]::Create('http://jira-mcp.teremok-spb.local:9000/mcp')
$req.Method = 'POST'
$req.ContentType = 'application/json'
$req.Headers['Authorization'] = "Bearer $JIRA_MCP_TOKEN"
$req.Accept = 'application/json, text/event-stream'
$body = [Text.Encoding]::UTF8.GetBytes($initObj)
$req.ContentLength = $body.Length
$req.GetRequestStream().Write($body, 0, $body.Length)

try {
    $resp = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader $resp.GetResponseStream()
    $text = $reader.ReadToEnd()
    $reader.Close()
    $resp.Close()
    Write-Host "Response: $text"
    if ($resp.Headers['Mcp-Session-Id']) {
        Write-Host "Session: $($resp.Headers['Mcp-Session-Id'])"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Host "Status: $($_.Exception.Response.StatusCode)"
        $errReader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        $errText = $errReader.ReadToEnd()
        $errReader.Close()
        Write-Host "Body: $errText"
    }
}
