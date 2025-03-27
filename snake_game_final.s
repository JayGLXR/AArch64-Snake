// snake_game_final.s - Two-player snake game with multiple food items
// Assemble with: as -arch arm64 snake_game_final.s -o snake_game_final.o
// Link with: ld -o snake_game_final snake_game_final.o -lSystem -syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -e _main -arch arm64

// Game Constants
.equ WIDTH, 30
.equ HEIGHT, 20
.equ SNAKE_LEN, 5         // Increased initial snake length from 3 to 5
.equ MAX_BODY, 20         // Maximum body segments per snake
.equ MAX_FOOD, 8          // Increased number of food items from 5 to 8

// Characters
.equ CHAR_EMPTY, '.'
.equ CHAR_FOOD, 'F'
.equ CHAR_SNAKE1_HEAD, '1'
.equ CHAR_SNAKE1_BODY, '@'
.equ CHAR_SNAKE2_HEAD, '2'
.equ CHAR_SNAKE2_BODY, '@'
.equ CHAR_WALL, '#'

// Direction values
.equ DIR_UP, 0
.equ DIR_RIGHT, 1
.equ DIR_DOWN, 2
.equ DIR_LEFT, 3

.data
.align 3
title: .asciz "ARM64 Snake Competition\n"
score_msg: .asciz "Snake 1: %d  Snake 2: %d\n"
buffer: .space (WIDTH + 3) * (HEIGHT + 3)   // Board buffer

// Snake 1 data
s1_head_x: .word 5         // X position
s1_head_y: .word 5         // Y position
s1_dir: .word DIR_RIGHT    // Direction
s1_score: .word 0          // Score
s1_length: .word SNAKE_LEN // Current length
s1_body_x: .space MAX_BODY * 4  // Body segment X positions
s1_body_y: .space MAX_BODY * 4  // Body segment Y positions

// Snake 2 data
s2_head_x: .word WIDTH-6   // X position
s2_head_y: .word HEIGHT-6  // Y position
s2_dir: .word DIR_LEFT     // Direction
s2_score: .word 0          // Score
s2_length: .word SNAKE_LEN // Current length
s2_body_x: .space MAX_BODY * 4  // Body segment X positions
s2_body_y: .space MAX_BODY * 4  // Body segment Y positions

// Food data (8 food items)
food_x: .space MAX_FOOD * 4  // X positions (4 bytes each)
food_y: .space MAX_FOOD * 4  // Y positions

// Direction arrays
dx: .word 0, 1, 0, -1    // dx for Direction: Up, Right, Down, Left
dy: .word -1, 0, 1, 0    // dy for Direction: Up, Right, Down, Left

.text
.globl _main
_main:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!   // Save registers for loop counter
    mov x29, sp
    
    // Initialize snake bodies
    bl _init_snakes
    
    // Initialize food positions
    bl _init_food
    
    // Game loop
    mov w19, #0          // Step counter
_game_loop:
    // Clear screen with newlines for simplicity
    mov w0, #'\n'
    bl _putchar
    mov w0, #'\n'
    bl _putchar
    
    // Print score
    adrp x0, score_msg@PAGE
    add x0, x0, score_msg@PAGEOFF
    
    adrp x1, s1_score@PAGE
    add x1, x1, s1_score@PAGEOFF
    ldr w1, [x1]
    
    adrp x2, s2_score@PAGE
    add x2, x2, s2_score@PAGEOFF
    ldr w2, [x2]
    bl _printf
    
    // Update snakes
    bl _update_snake1
    bl _update_snake2
    
    // Check for food
    bl _check_food
    
    // Render board
    bl _render_board
    
    // Delay (200ms)
    mov w0, #200
    mov w1, #1000
    mul w0, w0, w1      // 200ms in microseconds
    bl _usleep
    
    // Loop control
    add w19, w19, #1
    cmp w19, #100      // Run for 100 steps max
    b.lt _game_loop
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Initialize snake bodies
_init_snakes:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    mov x29, sp
    
    // Initialize Snake 1 body
    adrp x19, s1_body_x@PAGE
    add x19, x19, s1_body_x@PAGEOFF
    adrp x20, s1_body_y@PAGE
    add x20, x20, s1_body_y@PAGEOFF
    
    // Get initial head position
    adrp x0, s1_head_x@PAGE
    add x0, x0, s1_head_x@PAGEOFF
    ldr w1, [x0]           // head_x
    
    adrp x0, s1_head_y@PAGE
    add x0, x0, s1_head_y@PAGEOFF
    ldr w2, [x0]           // head_y
    
    // Place body segments leftward from head
    mov w0, #0             // Body segment index
