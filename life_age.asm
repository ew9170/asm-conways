# Name:	Eaton Wu
# Section 3
# Project 1 (of 1)
#
# Description:	Conway's Game of Life in MIPS!
#
#		The program reads three values from standard input:
#		1) Board Size
#       2) The number of generations
#       3) Number of live cells
#       4) Locations to initialize the life board w/ cells


### syscall codes ###
PRINT_INT =	1     ###
PRINT_STRING = 4  ###
READ_INT = 5      ###
READ_STRING = 8   ###
EXIT = 10         ###
#####################


#------------------------ hardcoded strings ------------------------ #    
    .data                                                            #
    .align 2                                                         #
                                                                     #
banner_string:                                                       #
    .ascii  "\n*************************************\n"              #
    .ascii  "****    Game of Life with Age    ****\n"                #
    .asciiz "*************************************\n"                #
                                                                     #
board_size_prompt:                                                   #
    .asciiz "\nEnter board size: "                                   #
                                                                     #
generation_quantity_prompt:                                          #
    .asciiz "\nEnter number of generations to run: "                 #
                                                                     #
live_cell_quantity_prompt:                                           #
    .asciiz "\nEnter number of live cells: "                         #
                                                                     #
enter_locations_prompt:                                              #
    .asciiz "\nStart entering locations\n"                           #
                                                                     #
invalid_board_prompt:                                                #
    .asciiz "\nWARNING: illegal board size, try again: "             #
                                                                     #
invalid_generations_prompt:                                          #
    .asciiz "\nWARNING: illegal number of generations, try again: "  #
                                                                     #
invalid_cells_prompt:                                                #
    .asciiz "\nWARNING: illegal number of live cells, try again: "   #
                                                                     #
invalid_point_prompt:                                                #
    .asciiz "\nERROR: illegal point location\n"                      #
                                                                     #
blank_space:                                                         #
    .asciiz " "                                                      #
                                                                     #
generation_print_1:                                                  #
    .asciiz "\n====    GENERATION "                                  #
                                                                     #
generation_print_2:                                                  #
    .asciiz "    ====\n"                                             #
                                                                     #
plus_symbol:                                                         #
    .asciiz "+"                                                      #
                                                                     #
dash_symbol:                                                         #
    .asciiz "-"                                                      #
                                                                     #
bar_symbol:                                                          #
    .asciiz "|"                                                      #
                                                                     #
new_line:                                                            #
    .asciiz "\n"                                                     #
                                                                     #
get_attributes_complete_print:                                       #
    .asciiz "\nlocations done\n"                                     #
                                                                     #
                                                                     #
                                                                     #
                                                                     #
    .text                                                            #
                                                                     #
#------------------------ hardcoded strings ------------------------ #
    


#---------------------- Game of Life Attribute Struct ---------------------- #
    .data

cell_array:
    .space 930              # allocate 120 bytes (maximum size of 30 * 30 bytes, one byte per character + null terminator)

cell_array_buffer:
    .space 930              # allocate 

board_attributes:     
    .word   0                 # board size (0)
    .word   0                 # generation quantity (4)
    .word   0                 # cell quantity (8)

    .text
#---------------------- Game of Life Attribute Struct ---------------------- # 

