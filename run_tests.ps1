$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $root "build"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$core = Get-ChildItem -Path $root -Recurse -Filter *.sv |
    Where-Object { $_.Name -notlike '*_tb.sv' } |
    ForEach-Object { $_.FullName }

$tests = @(
    @{ Top = "ALU_tb";             File = "ALU/ALU_tb.sv" },
    @{ Top = "immgen_tb";          File = "tests/immgen_tb.sv" },
    @{ Top = "control_tb";         File = "tests/control_tb.sv" },
    @{ Top = "dmem_tb";            File = "tests/dmem_tb.sv" },
    @{ Top = "hazard_tb";          File = "tests/hazard_tb.sv" },
    @{ Top = "branchpredictor_tb"; File = "tests/branchpredictor_tb.sv" },
    @{ Top = "register_tb";        File = "tests/register_tb.sv" },
    @{ Top = "processor_tb";       File = "processor_tb.sv" }
)

foreach ($test in $tests) {
    $top = $test.Top
    $tb = Join-Path $root $test.File
    $out = Join-Path $buildDir "$top.vvp"

    Write-Host "RUN $top"
    & iverilog -g2012 -Wall -s $top -o $out @core $tb
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & vvp $out
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "All tests passed."
