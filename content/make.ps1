# Aradhya content pipeline — Windows wrapper.
#   .\content\make.ps1 install
#   .\content\make.ps1 validate
#   .\content\make.ps1 build            # dev build, unverified content allowed
#   .\content\make.ps1 build -Strict    # release build, refuses unverified content
#   .\content\make.ps1 report
#   .\content\make.ps1 all
#
# Run from the repo root. All tools are invoked as modules so that
# `content` is importable as a package (python -m content.tools.X).

param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'validate', 'build', 'report', 'index', 'relate', 'all', 'clean')]
    [string]$Task = 'all',

    [switch]$Strict,
    [string]$Modules = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

function Invoke-Tool {
    param([string]$Module, [string[]]$ToolArgs = @())
    Write-Host "==> python -m content.tools.$Module $($ToolArgs -join ' ')" -ForegroundColor Cyan
    & py -m "content.tools.$Module" @ToolArgs
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        throw "content.tools.$Module failed with exit code $LASTEXITCODE"
    }
}

function Get-BuildArgs {
    $a = @()
    if ($Strict) { $a += '--strict' } else { $a += '--allow-unverified' }
    if ($Modules) { $a += @('--modules', $Modules) }
    return $a
}

try {
    switch ($Task) {
        'install' {
            Write-Host '==> installing python deps' -ForegroundColor Cyan
            & py -m pip install -r content/requirements.txt
            if ($LASTEXITCODE -ne 0) { throw "pip install failed ($LASTEXITCODE)" }
        }
        'validate' { Invoke-Tool 'validate' }
        'build' { Invoke-Tool 'build' (Get-BuildArgs) }
        'report' { Invoke-Tool 'report' }
        'index' { Invoke-Tool 'index' }
        'relate' { Invoke-Tool 'relate' }
        'clean' {
            Write-Host '==> removing content/build' -ForegroundColor Cyan
            if (Test-Path 'content/build') { Remove-Item 'content/build' -Recurse -Force }
        }
        'all' {
            Invoke-Tool 'validate'
            Invoke-Tool 'build' (Get-BuildArgs)
            Invoke-Tool 'report'
        }
    }
    Write-Host "OK: $Task" -ForegroundColor Green
}
finally {
    Pop-Location
}