#   get_attributes()
#   sets the game of life matrix (cell_array)to an initial state, 
#   specified by the user
#   
#   arguments: n/a
#   destroys: $a0, $t1, $t2, $t3, $t4
get_attributes:

    addi    $sp, $sp, 8         # allocate space for 1
    sw      $s0, 4($sp)
    sw      $ra, 0($sp)

    # BOARD INPUT #
    li      $v0, PRINT_STRING
    la      $a0, board_size_prompt
    syscall
    start_board_input:
    li      $v0, READ_INT           
    syscall                                     # at this point, board_size is in $v0
    li      $t2, 4
    slt     $t0, $v0, $t2                       # check if input - 30 is negative, is < 30 if $t0 is 0
    bne		$t0, $zero, bad_board_value         # if not 0, then value was greater than 30
    li      $t2, 31
    slt     $t1, $v0, $t2                       # check if input - 4 is positive, is < 4 if $t0 is 1
    beq     $t1, $zero, bad_board_value
    # if value is valid, set cell_array[0] = $v0
    la		$t0, board_attributes
    sw		$v0, 0($t0)	                        # dereference cell_array to store board_size
     

    # GENERATION INPUT #
    li      $v0, PRINT_STRING
    la      $a0, generation_quantity_prompt
    syscall
    start_generation_input:
    li      $v0, READ_INT           
    syscall

    li      $t2, 21

    slt     $t1, $v0, $t2                       # is input < 20?
    beq     $t1, $zero, bad_generation_value    # if $t1 == 1, then $v0 was not greater than 20, which is ideal.

    slt     $t0, $v0, $zero                     # is input < 0 (negative)?                     
    bne		$t0, $zero, bad_generation_value    # if not 0, then negative.
    la      $t0, board_attributes
    sw      $v0, 4($t0)


    # LIVE CELL QUANTITY INPUT #
    li      $v0, PRINT_STRING
    la      $a0, live_cell_quantity_prompt
    syscall

    start_cell_input:
    li      $v0, READ_INT           
    syscall

    slt     $t0, $v0, $zero                     # check if input is negative, is negative if $t0 is 0
    bne		$t0, $zero, bad_cell_value          # if not 0, then value was greater than 30
         
    la      $t0, board_attributes
    lw      $t0, 0($t0)                         # put board size into $t0
    mult	$t0, $t0			                # square the board size
    mflo	$t0					                # place max # of cells in $t0
    
    slt     $t1, $v0, $t0                       # check if input < board_size ^ 2, then is valid
    beq     $t1, $zero, bad_cell_value
    la      $t0, board_attributes
    sw      $v0, 8($t0)


    li		$v0, PRINT_STRING
    la      $a0, enter_locations_prompt
    syscall

    # Get counter for the decrementing for loop
    # (while live_cell_count_copy > 0):
    la      $s0, board_attributes
    lw      $s0, 8($t0)

    get_points_loop_start:
    beq     $s0, $zero, get_attributes_done

    start_point_input:
    # CELL LOCATION QUANTIY INPUT #
    # read row
    li      $v0, READ_INT
    syscall

    la      $t1, board_attributes
    lw      $t1, 0($t1)

    slt     $t0, $v0, $zero
    bne     $t0, $zero, bad_location_value
    slt     $t0, $v0, $t1
    beq     $t0, $zero, bad_location_value
    move    $a0, $v0    
    
    # read column
    li      $v0, READ_INT
    syscall

    la      $t1, board_attributes
    lw      $t1, 0($t1)

    slt     $t0, $v0, $zero
    bne     $t0, $zero, bad_location_value
    slt     $t0, $v0, $t1
    beq     $t0, $zero, bad_location_value
    move    $a1, $v0    

    # jump to set_cell_at_location and save position to $ra

    li      $a2, 65     # pass character to 'A' to set_cell_at_location 
    jal		set_cell_at_location
    bne     $v0, $zero, bad_location_value

    addi    $s0, $s0, -1
    j       get_points_loop_start

    get_attributes_done:

    lw		$ra, 0($sp)
    lw      $s0, 4($sp)
    addi    $sp, $sp, 8
    jr      $ra

    # if bad board value is detected, re-prompt
    bad_board_value:
    li      $v0, PRINT_STRING
    la      $a0, invalid_board_prompt
    syscall
    j       start_board_input              

    bad_generation_value:
    li      $v0, PRINT_STRING
    la      $a0, invalid_generations_prompt
    syscall
    j       start_generation_input         

    bad_cell_value:
    li      $v0, PRINT_STRING
    la      $a0, invalid_cells_prompt
    syscall
    j       start_cell_input  

    bad_location_value:
    li      $v0, PRINT_STRING
    la      $a0, invalid_point_prompt
    syscall
    li      $v0, EXIT
    syscall         


