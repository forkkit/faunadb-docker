
function Get-Config([String] $ConfigFile, [String] $Config, [String] $DefaultValue) {
  $value = Get-Content $ConfigFile | where { $_ -match '^$Config:\s*(.*)$' } | foreach { ($matches[1] -split '#')[0].Trim() }

  if ( $value.Length -eq 0 ) {
    return $DefaultValue
  }

  return $value
}

function Test-Connection([String] $Address, [String] $Port) {
  try {
    $connection = New-Object System.Net.Sockets.TcpClient($Address, $Port)
    $isConnected = $connection.Connected
    $connection.Close()
    return $isConnected
  } catch {
    return $false
  }
}

function Pop-Front([array] $Array) {
  return ,@($Array | Select-Object -Skip 1)
}


if (-not ("Kernel32" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct MEMORYSTATUSEX {
  public uint  dwLength;
  public uint  dwMemoryLoad;
  public ulong ullTotalPhys;
  public ulong ullAvailPhys;
  public ulong ullTotalPageFile;
  public ulong ullAvailPageFile;
  public ulong ullTotalVirtual;
  public ulong ullAvailVirtual;
  public ulong ullAvailExtendedVirtual;
}

public static class Kernel32 {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GlobalMemoryStatusEx(out MEMORYSTATUSEX lpBuffer);
}
"@
}

function Get-Total-Physical-Memory {
  $memoryStatus = New-Object MEMORYSTATUSEX
  $memoryStatus.dwLength = [System.Runtime.InteropServices.Marshal]::SizeOf($memoryStatus)

  if ([Kernel32]::GlobalMemoryStatusEx([ref] $memoryStatus)) {
    return $memoryStatus.ullTotalPhys / 1024
  }

  return 0
}
