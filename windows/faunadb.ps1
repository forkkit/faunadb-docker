#Set-PSDebug -Trace 1

. .\helpers.ps1

$host_ip = ((ipconfig) -like '*IPv4*' -split ' : ')[-1]
$join_node = $host_ip
$action = ""
$config_file = ""

function Show-Help {
  Write-Output "FaunaDB Enterprise Docker Image"
  Write-Output ""
  Write-Output "Options:"
  Write-Output " -Help               Print this message and exit."
  Write-Output " -Init               Initialize the node (default action)."
  Write-Output " -Run                Run and doesn't initialize the node."
  Write-Output " -Join host[:port]   Join a cluster through an active node specified in host and port."
  Write-Output " -Config <path>      Specify a custom config file. Should be accessible inside the docker image."
}

function Check-Action {
  if ( $action.Length -ne 0 ) {
    Write-Output "Arguments -Init and -Join are mutually exclusive"
    Exit 1
  }
}

while ( $args.Length -gt 0 ) {
  $arg = $args[0]
  $args = Pop-Front $args

  switch ($arg.ToLower()) {
    "-help" { Show-Help; Exit 0 }
    "-init" { Check-Action; $action = "init" }
    "-run"  { $action = "run" }

    "-join" {
      if ( $args.Length -eq 0 ) {
        Write-Output "Argument -Join needs a HOST[:PORT] address to join a cluster. Skip joining."
      } else {
        Check-Action
        $action = "join"
        $join_node = $args[0]
        $args = Pop-Front $args
      }
    }

    "-config" {
      if ( $args.Length -eq 0 ) {
        Write-Output "Argument -Config needs a file path"
        Exit 1
      }

      $config_file = $args[0]
      $args = Pop-Front $args
    }

    default {
      Write-Output "Invalid argument: $arg"
      Exit 0
    }
  }
}

$default_data_path = "c:\storage\data"
$default_log_path = "c:\storage\log"

if ( $config_file.Length -eq 0 ) {
  $config_file = "c:\faunadb\default.yml"

  $config_content = @"
---
auth_root_key: secret
network_datacenter_name: NoDc
storage_data_path: $default_data_path
log_path: $default_log_path
network_listen_address: $host_ip
network_broadcast_address: $host_ip
network_admin_http_address: 127.0.0.1     #don't expose admin endpoint outside docker by default
network_coordinator_http_address: 0.0.0.0 #expose api endpoint to all interfaces
storage_transaction_log_nodes:
 - [ '$join_node' ]
"@
  $config_content | Out-File -Force -FilePath $config_file
}

$data_path = Get-Config -ConfigFile $config_file -Config "storage_data_path" -DefaultValue $default_data_path
$log_path = Get-Config -ConfigFile $config_file -Config "log_path" -DefaultValue $default_log_path

if ( ($action.Length -eq 0) -and ((Get-ChildItem $data_path | Measure-Object).Count -gt 0) ) {
  $action = "init"
}

if ( $action -eq "init" ) {
  $p = Start-Process "pwsh.exe" -NoNewWindow -ArgumentList "-File","C:\faunadb\faunadb-admin.ps1","-Wait","-Timeout","300","-c",$config_file,"init"
}

if ( $action -eq "join" ) {
  $p = Start-Process "pwsh.exe" -NoNewWindow -ArgumentList "-File","C:\faunadb\faunadb-admin.ps1","-Wait","-Timeout","300","-c",$config_file,"join",$host_address
}

$MAX_HEAP_SIZE = [uint64](Get-Total-Physical-Memory) / 2
$STACK_SIZE = "256k"
$GC_LOG_PATH_OPTS = "-Xloggc:$log_path\gc.log"
$HEAP_REGION_SIZE = "4m"
$GC_OPTS = @("-XX:+UseG1GC", "-XX:MaxGCPauseMillis=200", "-XX:G1HeapRegionSize=$HEAP_REGION_SIZE")

$opts = @(
    "-Djava.net.preferIPv4Stack=true", `
    "-Dhttp.connection.timeout=2", `
    "-Dhttp.connection-manager.timeout=2", `
    "-Dhttp.socket.timeout=6" `
  ) + $JAVA_OPTS +
  @(
    "-Xmx${MAX_HEAP_SIZE}K", `
    "-Xms${MAX_HEAP_SIZE}K", `
    "-Xss$STACK_SIZE", `
    $GC_LOG_PATH_OPTS `
  ) + $GC_OPTS +
  @(
    "-XX:-UseBiasedLocking", `
    "-XX:+UseThreadPriorities", `
    "-XX:+StartAttachListener" `
  )

$config_file | Out-File -Force -FilePath "c:\faunadb\config_file"
Get-Item -Force "c:\faunadb\config_file" | foreach { $_.Attributes += "Hidden" }

c:\java\bin\java.exe $opts -server -jar c:\faunadb\lib\faunadb.jar -c $config_file

