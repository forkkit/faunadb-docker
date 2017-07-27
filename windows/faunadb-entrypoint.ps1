$newArgs = @() + $args

if (($newArgs.Length -eq 0) -or ($newArgs[0].StartsWith("-"))) {
  $newArgs = @(".\faunadb.ps1") + $newArgs
}

Invoke-Expression "$newArgs"

