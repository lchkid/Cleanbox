# VM Service driver for the Cleanbox debug build.
# Usage:
#   vm.ps1 -Cmd ext -A ext.flutter.debugDumpApp -Port 8186
#   vm.ps1 -Cmd ext -A ext.flutter.debugDumpRenderTree -Port 8186
#   vm.ps1 -Cmd getVM -Port 8186
param(
  [string]$Cmd = "ext",
  [string]$A1 = "ext.flutter.debugDumpApp",
  [string]$A2 = "",
  [int]$Port = 8186,
  [string]$Out = ""
)
$ErrorActionPreference = "Stop"

$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$script:reqId = 0

function Send-Rpc([string]$method, $params) {
  $script:reqId += 1
  $obj = @{ jsonrpc = "2.0"; id = $script:reqId; method = $method }
  if ($null -ne $params) { $obj.params = $params }
  $body = $obj | ConvertTo-Json -Depth 20 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  $seg = [System.ArraySegment[byte]]::new($bytes)
  [void]$ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

  $sb = New-Object System.Text.StringBuilder
  do {
    $buf = New-Object byte[] 1048576
    $rseg = [System.ArraySegment[byte]]::new($buf)
    $res = $ws.ReceiveAsync($rseg, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    [void]$sb.Append([System.Text.Encoding]::UTF8.GetString($buf, 0, $res.Count))
    if ($res.EndOfMessage) { break }
  } while ($true)
  return $sb.ToString()
}

[void]$ws.ConnectAsync([Uri]"ws://127.0.0.1:$Port/ws", [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

$vmRaw = Send-Rpc "getVM" $null
$vm = $vmRaw | ConvertFrom-Json
if ($vm.error) { Write-Output "RPC_ERROR: $($vm.error.message)"; exit 1 }
$isolateId = $vm.result.isolates[0].id

switch ($Cmd.ToLower()) {
  "ext" {
    $params = @{ isolateId = $isolateId }
    $r = Send-Rpc $A1 $params
    $o = $r | ConvertFrom-Json
    if ($o.error) { Write-Output "EXT_ERROR: $($o.error.message)"; Write-Output $r }
    elseif ($null -ne $o.result) {
      if ($Out -ne "") {
        [System.IO.File]::WriteAllText($Out, ([string]$o.result), (New-Object System.Text.UTF8Encoding $false))
        Write-Output "written: $Out"
      } else {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        Write-Output $o.result
      }
    }
    else { Write-Output $r }
  }
  "getVM" {
    Write-Output ($vmRaw)
  }
  "getIsolate" {
    $params = @{ isolateId = $isolateId }
    $r = Send-Rpc "getIsolate" $params
    $o = $r | ConvertFrom-Json
    Write-Output ($o.result | ConvertTo-Json -Depth 8 -Compress)
  }
}
$ws.Dispose()
