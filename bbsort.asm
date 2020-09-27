j main
j interrupt
j exception

main:
nop
nop
nop
li $s5 0x40000014
lw $s4 0($s5)    # $s4: initial systick
add $s0 $zero $zero # $s0: start address of data
addi $s1 $zero 128  # N=128

add $t0 $zero $s1 # i=N
for1:
beq $t0 $zero endfor1
addi $t1 $zero 0  # j=0
for2:
addi $t1 $t1 1
slt $t2 $t1 $t0
beq $t2 $zero endfor2 
sll $t2 $t1 2
add $t2 $t2 $s0
lw $a0 0($t2)
lw $a1 4($t2)
sltu $t3 $a0 $a1
beq $t3 $zero for2
jal swap
sw $a0 0($t2)
sw $a1 4($t2)
j for2
endfor2:
sub $t0 $t0 1
j for1
endfor1:

# save systick
li $s5 0x40000014
lw $s7 0($s5)
sub $s5 $s7 $s4  # systick diff

# enable timer
li $t0 0x40000000 # timer address
li $t1 0xffff0000
li $t2 0xffffffff
addi $t3 $zero 3
sw $t1 0($t0) # TH
sw $t2 4($t0) # TL
sw $t3  8($t0) # TCON


loop:
j loop

swap:
xor $a0 $a0 $a1
xor $a1 $a0 $a1
xor $a0 $a0 $a1
jr $ra


exception:
nop
nop
nop
j exception

interrupt:
#disable timer
li $s0 0x40000000 # timer address
sw $zero 8($s0) 
add $s1 $zero 516 # $s1: start address of ssd table,129*4


li $s3 	0x40000010

add $s2 $zero 15
and $t0 $s5 $s2
sll $t0 $t0 2
add $t0 $t0 $s1
lw $t0 0($t0)
srl $s5 $s5 4
and $t1 $s5 $s2
sll $t1 $t1 2
add $t1 $t1 $s1
lw $t1 0($t1)
srl $s5 $s5 4
and $t2 $s5 $s2
sll $t2 $t2 2
add $t2 $t2 $s1
lw $t2 0($t2)
srl $s5 $s5 4
and $t3 $s5 $s2
sll $t3 $t3 2
add $t3 $t3 $s1
lw $t3 0($t3)

scan:
add $t5 $t0 $zero
sw $t5 0($s3)
add $t5 $t1 $zero
sw $t5 0($s3)
add $t5 $t2 $zero
sw $t5 0($s3)
add $t5 $t3 $zero
sw $t5 0($s3)
j scan
jr $k0