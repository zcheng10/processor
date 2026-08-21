.data
array:  .word 9, 3, 7, 1, 5, 8, 2, 4, 6    # The array to sort
size:   .word 9                           # Number of elements in the array

.text
.globl main

main:
    la   a0, array        # Load base address of the array
    lw   a1, size         # Load the number of elements

bubble_sort:
    li   t0, 0            # t0 = outer loop counter (i)
    sub  t1, a1, 1        # t1 = limit for outer loop (size - 1)

outer_loop:
    bge  t0, t1, done     # If i >= size - 1, sorting is finished
    li   t2, 0            # t2 = inner loop counter (j)
    sub  t3, t1, t0       # t3 = limit for inner loop (size - 1 - i)

inner_loop:
    bge  t2, t3, next_outer # If j >= size - 1 - i, move to next outer iteration

    # Calculate memory addresses of array[j] and array[j+1]
    slli t4, t2, 2        # t4 = j * 4 (byte offset for element j)
    add  t4, a0, t4       # t4 = address of array[j]
    
    lw   s0, 0(t4)        # s0 = array[j]
    lw   s1, 4(t4)        # s1 = array[j+1]

    # Compare adjacent elements
    ble  s0, s1, no_swap  # If array[j] <= array[j+1], no swap needed

    # Swap elements in memory
    sw   s1, 0(t4)        # store old array[j+1] into array[j]
    sw   s0, 4(t4)        # store old array[j] into array[j+1]

no_swap:
    addi t2, t2, 1        # j = j + 1
    j    inner_loop       # Repeat inner loop

next_outer:
    addi t0, t0, 1        # i = i + 1
    j    outer_loop       # Repeat outer loop

done:
    # Exit program execution (Standard Environment / RARS / Venus syscall)
    li   a7, 10           # Syscall code 10 for exit
    ecall
