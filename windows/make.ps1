$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Load-Var {
    param
    (
        [String] $Name,
        [String] $Default
    )

    if (-not (Test-Path Env:$Name)) {
        return $Default
    }
    return (Get-Item -Path Env:$Name).Value
}

function Require-Var {
    param
    (
        [String] $Name,
        [String] $Value
    )

    if (!$Value) {
        Write-Error "$Name is undefined"
        Exit 1
    }
}

$Repo = Load-Var "REPO" "gcr.io/faunadb-cloud"
$Version = Load-Var "FAUNADB_VERSION" $null
$PkgVersion = Load-Var "FAUNADB_PKG_VERSION" $null
$Nightly = Load-Var "FAUNADB_NIGHTLY" $null
$ExtraTags = Load-Var "EXTRA_TAGS" ""
$Tags = "$Version $ExtraTags".Trim() -Split "\s+"

function Target-All {
    Target-FetchRelease
    Target-Build
}

function Target-FetchRelease {
    Require-Var "FAUNADB_VERSION" $Version
    Require-Var "FAUNADB_PKG_VERSION" $PkgVersion

    $TargetPath = "faunadb-enterprise-$PkgVersion.zip"

    if (-not (Test-Path $TargetPath)) {
        aws s3 cp "s3://fauna-releases/builds/enterprise/$Version/faunadb-enterprise-$PkgVersion.zip" .
        if ($LastExitCode -ne '0') { Exit $LastExitCode }
    }
}

function Target-FetchNightly {
    Require-Var "FAUNADB_NIGHTLY" $Nightly
    Require-Var "FAUNADB_PKG_VERSION" $PkgVersion

    $TargetPath = "faunadb-enterprise-$PkgVersion.zip"

    if (-not (Test-Path $TargetPath)) {
        aws s3 cp "s3://fauna-nightly/$Env:FAUNADB_NIGHTLY/faunadb-enterprise-$PkgVersion.zip" .
        if ($LastExitCode -ne '0') { Exit $LastExitCode }
    }
}

function Target-Build {
    Require-Var "FAUNADB_VERSION" $Version
    Require-Var "FAUNADB_PKG_VERSION" $PkgVersion

    docker build --pull --build-arg "VERSION=$Version" --build-arg "PKG_VERSION=$PkgVersion" -t "faunadb/enterprise:$Version-windows" .
    if ($LastExitCode -ne '0') { Exit $LastExitCode }
}

function Target-PublishRelease {
    Require-Var "FAUNADB_VERSION" $Version

    foreach ($tag in $Tags) {
        docker tag "faunadb/enterprise:$Version-windows" "$Repo/faunadb/enterprise:$tag-windows"
        if ($LastExitCode -ne '0') { Exit $LastExitCode }
    }

    foreach ($tag in $Tags) {
        docker push "$Repo/faunadb/enterprise:$tag-windows"
        if ($LastExitCode -ne '0') { Exit $LastExitCode }
    }
}

function Target-PublishNightly {
    Require-Var "FAUNADB_VERSION" $Version

    foreach ($tag in $Tags) {
        docker tag "faunadb/enterprise:$Version-windows" "$Repo/faunadb/enterprise/nightly:$tag-windows"
        if ($LastExitCode -ne '0') { Exit $LastExitCode }
    }

    foreach ($tag in $Tags) {
        docker push "$Repo/faunadb/enterprise/nightly:$tag-windows"
        if ($LastExitCode -ne '0') { Exit $LastExitCode }
    }
}

# Load in vars from command line
foreach ($arg in $args) {
    if ($arg.IndexOf("=") -ne -1) {
        $Name, $Value = $arg.Split("=", 2)

        switch ($Name.ToUpper()) {
            "REPO"                { $Repo = $Value }
            "FAUNADB_VERSION"     { $Version = $Value }
            "FAUNADB_PKG_VERSION" { $PkgVersion = $Value }
            "FAUNADB_NIGHTLY"     { $Nightly = $Value }
            "EXTRA_TAGS"          { $ExtraTags = $Value; $Tags = "$Version $ExtraTags".Trim() -Split "\s+" }
        }
    }
}

# Execute targets
$targets = 0
foreach ($arg in $args) {
    if ($arg.IndexOf("=") -eq -1) {
        $targets++
        switch ($arg.ToLower()) {
            "fetch-release"   { Target-FetchRelease }
            "fetch-nightly"   { Target-FetchNightly }
            "build"           { Target-Build }
            "publish-release" { Target-PublishRelease }
            "publish-nightly" { Target-PublishNightly }
            default { Write-Error "Unknown target $arg."; Exit 1 }
        }
    }
}

# Execute all if no targets given
if ($targets -eq 0) {
    Target-All
}