#   set_cell_at_location
#   
#   Takes a point, and sets it to a character
#   using formula (board_size * row_number) + row_number + col_num
#   arguments:  $a0 = row
#               $a1 = col
#               $a2 = character to place in
#   destroys:   $t0, $t1, $t2 
#   returns: $v0 = 0 if square was unoccupied, 1 otherwise
set_cell_at_location:

    la      $t0, board_attributes

    lw      $t1, 0($t0)         # $t1 contains the board_size
    mult	$t1, $a0		    # board_size * row_number
    mflo	$t1					# $t1 = board_size * row number

    add		$t1, $t1, $a0		
    add		$t1, $t1, $a1		# we now have index of the cell to be set
    
    la		$t0, cell_array
    add		$t0, $t0, $t1       # move cell_array ptr to appropriate position

    lb		$t1, 0($t0)		    #
    bne     $t1, $zero, bad_cell_location_return 
    
    sb      $a2, 0($t0)         # set matrix position at ($a0, $a1) to $a2
    li      $v0, 0
    jr      $ra

    bad_cell_location_return:
    li      $v0, 1
    jr      $ra


#   set_cell_buffer_location
#   
#   Takes a point, and sets it to a character
#   using formula (board_size * row_number) + row_number + col_num
#   arguments:  $a0 = row
#               $a1 = col
#               $a2 = character to place in
#   destroys:   $t0, $t1, $t2 
#   returns: nothing
set_cell_buffer_location:

    la      $t0, board_attributes

    lw      $t1, 0($t0)         # $t1 contains the board_size
    mult	$t1, $a0		    # board_size * row_number
    mflo	$t1					# $t1 = board_size * row number

    add		$t1, $t1, $a0		
    add		$t1, $t1, $a1		# we now have index of the cell to be set
    
    la		$t0, cell_array_buffer
    add		$t0, $t0, $t1       # move cell_array ptr to appropriate position
    
    sb      $a2, 0($t0)         # set matrix position at ($a0, $a1) to $a2
    jr      $ra



#   print_board
#
#   Using the attribute struct's board size, print out each row of the matrix
#   
#   arguments: 
#   $a0 = address of board to print (also $t0)
#   $a1 = the generation being printed (also $t1)
print_board:
    addi    $sp, $sp, 4
    sw      $ra, 0($sp)
    move    $t0, $a0     # preserve a0
    move    $t1, $a1     # preserve a1
    li      $v0, PRINT_STRING
    la	    $a0, generation_print_1
    syscall

    li      $v0, PRINT_INT
    move    $a0, $t1
    syscall

    li      $v0, PRINT_STRING
    la      $a0, generation_print_2
    syscall 

    la      $t2, board_attributes
    lw      $t2, 0($t2)             # t2 now contains board side size
    move    $a1, $t2

    print_board_header_start:

    la      $a0, plus_symbol
    syscall
    
    jal     print_dashes            # print the number of dashes stored in $a1

    la      $a0, plus_symbol
    syscall
    la      $a0, new_line
    syscall
    print_board_header_done:

    move    $t3, $zero
    print_board_print_row_loop_start:
    slt     $t4, $t3, $t2               # if $t3 is less than size, then continue
    beq     $t4, $zero, print_board_print_row_loop_done

    print_board_print_row_loop:
    # now to print each row, start with a bar
    la      $a0, bar_symbol
    syscall
    
    move    $t4, $t2
    mult    $t4, $t3
    mflo    $t4
    add     $t4, $t4, $t3
    add     $t4, $t4, $t0

    move    $a0, $t4
    li      $v0, PRINT_STRING
    syscall

    la      $a0, bar_symbol
    syscall
    la      $a0, new_line
    syscall

    addi    $t3, $t3, 1
    j print_board_print_row_loop_start

    print_board_print_row_loop_done:
    la      $a0, plus_symbol
    syscall
    move    $a1, $t2
    jal     print_dashes            # print the number of dashes stored in $a1

    la      $a0, plus_symbol
    syscall
    la      $a0, new_line
    syscall
    lw      $ra, 0($sp)
    addi    $sp, $sp, -4
    jr      $ra

