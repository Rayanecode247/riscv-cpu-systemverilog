    .text
    .globl _start

# Bubble-sort five signed positive integers in place.
#
# The array starts at byte address 0.  Each pass compares adjacent words and
# swaps them when the right-hand value is smaller than the left-hand value.
# Only implemented CPU instructions are used; labels are assembler notation,
# not additional machine instructions.

_start:
    addi s0, x0, 0        # s0 = base byte address of the array (0)
    addi s1, x0, 4        # s1 = comparisons remaining in the first pass

outer_pass:
    addi s2, x0, 0        # s2 = comparison index j
    addi s3, s0, 0        # s3 = address of array[j]

inner_pass:
    lw   t0, 0(s3)        # t0 = array[j]
    lw   t1, 4(s3)        # t1 = array[j+1]
    slt  t2, t1, t0       # t2 = 1 when array[j+1] < array[j]
    beq  t2, x0, no_swap  # already ordered: skip the stores
    sw   t1, 0(s3)        # put the smaller value at array[j]
    sw   t0, 4(s3)        # put the larger value at array[j+1]

no_swap:
    addi s3, s3, 4        # advance to the next adjacent pair
    addi s2, s2, 1        # j = j + 1
    slt  t4, s2, s1       # another pair remains in this pass?
    bne  t4, x0, inner_pass

    addi s1, s1, -1       # each pass needs one fewer comparison
    bne  s1, x0, outer_pass

done:
    jal  x0, 0            # halt convention used by the demo testbench
