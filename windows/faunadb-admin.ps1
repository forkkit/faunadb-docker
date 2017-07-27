#Set-PSDebug -Trace 1

. .\helpers.ps1

$config_file = "c:\faunadb\default.yml"
$admin_port = ""
$admin_address = ""
$maxTimeout = 300
$wait_fauna = $false
$newArgs = @()

if (Test-Path "c:\faunadb\config_file") {
  $config_file = Get-Content -Path "c:\faunadb\config_file"
}

function Wait-Fauna-And-Do([ScriptBlock] $Block) {
  $timeout = 0;

  while ($wait_fauna -and (-not (Test-Connection $admin_address $admin_port))) {
    $timeout++

    if ( $timeout -gt $maxTimeout ) {
      Write-Output "Initialization timed out, server took more than $maxTimeout seconds to initialize"
      Exit 1
    }

    Sleep 1
  }

  $Block.Invoke()
}

while ($args.Length -gt 0) {
  $arg = $args[0]

  $args = Pop-Front $args

  switch($arg) {
    "-Wait" {
      $wait_fauna = $true
    }

    "-Timeout" {
      if ( $args.Length -eq 0 -or (-not [Int32]::TryParse($args[0], [ref] $maxTimeout))) {
        Write-Output "Invalid Timeout argument"
        Exit 1
      }

      $args = Pop-Front $args
    }

    "-c" {
      $config_file = $args[0]
      $args = Pop-Front $args
      $newArgs = $newArgs + @("-c", $config_file)
    }

    default {
      $newArgs = $newArgs + @($arg)
    }
  }
}

$Env:FAUNADB_CONFIG = $config_file

# 2.5.3 doesn't get config from FAUNADB_CONFIG
if ($Env:FAUNADB_VERSION.StartsWith("2.5.3")) {
  # so, if not specified on cmdline, force use it
  if ($newArgs -notcontains "-c") {
    $newArgs = $newArgs + @("-c", $config_file)
  }
}

$admin_port = Get-Config -ConfigFile $config_file -Config "network_admin_http_port" -DefaultValue "8444"
$admin_address = Get-Config -ConfigFile $config_file -Config "network_admin_http_address" -DefaultValue "127.0.0.1"

Wait-Fauna-And-Do {
  $arguments = @("-server", "-cp", "c:\faunadb\lib\faunadb.jar", "fauna.tools.Admin") + $newArgs
  $p = Start-Process "c:\java\bin\java.exe" -NoNewWindow -ArgumentList $arguments
}