#   print_dashes()
#
#   arguments:
#   $a1 : number of dashes to print
print_dashes:
    addi    $sp, $sp, 4
    sw      $ra, 0($sp)
    la      $a0, dash_symbol

    print_dashes_loop_start:
    beq     $a1, $zero, print_dashes_loop_done
    # for (i = board_size; i != 0; i--)
    syscall
    addi    $a1, $a1, -1
    j print_dashes_loop_start

    print_dashes_loop_done:
    lw      $ra, 0($sp)
    addi    $sp, $sp, -4
    jr      $ra


#   set_dead_cells_to_space()
#   
#   This function takes a board and sets all of
#   the null non-alive cells to whitespace.
#
#   arguments: $a0 = address of the board to set
#   returns: n/a
set_dead_cells_to_space:
	addi	$sp, $sp, -28
	sw	    $ra, 24($sp)
    sw      $a0, 20($sp)
    sw      $s4, 16($sp)
	sw	    $s3, 12($sp)
	sw	    $s2, 8($sp)
	sw	    $s1, 4($sp)
	sw	    $s0, 0($sp)

    la      $s0, board_attributes
    lw      $s0, 0($s0)                                  # get size of board
    move    $s1, $zero                                   # $s1 = 0, used for counter

    set_dead_cells_row_loop_start:                       # $s1 = counter
    slt     $t0, $s1, $s0                                # is counter < board_size?
    beq     $t0, $zero, set_dead_cells_row_loop_done     # for (int i = 0; i < board_size; i++){

    mult    $s0, $s1                                     # 
    mflo    $s2                                          #
    add     $s2, $s2, $s1                                # $s2 = (board_size * row_number) + row_number

    move    $s3, $zero                                   # $s3 = column loop counter
    set_dead_cells_column_loop_start:
    slt     $t0, $s3, $s0
    beq     $t0, $zero, set_dead_cells_column_loop_done
    add     $s4, $s2, $s3                                # $s4 = index of cell_array
    

    # do stuff here with correct index of cell_array
    move    $a1, $s1
    move    $a2, $s3

    lw      $a0, 20($sp)
    jal     check_space
    li      $t0, 2
    beq     $v0, $t0, set_dead_cells_alive_cell_detected
    li      $t0, 32

    lw      $a0, 20($sp)
    add     $t1, $a0, $s2
    add     $t1, $t1, $s3
    sb      $t0, 0($t1)

    set_dead_cells_alive_cell_detected:
    # do nothing

    addi    $s3, $s3, 1
    j       set_dead_cells_column_loop_start

    set_dead_cells_column_loop_done:

    addi    $s1, $s1, 1
    j       set_dead_cells_row_loop_start


    set_dead_cells_row_loop_done:
    
    lw	    $ra, 24($sp)
    lw      $a0, 20($sp)
    lw      $s4, 16($sp)
	lw	    $s3, 12($sp)
	lw	    $s2, 8($sp)
	lw	    $s1, 4($sp)
	lw	    $s0, 0($sp)
    addi    $sp, $sp, 28
    jr      $ra


#   check_space()
#
#   This function checks if a cell is null, dead, or alive.
#
#   arguments: 
#   $a0 = address of cell array
#   $a1 = row
#   $a2 = column
#
#   This is a leaf function.
#   
#   return values:
#   $v0 = 0 if null, 1 if dead, 2 if alive.
check_space:
    addi    $sp, $sp, -16
    sw      $ra, 12($sp)
    sw      $a0, 8($sp)
    sw      $a1, 4($sp)
    sw      $a2, 0($sp)

    la      $t0, board_attributes
    lw      $t0, 0($t0)

    mult    $t0, $a1
    mflo    $t0

    add     $t0, $t0, $a1
    add     $t0, $t0, $a2

    add     $a0, $a0, $t0
    lb      $t1, 0($a0)       #$t1 now contains value at index ($a1, $a2)

    beq     $t1, $zero, check_space_return_zero
    li      $t2, 32
    beq     $t1, $t2, check_space_return_one
    j       check_space_return_two

    check_space_return_zero:
    lw      $ra, 12($sp)
    lw      $a0, 8($sp)
    lw      $a1, 4($sp)
    lw      $a2, 0($sp)
    addi    $sp, $sp, 16
    li      $v0, 0
    jr      $ra

    check_space_return_one:
    lw      $ra, 12($sp)
    lw      $a0, 8($sp)
    lw      $a1, 4($sp)
    lw      $a2, 0($sp)
    addi    $sp, $sp, 16
    li      $v0, 1
    jr      $ra

    check_space_return_two:
    lw      $ra, 12($sp)
    lw      $a0, 8($sp)
    lw      $a1, 4($sp)
    lw      $a2, 0($sp)
    addi    $sp, $sp, 16
    li      $v0, 2
    jr      $ra


