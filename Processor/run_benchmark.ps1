$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $root
$buildDir = Join-Path $repoRoot "build"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$core = Get-ChildItem -Path $root -Filter *.sv |
    Where-Object { $_.Name -notin @("processor_tb.sv", "ALU.sv", "adder.sv") } |
    ForEach-Object { $_.FullName }

$out = Join-Path $buildDir "bubble_sort_tb.vvp"

Push-Location $root
try {
    & iverilog -g2012 -Wall -s processor_tb -o $out @core processor_tb.sv
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & vvp $out
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
