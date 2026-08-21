# 5-Stage Pipelined RV32I Processor

This project is a SystemVerilog implementation of a 32-bit, 5-stage pipelined RISC-V processor targeting the base RV32I integer instruction set. The core includes instruction fetch, decode, execute, memory, and writeback stages, plus forwarding, load-use hazard handling, branch prediction, misprediction recovery, byte-addressable data memory, and hardware performance counters.

The current integrated/runnable processor lives in [`Processor/`](Processor/). The root-level module folders contain the earlier separated module layout and related tests; for running the full processor and benchmark, use the self-contained files in [`Processor/`](Processor/).

## High-level architecture

The processor follows the classic 5-stage RISC pipeline:

- The fetch stage reads the next instruction and asks the branch predictor for the next PC.
- The decode stage extracts fields, reads registers, generates immediates, and produces control signals.
- The execute stage performs ALU operations, branch comparisons, JAL/JALR target generation, and misprediction detection.
- The memory stage performs RV32I load/store accesses.
- The writeback stage selects ALU, memory, or `PC + 4` results and writes the register file.

## Supported RV32I behavior

The design supports the main RV32I integer datapath instructions:

- R-type ALU ops: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`
- I-type ALU ops: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU`
- Loads: `LB`, `LH`, `LW`, `LBU`, `LHU`
- Stores: `SB`, `SH`, `SW`
- Branches: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- Jumps: `JAL`, `JALR`
- Upper immediates: `LUI`, `AUIPC`

`ECALL` is used by the benchmark testbench as a halt marker. `FENCE`, `ECALL`, and `EBREAK` are treated as simple no-op/control markers.

## Pipeline behavior

### Fetch

The fetch stage contains:

- `PC`
- instruction memory
- `PC + 4` adder
- conditional branch predictor
- next-PC mux

The normal next PC comes from the predictor. If a branch/jump is later found to have been mispredicted in execute, the PC is redirected to the correct target.

### Decode

Decode performs:

- instruction field extraction
- control signal generation
- register reads
- immediate generation
- source-register usage detection for more precise hazards

The register file includes x0 hardwiring and same-cycle writeback bypassing. This avoids a common 5-stage pipeline issue where an instruction in decode reads a register that the writeback stage is updating in the same cycle.

### Execute

Execute performs:

- ALU operations
- branch condition evaluation
- branch target calculation
- JAL target calculation
- JALR target calculation
- forwarding selection
- misprediction detection

Branch and jump recovery is handled by comparing the predicted PC carried through the pipeline against the actual next PC computed in execute:

```systemverilog
mispredictE = (branchE || jumpE) && (predictedPCE != actualNextPCE);
```

On a misprediction, the decode and execute stages are flushed and fetch restarts at the correct PC.

### Memory

The data memory is byte-addressable and supports RV32I byte, halfword, and word operations:

- signed loads: `LB`, `LH`
- unsigned loads: `LBU`, `LHU`
- word load: `LW`
- byte/halfword/word stores: `SB`, `SH`, `SW`

### Writeback

Writeback selects one of:

- ALU result
- memory load result
- `PC + 4` for `JAL`/`JALR`

The selected value is written into the register file if `regWriteW` is asserted and `rd != x0`.

## Hazard handling

The design handles the major hazards expected in a simple 5-stage pipeline.

### Data forwarding

ALU operands in execute can be forwarded from:

- the EX/MEM stage
- the MEM/WB stage
- the register value originally read in decode

This avoids most ALU-to-ALU dependency stalls.

### Load-use stalls

If an instruction in decode immediately consumes the destination register of a load in execute, the hazard unit stalls fetch/decode and inserts a bubble into execute.

Load-use penalty:

```text
1 cycle per immediate load-use dependency
```

### Control hazards

Conditional branches are predicted in fetch, but resolved in execute. If the prediction was wrong, the design flushes the wrong-path instructions.

Current redirect penalty:

```text
2 cycles per branch/jump misprediction
```

The branch predictor currently predicts conditional branches only. Unconditional `JAL` instructions are corrected in execute, so each taken JAL currently behaves like a redirect miss.

## Branch predictor

The branch predictor in [`Processor/branchpredictor.sv`](Processor/branchpredictor.sv) uses:

- 1024 predictor entries
- 2-bit saturating counters
- unconditional fetch-stage `JAL` target prediction
- a small decreasing-trip-count loop-exit predictor
- strongly-not-taken reset state
- PC-based hash index
- update when a conditional branch resolves in execute

The predictor output is a predicted next PC. The pipeline stores that predicted PC in the IF/ID and ID/EX registers so execute can compare it against the true next PC.