#   simulate()
#
#   The big function in this program, simulates the rules of
#   Conway's Game of Life.
#
#   We assume that the cell array buffer has been cleared
#   BEFORE the simulate function is called.
#
#   arguments:
#   $a0 = address of original cell array
#   $a1 = address of cell array buffer
#
#   return:
#   none, but the cell array buffer ages by one.
simulate:
    addi        $sp, $sp, -12
    sw          $ra, 8($sp)
    sw          $s1, 4($sp)
    sw          $s3, 0($sp)

    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  #$t0 contains the board side length
    # for each row and column...
    move        $s1, $zero                                   # $s1 = 0, used for counter

    simulate_row_loop_start:                                 # $s1 = counter

    slt         $t0, $s1, $t1                                # is counter < board_size?
    beq         $t0, $zero, simulate_row_loop_done           # for (int i = 0; i < board_size; i++){

    move        $s3, $zero                                   # $s3 = column loop counter
    simulate_column_loop_start:
    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  #$t0 contains the board side length

    slt         $t0, $s3, $t1                                # is column counter less than side length?
    beq         $t0, $zero, simulate_column_loop_done

    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  # $t0 contains the board side length
    mult        $t1, $s1
    mflo        $t0
    add         $t0, $t0, $s1                                # $t0 = index of cell_array
    add         $t0, $t0, $s3

    # do stuff here with correct index of cell_array         #

    # TODO: Count Neighbors
    # if neighbor < 2, set to whitespace
    # if neighbor > 3, set to whitespace
    # if cell is dead, becomes alive iff neighbor == 3
    # else, increase age by one

    move        $a0, $s1
    move        $a1, $s3
    jal         count_neighbors
    
    li          $t0, 2
    slt         $t0, $v0, $t0                                # $t0 = is the quantity < 2?
    bne         $t0, $zero, simulate_kill_cell

    li          $t0, 4
    slt         $t0, $v0, $t0                                # $t0 = is the quantity < 4?
    beq         $t0, $zero, simulate_kill_cell               # $t0 = 1 if $v0 < 3, so if not less than 3, kill

    move        $t1, $v0                                     # preserve count_neighbors in $t1

#   This function checks if a cell is null, dead, or alive.
#   return values:
#   $v0 = 0 if null, 1 if dead, 2 if alive.
    la          $a0, cell_array
    move        $a1, $s1
    move        $a2, $s3
    jal         check_space

    li          $t2, 2                                       # if neighbors is between 2 and 3, and cell is alive, age it 
    beq         $v0, $t2, simulate_age_cell

    # if we get here, the cell is dead (or null, somehow), but the neighbor is either 2 or 3.

    move        $a0, $s1
    move        $a1, $s3
    jal         count_neighbors
    li          $t2, 3
    beq         $v0, $t2, simulate_generate_cell             # generate cell if $t1 (neighbor_count) == 3

    # if we get here, the cell is dead, and the neighbor count is 2. We can leave.
    j           simulate_cell_done


    simulate_kill_cell:
#   set_cell_buffer_location
#   arguments:  $a0 = row
#               $a1 = col
#               $a2 = character to place in
#   destroys:   $t0, $t1, $t2 
#   returns: $v0 = 0 if square was unoccupied, 1 otherwise

    move        $a0, $s1
    move        $a1, $s3
    li          $a2, 32
    jal         set_cell_buffer_location

    j           simulate_cell_done

    simulate_age_cell:

    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  # $t0 contains the board side length
    mult        $t1, $s1
    mflo        $t0
    la          $t1, cell_array
    add         $t0, $t0, $s1                                # $t0 = index of cell_array
    add         $t0, $t0, $s3
    add         $t4, $t1, $t0                                # $t1 = address of cell_array
    lb          $t5, 0($t4)                                  # $t4 = character at array
    addi        $t5, $t5, 1

    move        $a0, $s1
    move        $a1, $s3
    move        $a2, $t5
    jal         set_cell_buffer_location

    j           simulate_cell_done         

    simulate_generate_cell:
    #set_cell_at_location
    move        $a0, $s1
    move        $a1, $s3
    li          $a2, 65
    jal         set_cell_buffer_location

    j         simulate_cell_done

    simulate_cell_done:

    # do stuff here with correct index of cell_array         #
    addi        $s3, $s3, 1
    j           simulate_column_loop_start

    simulate_column_loop_done:

    addi        $s1, $s1, 1
    j           simulate_row_loop_start

    simulate_row_loop_done:
    lw          $ra, 8($sp)
    lw          $s1, 4($sp)
    lw          $s3, 0($sp)
    addi        $sp, $sp, 12

    jr          $ra



#   count_neighbors()
#
#   This function counts the neighbors in cell_array
#   given the row/col indices
#
#   Arguments:
#   $a0 = row index
#   $a1 = column index
#
#   Return Values
#   $v0 = number of neighbors
count_neighbors:
    addi    $sp, $sp, -12
    sw      $ra, 8($sp)
    sw      $a1, 4($sp)
    sw      $a0, 0($sp)

    la      $t0, board_attributes
    lw      $t0, 0($t0)

    move    $t8, $zero

    count_neighbors_get_top_left:
    lw      $t1, 0($sp)     # $t1 now contains original row index
    addi    $t1, $t1, -1
    div     $t1, $t0        # remainder placed in mfhi
    mfhi    $t1             # $t1 now contains the top left row index
    slt     $t3, $t1, $zero
    beq     $t3, $zero, get_top_left_row_not_negative
    add     $t1, $t1, $t0
    
        get_top_left_row_not_negative:
    lw      $t2, 4($sp)     # $t2 now contains original column index
    addi    $t2, $t2, -1
    div     $t2, $t0
    mfhi    $t2             # $t2 now contains the top left column index
    slt     $t3, $t2, $zero
    beq     $t3, $zero, get_top_left_col_not_negative
    add     $t2, $t2, $t0
    
        get_top_left_col_not_negative:

#   arguments of check_space: 
#   $a0 = address of cell array
#   $a1 = row
#   $a2 = column
#   return values:
#   $v0 = 0 if null, 1 if dead, 2 if alive.
    la      $a0, cell_array
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_top
    addi    $t8, $t8, 1

    count_neighbors_get_top:
    la      $t0, board_attributes
    lw      $t0, 0($t0)
    lw      $t1, 0($sp)
    addi    $t1, $t1, -1
    div     $t1, $t0        # remainder placed in mfhi
    mfhi    $t1             # $t1 now contains the top row index
    slt     $t3, $t1, $zero
    beq     $t3, $zero, get_top_not_negative
    add     $t1, $t1, $t0
    
        get_top_not_negative:
    lw      $t2, 4($sp)     # $t2 now contains original column index        # $t2 now contains the col index (which remains the same)
    la      $a0, cell_array
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_top_right
    addi    $t8, $t8, 1

    count_neighbors_get_top_right:
    la      $t0, board_attributes
    lw      $t0, 0($t0)
    lw      $t1, 0($sp)
    addi    $t1, $t1, -1
    div     $t1, $t0        # remainder placed in mfhi
    mfhi    $t1             # $t1 now contains the top left row index
    slt     $t3, $t1, $zero
    beq     $t3, $zero, get_top_right_not_negative
    add     $t1, $t1, $t0
    
        get_top_right_not_negative:
    
    lw      $t2, 4($sp)     # $t2 now contains original column index
    addi    $t2, $t2, 1
    div     $t2, $t0
    mfhi    $t2             # $t2 now contains the top left column index

    la      $t4, cell_array
    move    $a0, $t4
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_left
    addi    $t8, $t8, 1

    count_neighbors_get_left:
    la      $t0, board_attributes
    lw      $t0, 0($t0)
    lw      $t1, 0($sp)
    
    lw      $t2, 4($sp)     # $t2 now contains original column index
    addi    $t2, $t2, -1
    div     $t2, $t0
    mfhi    $t2             # $t2 now contains the top left column index
    slt     $t3, $t2, $zero
    beq     $t3, $zero, get_left_not_negative
    add     $t2, $t2, $t0
    
        get_left_not_negative:

    la      $t4, cell_array
    move    $a0, $t4
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_right
    addi    $t8, $t8, 1

    count_neighbors_get_right:
    la      $t0, board_attributes
    lw      $t0, 0($t0)
    lw      $t1, 0($sp)
    
    lw      $t2, 4($sp)     # $t2 now contains original column index
    addi    $t2, $t2, 1
    div     $t2, $t0
    mfhi    $t2             # $t2 now contains the top left column index

    la      $t4, cell_array
    move    $a0, $t4
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_bottom_left
    addi    $t8, $t8, 1

    count_neighbors_get_bottom_left:
    la      $t0, board_attributes
    lw      $t0, 0($t0)
    lw      $t1, 0($sp)
    addi    $t1, $t1, 1
    div     $t1, $t0        # remainder placed in mfhi
    mfhi    $t1             # $t1 now contains the top left row index
    
    lw      $t2, 4($sp)     # $t2 now contains original column index
    addi    $t2, $t2, -1
    div     $t2, $t0
    mfhi    $t2             # $t2 now contains the top left column index
    slt     $t3, $t2, $zero
    beq     $t3, $zero, get_bottom_left_not_negative
    add     $t2, $t2, $t0
    
        get_bottom_left_not_negative:

    la      $t4, cell_array
    move    $a0, $t4
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_bottom
    addi    $t8, $t8, 1

    count_neighbors_get_bottom:
    la      $t0, board_attributes
    lw      $t0, 0($t0)     # $t0 is the board side length
    lw      $t1, 0($sp)     # $t1 is the original row index
    addi    $t1, $t1, 1
    div     $t1, $t0        # remainder placed in mfhi
    mfhi    $t1             # $t1 now contains the top left row index
    
    lw      $t2, 4($sp)     # $t2 now contains original column index

    la      $t4, cell_array
    move    $a0, $t4
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_get_bottom_right
    addi    $t8, $t8, 1

    count_neighbors_get_bottom_right:
    la      $t0, board_attributes
    lw      $t0, 0($t0)
    lw      $t1, 0($sp)
    addi    $t1, $t1, 1
    div     $t1, $t0        # remainder placed in mfhi
    mfhi    $t1             # $t1 now contains the top left row index
    
    lw      $t2, 4($sp)     # $t2 now contains original column index
    addi    $t2, $t2, 1
    div     $t2, $t0
    mfhi    $t2             # $t2 now contains the top left column index

    la      $t4, cell_array
    move    $a0, $t4
    move    $a1, $t1
    move    $a2, $t2
    jal     check_space
    li      $t7, 2
    bne     $v0, $t7, count_neighbors_done
    addi    $t8, $t8, 1

    count_neighbors_done:
    move    $v0, $t8
    lw      $ra, 8($sp)
    lw      $a1, 4($sp)
    lw      $a0, 0($sp)
    addi    $sp, $sp, 12

    jr      $ra