_init_s1_loop:
    cmp w0, #SNAKE_LEN
    b.ge _init_s2_start
    
    // Compute position: right-to-left from head
    sub w3, w1, w0         // x = head_x - i
    
    // Store position
    str w3, [x19, w0, SXTW #2]  // body_x[i] = x
    str w2, [x20, w0, SXTW #2]  // body_y[i] = head_y
    
    add w0, w0, #1         // Next segment
    b _init_s1_loop
    
_init_s2_start:
    // Initialize Snake 2 body
    adrp x19, s2_body_x@PAGE
    add x19, x19, s2_body_x@PAGEOFF
    adrp x20, s2_body_y@PAGE
    add x20, x20, s2_body_y@PAGEOFF
    
    // Get initial head position
    adrp x0, s2_head_x@PAGE
    add x0, x0, s2_head_x@PAGEOFF
    ldr w1, [x0]           // head_x
    
    adrp x0, s2_head_y@PAGE
    add x0, x0, s2_head_y@PAGEOFF
    ldr w2, [x0]           // head_y
    
    // Place body segments rightward from head
    mov w0, #0             // Body segment index
_init_s2_loop:
    cmp w0, #SNAKE_LEN
    b.ge _init_snakes_done
    
    // Compute position: left-to-right from head
    add w3, w1, w0         // x = head_x + i
    
    // Store position
    str w3, [x19, w0, SXTW #2]  // body_x[i] = x
    str w2, [x20, w0, SXTW #2]  // body_y[i] = head_y
    
    add w0, w0, #1         // Next segment
    b _init_s2_loop
    
_init_snakes_done:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Initialize food at random positions
_init_food:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    mov x29, sp
    
    // Get base addresses for food arrays
    adrp x19, food_x@PAGE
    add x19, x19, food_x@PAGEOFF
    adrp x20, food_y@PAGE
    add x20, x20, food_y@PAGEOFF
    
    // Place MAX_FOOD food items
    mov w21, #0          // Counter
_init_food_loop:
    cmp w21, #MAX_FOOD
    b.ge _init_food_done
    
    // Calculate positions to spread food across the board
    // X position: divide board into sections
    mov w22, #WIDTH
    sub w22, w22, #4     // WIDTH-4 to avoid edges
    mul w23, w21, w22    // Multiply by section size
    mov w24, #MAX_FOOD   // Load divisor into register
    udiv w23, w23, w24   // Divide by number of food items
    add w23, w23, #2     // Add offset to avoid edges
    str w23, [x19, w21, SXTW #2]  // Store in food_x[i]
    
    // Y position: alternate between top and bottom half
    mov w22, #HEIGHT
    sub w22, w22, #4     // HEIGHT-4 to avoid edges
    and w23, w21, #1     // Get least significant bit (0 or 1)
    mul w23, w23, w22    // Multiply by half board height
    add w23, w23, #2     // Add offset to avoid edges
    str w23, [x20, w21, SXTW #2]  // Store in food_y[i]
    
    add w21, w21, #1      // Next food item
    b _init_food_loop
    
_init_food_done:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Update snake 1 position
_update_snake1:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    mov x29, sp
    
    // Load current position and direction
    adrp x0, s1_head_x@PAGE
    add x0, x0, s1_head_x@PAGEOFF
    ldr w1, [x0]         // w1 = head_x
    
    adrp x0, s1_head_y@PAGE
    add x0, x0, s1_head_y@PAGEOFF
    ldr w2, [x0]         // w2 = head_y
    
    adrp x0, s1_dir@PAGE
    add x0, x0, s1_dir@PAGEOFF
    ldr w3, [x0]         // w3 = direction
    
    // Change direction occasionally (just to make snake move interestingly)
    mov w4, #5           // Change every 5 steps
    udiv w5, w19, w4     // w5 = step / 5
    msub w6, w5, w4, w19 // w6 = step % 5
    
    cbnz w6, _s1_no_change
    
    // Occasional direction change based on step count
    add w3, w3, #1       // Next direction
    cmp w3, #4
    b.lt _s1_dir_ok
    mov w3, #0           // Reset to UP
_s1_dir_ok:
    str w3, [x0]         // Save new direction
    
_s1_no_change:
    // Calculate new position based on direction
    adrp x0, dx@PAGE
    add x0, x0, dx@PAGEOFF
    ldr w4, [x0, w3, SXTW #2]   // w4 = dx[dir]
    
    adrp x0, dy@PAGE
    add x0, x0, dy@PAGEOFF
    ldr w5, [x0, w3, SXTW #2]   // w5 = dy[dir]
    
    add w1, w1, w4       // new_x = x + dx
    add w2, w2, w5       // new_y = y + dy
    
    // Boundary wrapping
    cmp w1, #0
    b.ge 1f
    mov w1, #WIDTH-1      // Wrap to right edge
1:  cmp w1, #WIDTH
    b.lt 2f
    mov w1, #0            // Wrap to left edge
    
2:  cmp w2, #0
    b.ge 3f
    mov w2, #HEIGHT-1     // Wrap to bottom
3:  cmp w2, #HEIGHT
    b.lt 4f
    mov w2, #0            // Wrap to top
4:  // Label for boundary wrapping
    
    // Before updating head position, move body segments
    adrp x19, s1_body_x@PAGE
    add x19, x19, s1_body_x@PAGEOFF
    adrp x20, s1_body_y@PAGE
    add x20, x20, s1_body_y@PAGEOFF
    
    // Get current length
    adrp x0, s1_length@PAGE
    add x0, x0, s1_length@PAGEOFF
    ldr w12, [x0]        // w12 = length
    
    // Start from the tail (last segment) and move toward the head
    sub w11, w12, #1     // w11 = index of last segment
_s1_move_body_loop:
    cmp w11, #0
    b.le _s1_move_body_done
    
    // Move each segment to the position of the segment ahead of it
    sub w10, w11, #1     // Index of next segment toward head
    
    // Load position of segment ahead
    ldr w8, [x19, w10, SXTW #2]  // x of segment ahead
    ldr w9, [x20, w10, SXTW #2]  // y of segment ahead
    
    // Update current segment position
    str w8, [x19, w11, SXTW #2]  // body_x[i] = body_x[i-1]
    str w9, [x20, w11, SXTW #2]  // body_y[i] = body_y[i-1]
    
    sub w11, w11, #1     // Move to next segment toward head
    b _s1_move_body_loop
    
_s1_move_body_done:
    // Update first body segment to current head position
    str w1, [x19, #0]    // body_x[0] = current head_x
    str w2, [x20, #0]    // body_y[0] = current head_y
    
    // Update head position
    adrp x0, s1_head_x@PAGE
    add x0, x0, s1_head_x@PAGEOFF
    str w1, [x0]          // Update head_x
    
    adrp x0, s1_head_y@PAGE
    add x0, x0, s1_head_y@PAGEOFF
    str w2, [x0]          // Update head_y
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Update snake 2 position
_update_snake2:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    mov x29, sp
    
    // Load current position and direction
    adrp x0, s2_head_x@PAGE
    add x0, x0, s2_head_x@PAGEOFF
    ldr w1, [x0]         // w1 = head_x
    
    adrp x0, s2_head_y@PAGE
    add x0, x0, s2_head_y@PAGEOFF
    ldr w2, [x0]         // w2 = head_y
    
    adrp x0, s2_dir@PAGE
    add x0, x0, s2_dir@PAGEOFF
    ldr w3, [x0]         // w3 = direction
    
    // Change direction occasionally
    mov w4, #7           // Change every 7 steps
    udiv w5, w19, w4     // w5 = step / 7
    msub w6, w5, w4, w19 // w6 = step % 7
    
    cbnz w6, _s2_no_change
    
    // Different direction change pattern
    sub w3, w3, #1       // Previous direction
    cmp w3, #0
    b.ge _s2_dir_ok
    mov w3, #3           // Wrap to LEFT
_s2_dir_ok:
    str w3, [x0]         // Save new direction
    
_s2_no_change:
    // Calculate new position based on direction
    adrp x0, dx@PAGE
    add x0, x0, dx@PAGEOFF
    ldr w4, [x0, w3, SXTW #2]   // w4 = dx[dir]
    
    adrp x0, dy@PAGE
    add x0, x0, dy@PAGEOFF
    ldr w5, [x0, w3, SXTW #2]   // w5 = dy[dir]
    
    add w1, w1, w4       // new_x = x + dx
    add w2, w2, w5       // new_y = y + dy
    
    // Boundary wrapping - same as snake 1
    cmp w1, #0
    b.ge 1f
    mov w1, #WIDTH-1
1:  cmp w1, #WIDTH
    b.lt 2f
    mov w1, #0
    
2:  cmp w2, #0
    b.ge 3f
    mov w2, #HEIGHT-1
3:  cmp w2, #HEIGHT
    b.lt 4f
    mov w2, #0
4:  // Label for boundary wrapping
    
    // Before updating head position, move body segments
    adrp x19, s2_body_x@PAGE
    add x19, x19, s2_body_x@PAGEOFF
    adrp x20, s2_body_y@PAGE
    add x20, x20, s2_body_y@PAGEOFF
    
    // Get current length
    adrp x0, s2_length@PAGE
    add x0, x0, s2_length@PAGEOFF
    ldr w12, [x0]        // w12 = length
    
    // Start from the tail (last segment) and move toward the head
    sub w11, w12, #1     // w11 = index of last segment
_s2_move_body_loop:
    cmp w11, #0
    b.le _s2_move_body_done
    
    // Move each segment to the position of the segment ahead of it
    sub w10, w11, #1     // Index of next segment toward head
    
    // Load position of segment ahead
    ldr w8, [x19, w10, SXTW #2]  // x of segment ahead
    ldr w9, [x20, w10, SXTW #2]  // y of segment ahead
    
    // Update current segment position
    str w8, [x19, w11, SXTW #2]  // body_x[i] = body_x[i-1]
    str w9, [x20, w11, SXTW #2]  // body_y[i] = body_y[i-1]
    
    sub w11, w11, #1     // Move to next segment toward head
    b _s2_move_body_loop
    
_s2_move_body_done:
    // Update first body segment to current head position
    str w1, [x19, #0]    // body_x[0] = current head_x
    str w2, [x20, #0]    // body_y[0] = current head_y
    
    // Update head position
    adrp x0, s2_head_x@PAGE
    add x0, x0, s2_head_x@PAGEOFF
    str w1, [x0]          // Update head_x
    
    adrp x0, s2_head_y@PAGE
    add x0, x0, s2_head_y@PAGEOFF
    str w2, [x0]          // Update head_y
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Check if snakes have eaten food
_check_food:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    mov x29, sp
    
    // Get snake head positions
    adrp x0, s1_head_x@PAGE
    add x0, x0, s1_head_x@PAGEOFF
    ldr w19, [x0]        // w19 = s1_head_x
    
    adrp x0, s1_head_y@PAGE
    add x0, x0, s1_head_y@PAGEOFF
    ldr w20, [x0]        // w20 = s1_head_y
    
    adrp x0, s2_head_x@PAGE
    add x0, x0, s2_head_x@PAGEOFF
    ldr w21, [x0]        // w21 = s2_head_x
    
    adrp x0, s2_head_y@PAGE
    add x0, x0, s2_head_y@PAGEOFF
    ldr w22, [x0]        // w22 = s2_head_y
    
    // Get food array base addresses
    adrp x9, food_x@PAGE
    add x9, x9, food_x@PAGEOFF
    adrp x10, food_y@PAGE
    add x10, x10, food_y@PAGEOFF
    
    // Check each food item
    mov w11, #0          // Food index
_check_food_loop:
    cmp w11, #MAX_FOOD
    b.ge _check_food_done
    
    // Get food position
    ldr w12, [x9, w11, SXTW #2]  // food_x[i]
    ldr w13, [x10, w11, SXTW #2] // food_y[i]
    
    // If food position is (-1,-1), it's already eaten
    cmn w12, #1
    b.eq _next_food
    
    // Check if snake 1 ate this food
    cmp w19, w12
    b.ne _check_s2_food
    cmp w20, w13
    b.ne _check_s2_food
    
    // Snake 1 ate food! Increment score
    adrp x0, s1_score@PAGE
    add x0, x0, s1_score@PAGEOFF
    ldr w1, [x0]
    add w1, w1, #1
    str w1, [x0]
    
    // Mark food as eaten by setting to (-1,-1)
    mov w1, #-1
    str w1, [x9, w11, SXTW #2]  // food_x[i] = -1
    str w1, [x10, w11, SXTW #2] // food_y[i] = -1
    
    // Place a new food item (reuse this index)
    bl _place_new_food_item
    
    // When snake eats food, increase its length (if not already at max)
    adrp x0, s1_length@PAGE
    add x0, x0, s1_length@PAGEOFF
    ldr w1, [x0]
    cmp w1, #MAX_BODY
    b.ge _dont_grow_s1    // Skip if already at max length
    add w1, w1, #1        // Increase length
    str w1, [x0]          // Save new length
_dont_grow_s1:
    
    b _next_food
    
_check_s2_food:
    // Check if snake 2 ate this food
    cmp w21, w12
    b.ne _next_food
    cmp w22, w13
    b.ne _next_food
    
    // Snake 2 ate food! Increment score
    adrp x0, s2_score@PAGE
    add x0, x0, s2_score@PAGEOFF
    ldr w1, [x0]
    add w1, w1, #1
    str w1, [x0]
    
    // Mark food as eaten by setting to (-1,-1)
    mov w1, #-1
    str w1, [x9, w11, SXTW #2]  // food_x[i] = -1
    str w1, [x10, w11, SXTW #2] // food_y[i] = -1
    
    // Place a new food item (reuse this index)
    bl _place_new_food_item
    
    // When snake eats food, increase its length (if not already at max)
    adrp x0, s2_length@PAGE
    add x0, x0, s2_length@PAGEOFF
    ldr w1, [x0]
    cmp w1, #MAX_BODY
    b.ge _dont_grow_s2    // Skip if already at max length
    add w1, w1, #1        // Increase length
    str w1, [x0]          // Save new length
_dont_grow_s2:
    
_next_food:
    add w11, w11, #1     // Next food item
    b _check_food_loop
    
_check_food_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// Place a new food item at a random position
_place_new_food_item:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Use step counter for pseudo-random position
    add w1, w11, w19    // Combine step + food index
    lsl w1, w1, #3      // Shift left for more variation
    
    // X position - spread across board width
    mov w3, #WIDTH
    sub w3, w3, #4        // WIDTH-4 to avoid edges
    and w2, w1, w3        // Modulo (WIDTH-4)
    add w2, w2, #2        // Add offset to avoid edges
    str w2, [x9, w11, SXTW #2]  // Store at food_x[index]
    
    // Y position - alternate between top and bottom
    lsr w1, w1, #3        // Shift for different Y value
    mov w3, #HEIGHT
    sub w3, w3, #4        // HEIGHT-4 to avoid edges
    and w2, w1, #1        // Get least significant bit
    mul w2, w2, w3        // Multiply by half board height
    add w2, w2, #2        // Add offset to avoid edges
    str w2, [x10, w11, SXTW #2] // Store at food_y[index]
    
    ldp x29, x30, [sp], #16
    ret

// Render the game board
_render_board:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    mov x29, sp
    
    // Get buffer pointer
    adrp x21, buffer@PAGE
    add x21, x21, buffer@PAGEOFF
    mov x22, x21        // Save start of buffer
    
    // Get snake head positions
    adrp x0, s1_head_x@PAGE
    add x0, x0, s1_head_x@PAGEOFF
    ldr w3, [x0]        // w3 = s1_head_x
    
    adrp x0, s1_head_y@PAGE
    add x0, x0, s1_head_y@PAGEOFF
    ldr w4, [x0]        // w4 = s1_head_y
    
    adrp x0, s2_head_x@PAGE
    add x0, x0, s2_head_x@PAGEOFF
    ldr w5, [x0]        // w5 = s2_head_x
    
    adrp x0, s2_head_y@PAGE
    add x0, x0, s2_head_y@PAGEOFF
    ldr w6, [x0]        // w6 = s2_head_y
    
    // Get food array pointers
    adrp x9, food_x@PAGE
    add x9, x9, food_x@PAGEOFF
    adrp x10, food_y@PAGE
    add x10, x10, food_y@PAGEOFF
    
    // Draw top border
    mov w0, #CHAR_WALL
    mov w1, #0
_top_border_loop:
    cmp w1, #WIDTH+2
    b.ge _top_border_done
    
    strb w0, [x21], #1   // Store '#' and advance pointer
    add w1, w1, #1
    b _top_border_loop
_top_border_done:
    mov w0, #'\n'
    strb w0, [x21], #1   // Add newline
    
    // Draw rows
    mov w19, #0          // y = 0
_row_loop:
    cmp w19, #HEIGHT
    b.ge _row_loop_done
    
    // Draw left wall
    mov w0, #CHAR_WALL
    strb w0, [x21], #1
    
    // Draw cells in row
    mov w20, #0         // x = 0
_col_loop:
    cmp w20, #WIDTH
    b.ge _col_loop_done
    
    // Check cell content in priority order:
    // 1. Snake 1 head
    cmp w20, w3
    b.ne _check_s2_head
    cmp w19, w4
    b.ne _check_s2_head
    
    mov w0, #CHAR_SNAKE1_HEAD
    b _draw_cell
    
_check_s2_head:
    // 2. Snake 2 head
    cmp w20, w5
    b.ne _check_s1_body
    cmp w19, w6
    b.ne _check_s1_body
    
    mov w0, #CHAR_SNAKE2_HEAD
    b _draw_cell
    
_check_s1_body:
    // 3. Check for Snake 1 body segments
    adrp x13, s1_body_x@PAGE
    add x13, x13, s1_body_x@PAGEOFF
    adrp x14, s1_body_y@PAGE
    add x14, x14, s1_body_y@PAGEOFF
    
    adrp x15, s1_length@PAGE
    add x15, x15, s1_length@PAGEOFF
    ldr w15, [x15]       // w15 = s1_length
    
    mov w7, #0           // Body segment index counter
_s1_body_loop:
    cmp w7, w15          // Check all segments
    b.ge _check_s2_body
    
    ldr w1, [x13, w7, SXTW #2]  // body_x[i]
    ldr w2, [x14, w7, SXTW #2]  // body_y[i]
    
    cmp w20, w1
    b.ne _next_s1_segment
    cmp w19, w2
    b.ne _next_s1_segment
    
    mov w0, #CHAR_SNAKE1_BODY
    b _draw_cell
    
_next_s1_segment:
    add w7, w7, #1
    b _s1_body_loop
    
_check_s2_body:
    // 4. Check for Snake 2 body segments
    adrp x13, s2_body_x@PAGE
    add x13, x13, s2_body_x@PAGEOFF
    adrp x14, s2_body_y@PAGE
    add x14, x14, s2_body_y@PAGEOFF
    
    adrp x15, s2_length@PAGE
    add x15, x15, s2_length@PAGEOFF
    ldr w15, [x15]       // w15 = s2_length
    
    mov w7, #0           // Body segment index counter
_s2_body_loop:
    cmp w7, w15          // Check all segments
    b.ge _check_food_cell
    
    ldr w1, [x13, w7, SXTW #2]  // body_x[i]
    ldr w2, [x14, w7, SXTW #2]  // body_y[i]
    
    cmp w20, w1
    b.ne _next_s2_segment
    cmp w19, w2
    b.ne _next_s2_segment
    
    mov w0, #CHAR_SNAKE2_BODY
    b _draw_cell
    
_next_s2_segment:
    add w7, w7, #1
    b _s2_body_loop
    
_check_food_cell:
    // 5. Food
    mov w7, #0           // Food index counter
_food_loop:
    cmp w7, #MAX_FOOD
    b.ge _empty_cell
    
    ldr w1, [x9, w7, SXTW #2]  // food_x[i]
    ldr w2, [x10, w7, SXTW #2] // food_y[i]
    
    // Skip if food is eaten (-1,-1)
    cmn w1, #1
    b.eq _next_food_check
    
    cmp w20, w1
    b.ne _next_food_check
    cmp w19, w2
    b.ne _next_food_check
    
    mov w0, #CHAR_FOOD
    b _draw_cell
    
_next_food_check:
    add w7, w7, #1
    b _food_loop
    
_empty_cell:
    // 6. Empty space
    mov w0, #CHAR_EMPTY
    
_draw_cell:
    strb w0, [x21], #1   // Store character
    add w20, w20, #1     // Next column
    b _col_loop
    
_col_loop_done:
    // Draw right wall
    mov w0, #CHAR_WALL
    strb w0, [x21], #1
    
    // End of row
    mov w0, #'\n'
    strb w0, [x21], #1
    
    add w19, w19, #1     // Next row
    b _row_loop
    
_row_loop_done:
    // Draw bottom border
    mov w0, #CHAR_WALL
    mov w1, #0
_bottom_border_loop:
    cmp w1, #WIDTH+2
    b.ge _bottom_border_done
    
    strb w0, [x21], #1
    add w1, w1, #1
    b _bottom_border_loop
_bottom_border_done:
    mov w0, #'\n'
    strb w0, [x21], #1
    
    // Add null terminator
    mov w0, #0
    strb w0, [x21]
    
    // Print the buffer
    mov x0, x22
    bl _puts
    
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret 