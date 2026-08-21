# RV32I bubble-sort benchmark for Processor/program.hex
# Sorts 9 signed 32-bit integers stored at data-memory byte address 0.
# Testbench preloads memory with: 9, 3, 7, 1, 5, 8, 2, 4, 6

    addi x10, x0, 0          # base address = 0
    addi x11, x0, 9          # n = 9
    addi x5,  x0, 0          # i = 0
    addi x6,  x11, -1        # outer limit = n - 1

outer:
    bge  x5, x6, done        # if i >= n - 1, finish
    addi x7, x0, 0           # j = 0
    sub  x28, x6, x5         # inner limit = n - 1 - i

inner:
    bge  x7, x28, next_outer # if j >= inner limit, next outer loop
    slli x29, x7, 2          # byte offset = j * 4
    add  x29, x10, x29       # address = base + offset
    lw   x8, 0(x29)          # a[j]
    lw   x9, 4(x29)          # a[j + 1]
    addi x7, x7, 1           # j++; fills the load-use gap before compare
    bge  x9, x8, no_swap     # if a[j + 1] >= a[j], already ordered
    sw   x9, 0(x29)
    sw   x8, 4(x29)

no_swap:
    jal  x0, inner

next_outer:
    addi x5, x5, 1
    jal  x0, outer

done:
    ecall                    # benchmark stop marker