<!--Tradeoff: the predictor improves loop and jump behavior, but the current hash logic is more expensive than simply indexing with `pc[11:2]`. For a higher Fmax, replacing the hash with a simpler XOR or direct index is likely beneficial. The loop-exit predictor also adds small per-entry state to reduce repeated loop-exit misses.
-->
## Performance counters

The top-level processor exposes hardware counters:

| Counter | Meaning |
|---|---|
| `cycle_count` | Cycles elapsed while the benchmark is running |
| `instruction_retired_count` | Non-NOP, non-ECALL instructions retired |
| `load_use_stall_count` | Number of load-use stall cycles |
| `redirect_flush_count` | Number of branch/jump redirect events |
| `branch_count` | Conditional branches resolved |
| `branch_taken_count` | Conditional branches that were taken |
| `branch_mispredict_count` | Conditional branch mispredictions |
| `jump_count` | Jump instructions resolved |
| `jump_mispredict_count` | Jump redirect misses |
| `halted` | Goes high after `ECALL` reaches writeback |

The testbench computes:

```text
IPC = retired_instructions / cycles
CPI = cycles / retired_instructions
branch_accuracy = 1 - branch_mispredicts / branches
```

If you later synthesize the design and obtain an Fmax, you can compute an effective throughput:

```text
MIPS = Fmax_MHz × IPC
```

For example, if synthesis reports 100 MHz and this benchmark remains at 0.916 IPC:

```text
100 MHz × 0.916 IPC ≈ 91.6 MIPS
```

## Design choices and tradeoffs

### 5-stage pipeline vs single-cycle CPU

A single-cycle CPU must fit fetch, decode, execute, memory, and writeback into one clock period. This design splits that work across five pipeline stages, which should allow a higher clock frequency.

Tradeoff: pipelining introduces hazards, forwarding logic, stall logic, flush logic, and pipeline registers.

### Separate instruction and data memories

The design uses separate instruction and data memory paths, avoiding fetch/load-store structural hazards.

Tradeoff: this is simpler and faster for a small educational core, but it assumes separate memory resources or a Harvard-style memory interface.

### Forwarding

Forwarding improves IPC because dependent ALU instructions usually do not stall.

Tradeoff: forwarding adds comparators and muxes to the execute-stage path, which may reduce maximum clock frequency slightly.

The current integrated core also forwards the full memory-stage result, including load data, from MEM to EX. Because the data memory is modeled with combinational reads, this removes immediate load-use bubbles in the benchmark.

Tradeoff: zero-bubble load-use forwarding assumes the data memory output is available early enough to feed the next execute stage. On an FPGA using synchronous block RAM, this may need to become a one-cycle load-use stall again, or the memory system must be redesigned around that timing.

### Branch resolution in execute

Resolving branches in execute keeps decode simpler.

Tradeoff: mispredictions cost two cycles. Moving branch compare/target logic into decode could reduce the penalty to one cycle, but would lengthen the decode critical path.

### Conditional branch prediction

The predictor improves repeated conditional branch behavior in loops.

Tradeoff: the current predictor handles `JAL` and loop-exit behavior, but its hash calculation may be expensive for synthesis timing.

### Byte-addressable memory

Byte-addressable memory supports the full RV32I load/store width behavior.

Tradeoff: byte lane selection and sign extension add logic compared with a simple word-only memory.

## Running the benchmark

TODO: synthesization with Quartus and simulation with Modelsim/Questasim
### Requirements

- Icarus Verilog with SystemVerilog support:
  - `iverilog`
  - `vvp`
- PowerShell
- Optional: GTKWave for waveform viewing

### Run bubble sort

From the project root:

```powershell
cd "C:\Users\Maxwell\Documents\RISCV processor"
powershell -ExecutionPolicy Bypass -File .\Processor\run_benchmark.ps1
```

The script compiles the integrated processor and runs [`Processor/processor_tb.sv`](Processor/processor_tb.sv). The testbench:

1. resets the processor,
2. preloads data memory with:

   ```text
   9, 3, 7, 1, 5, 8, 2, 4, 6
   ```

3. runs the machine code in [`Processor/program.hex`](Processor/program.hex),
4. waits for `ECALL`,
5. checks that memory contains:

   ```text
   1, 2, 3, 4, 5, 6, 7, 8, 9
   ```

6. prints performance counters.

The benchmark testbench also asserts that measured IPC is at least `0.900000`.


### Viewing waveforms

The benchmark generates `bubble_sort.vcd` in the `Processor/` directory when it runs. If GTKWave is installed:

```powershell
gtkwave .\Processor\bubble_sort.vcd
```

## Benchmark results and interpretation