#   copy_cell_array()
#
#   This function takes copies the array in $a0 into $a1
#   The array is 930 bytes and contains null terminators,
#   so size is the only way to do it.
#
#   This is a leaf function.
#
#   arguments:
#   $a0 = cell_array to be copied
#   $a1 = cell_array_buffer to be copied to
copy_cell_array:
    move        $t0, $zero
    li          $t1, 930

    copy_array_loop_start:
    slt         $t2, $t0, $t1
    beq         $t0, $t1, copy_array_loop_done
    lb          $t3, 0($a0)                         # dereference value at array1[i]
    sb          $t3, 0($a1)                         # store it in array[i]    

    addi        $a0, $a0, 1                         # increment pointers by one
    addi        $a1, $a1, 1

    addi        $t0, $t0, 1 
    j copy_array_loop_start
    copy_array_loop_done:

    jr          $ra



#   clear_cell_array()
#
#   arguments:
#   $a0 = address of cell array to be cleared
#
clear_cell_array:
    addi        $sp, $sp, -8
    sw          $s1, 4($sp)
    sw          $s3, 0($sp)

    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  #$t0 contains the board side length
    # for each row and column...
    move        $s1, $zero                                   # $s1 = 0, used for counter

    clear_cell_array_row_loop_start:                                 # $s1 = counter

    slt         $t0, $s1, $t1                                # is counter < board_size?
    beq         $t0, $zero, clear_cell_array_row_loop_done           # for (int i = 0; i < board_size; i++){

    move        $s3, $zero                                   # $s3 = column loop counter
    clear_cell_array_column_loop_start:
    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  #$t0 contains the board side length

    slt         $t0, $s3, $t1                                # is column counter less than side length?
    beq         $t0, $zero, clear_cell_array_column_loop_done

    la          $t1, board_attributes
    lw          $t1, 0($t1)                                  # $t0 contains the board side length
    mult        $t1, $s1
    mflo        $t0
    add         $t0, $t0, $s1                                # $t0 = index of cell_array
    add         $t0, $t0, $s3

    # do stuff here with correct index of cell_array         #
    move        $t5, $a0
    add         $t5, $t5, $t0
    li          $t6, 32
    sb          $t6, 0($t5)

    # do stuff here with correct index of cell_array         #
    addi        $s3, $s3, 1
    j           clear_cell_array_column_loop_start

    clear_cell_array_column_loop_done:

    addi        $s1, $s1, 1
    j           clear_cell_array_row_loop_start

    clear_cell_array_row_loop_done:
    lw          $s1, 4($sp)
    lw          $s3, 0($sp)
    addi        $sp, $sp, 8

    jr          $ra

    .globl main
#   main 
#
#   Calls get_attributes(), stores it in a data structure
#   Calls the simulate function and passes the address of
#   the data structure to it
main:
    li      $v0, PRINT_STRING
    la      $a0, banner_string

    syscall

    jal     get_attributes

    la      $a0, cell_array
    jal     set_dead_cells_to_space

    la      $a0, cell_array_buffer
    jal     set_dead_cells_to_space

    # print out the initial board
    li      $v0, PRINT_STRING
    la		$a0, cell_array
    li      $a1, 0
    jal     print_board

    # testing count_neighbors
    #   Arguments:
#   $a0 = row index
#   $a1 = column index
#
#   Return Values
#   $v0 = number of neighbors

    #li  $a0, 0
    #li  $a1, 0
    #jal count_neighbors

    # testing count neighbors

    la      $s5, board_attributes
    lw      $s5, 4($s5)                 # $t0 contains the number of generations
    move    $s6, $zero

    # print every generation thereafter

    # testing cell_array clear()
    #la      $a0, cell_array
    #jal     clear_cell_array


    generation_loop_start:
    slt     $t2, $s6, $s5
    beq     $t2, $zero, main_generation_loop_done

    # simulate, which places simulated board into buffer
    # then, copy buffer into original array
    la      $a0, cell_array
    la      $a1, cell_array_buffer

    jal     simulate

    la      $a0, cell_array_buffer
    la      $a1, cell_array
    jal     copy_cell_array

    la      $a0, cell_array
    addi    $a1, $s6, 1 
    jal     print_board

    addi    $s6, $s6, 1
    j generation_loop_start
    main_generation_loop_done:
    

    li      $v0, EXIT
    syscall
