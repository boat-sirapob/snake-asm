@ - Snake Project -

@ Members:
@       65011443 Peerachada Limtrakul
@       65011514 Salinporn Rattanaprapaporn
@       65011527 Sirapob Sriviriyahphaiboon
@       65011587 Thanida Paige Pholsukcharoen

@ make accessible from main program
.global snake_tail_x
.global snake_tail_y
.global snake_x
.global snake_y
.global snake_x_vel
.global snake_y_vel
.global tail_front
.global tail_rear
.global tail_length

.global food_x
.global food_y

.global score

.global initialize_game
.global snake_update

@ imports
.extern modulo
.extern rand_range
.extern initialize_rand

@ constants
.equ GRID_WIDTH, 30
.equ GRID_HEIGHT, 20
.set QUEUE_LIMIT, GRID_WIDTH * GRID_HEIGHT * 4

@ declare variables
.data
.balign 4
    @ attributes for snake
    snake_x:        .word 0     @ x position of head
    snake_y:        .word 0     @ y position of head
    snake_x_vel:    .word 1
    snake_y_vel:    .word 0
    target_length:  .word 3

    # circular queue for the tail
    snake_tail_x:   .space QUEUE_LIMIT
    snake_tail_y:   .space QUEUE_LIMIT
    tail_front:     .word 0     @ index for front of queue
    tail_rear:      .word 0     @ index for rear of queue
    tail_length:    .word 0

    @ attributes for food
    food_x:         .word 0
    food_y:         .word 0

    @ attribute for score
    score:          .word 0

    @ for printing the score
    pattern:        .asciz "Score: %d\n"

@ game logic
.text
.global main
initialize_game:

    @ backup link register
    PUSH {LR}               @ push link register to stack

    BL initialize_rand
    BL initialize_snake
    BL initialize_food

    @ return
    POP {LR}                @ restore link register
    BX LR                   @ return    

initialize_snake:
    
    @ backup link register
    PUSH {LR}               @ push link register to stack

    @ print the score
    LDR R0, =pattern        @ load the pattern for printing
    LDR R1, =score          @ load address of score
    LDR R1, [R1]            @ dereference
    BL printf               @ print

    @ reset score
    LDR R1, =score          @ load address of score
    MOV R0, #0              @ reset to 0
    STR R0, [R1]            @ store into variable

    @ reset tail
    LDR R1, =tail_front     @ load address of tail front
    MOV R0, #0              @ reset to 0
    STR R0, [R1]            @ store into variable

    LDR R1, =tail_rear      @ load address of tail rear
    MOV R0, #0              @ reset to 0
    STR R0, [R1]            @ store into variable

    LDR R1, =tail_length    @ load address of tail length
    MOV R0, #0              @ reset to 0
    STR R0, [R1]            @ store into variable

    @ reset position

    @ reset x
    LDR R1, =snake_x        @ load address of x
    MOV R0, #0              @ reset to 0
    STR R0, [R1]            @ store into variable

    @ reset y
    LDR R2, =snake_y        @ load address of y
    MOV R1, #0              @ reset to 0
    STR R1, [R2]            @ store into variable

    @ add current position to tail
    BL enqueue_tail         @ add to tail; enqueue_tail()
    
    @ reset velocity

    @ reset x
    LDR R1, =snake_x_vel    @ load address of x vel
    MOV R0, #1              @ reset to 1
    STR R0, [R1]            @ store into variable

    @ reset y
    LDR R2, =snake_y_vel    @ load address of y vel
    MOV R1, #0              @ reset to 0
    STR R1, [R2]            @ store into variable

    @ reset length
    LDR R1, =target_length  @ load address of target length
    MOV R0, #3              @ reset to 3
    STR R0, [R1]            @ store into variable

    @ return
    POP {LR}                @ restore link register
    BX LR                   @ return

initialize_food:

    @ backup link register
    PUSH {LR}               @ push link register to stack

  initialize_food_loop:
    @ get random x position
    MOV R0, #0              @ range_min = 0
    LDR R1, =GRID_WIDTH     @ range_max = grid_width
    BL rand_range           @ R0 = rand_range(range_min=0, range_max=grid_width)
    LDR R2, =food_x         @ load address of food x position
    STR R0, [R2]            @ store into food_x variable
    PUSH {R0}               @ temporarily store R0

    @ get random y position
    MOV R0, #0              @ range_min = 0
    LDR R1, =GRID_HEIGHT    @ range_max = grid_height
    BL rand_range           @ R0 = rand_range(range_min=0, range_max=grid_height)
    LDR R2, =food_y         @ load address of food y position
    STR R0, [R2]            @ store into food_y variable

    @ reset if position in snake
    MOV R1, R0              @ move to correct positional arguments
    POP {R0}                @ restore R0
    BL check_in_tail        @ check if food position is in the snake tail

    CMP R0, #1                  @ if yes
    BEQ initialize_food_loop    @ ... generate a new position  

    @ return
    POP {LR}                @ restore link register
    BX LR                   @ return    

enqueue_tail:
    @ add position to tail

    @ load position to add
    LDR R0, =snake_x        @ load address of snake x position
    LDR R0, [R0]            @ dereference
    LDR R1, =snake_y        @ load address of snake y position
    LDR R1, [R1]            @ dereference

    @ backup link register
    PUSH {LR}               @ push link register to stack

    @ get rear of tail
    LDR R4, =tail_rear      @ load address of queue rear
    LDR R2, [R4]            @ dereference; R2 = tail_rear

    @ enqueue for tail x
    LDR R3, =snake_tail_x   @ load address of queue for tail x positions
    STR R0, [R3, R2]        @ enqueue at rear

    @ enqueue for tail y
    LDR R3, =snake_tail_y   @ load address of queue for tail y positions
    STR R1, [R3, R2]        @ enqueue at rear

    @ increment tail length
    LDR R3, =tail_length    @ load address of tail length
    LDR R0, [R3]            @ dereference
    ADD R0, R0, #1          @ increment
    STR R0, [R3]            @ store back into variable
    
    @ increment rear; tail_rear = (tail_rear + 4) % QUEUE_LIMIT
    @   R4 = address to tail_rear
    @   R2 = value of tail_rear
    MOV R0, R2              @ move the tail_rear to R0
    ADD R0, R0, #4          @ increment using number of bytes
    LDR R1, =QUEUE_LIMIT    @ load end of queue
    BL modulo               @ R0 = R0 % QUEUE_LIMIT; modulo(tail_rear, QUEUE_LIMIT)
    STR R0, [R4]            @ store back into variable

    @ return
    POP {LR}                @ restore link register
    BX LR                   @ return

dequeue_tail:
    @ remove from front of queue

    @ backup link register
    PUSH {LR}               @ push link register to stack
    
    @ decrement tail length
    LDR R0, =tail_length    @ load tail length address
    LDR R1, [R0]            @ dereference
    SUB R1, R1, #1          @ decrement
    STR R1, [R0]            @ store back into variable

    @ get front of tail
    LDR R2, =tail_front     @ load address of queue front
    LDR R1, [R2]            @ dereference

    @ increment front of tail
    @   we don't need to remove the value because
    @   it will be overwritten by the enqueue function
    ADD R1, R1, #4          @ increment using number of bytes

    @ handle wrapping
    MOV R0, R1              @ R0 = R1
    LDR R1, =QUEUE_LIMIT    @ load end of queue

    BL modulo               @ R0 = R0 % QUEUE_LIMIT; modulo(tail_front, QUEUE_LIMIT)
    STR R0, [R2]            @ store back into variable

    @ return
    POP {LR}                @ restore link register
    BX LR                   @ return

get_next_position:
    
    @ get next position
    @ R0 = snake_x + snake_x_vel
    LDR R0, =snake_x        @ load x position address
    LDR R0, [R0]            @ dereference
    LDR R1, =snake_x_vel    @ load x velocity address
    LDR R1, [R1]            @ dereference
    ADD R0, R0, R1          @ add velocity to position

    @ R1 = snake_y + snake_y_vel
    LDR R1, =snake_y        @ load y position address
    LDR R1, [R1]            @ dereference
    LDR R2, =snake_y_vel    @ load y velocity address
    LDR R2, [R2]            @ dereference
    ADD R1, R1, R2          @ add velocity to position

    @ return
    BX LR                   @ return

check_eat:
    @ check if the next position of the snake
    @ eats the food

    @ back up link register
    PUSH {LR}                   @ push link register to stack

    @ get next position
    BL get_next_position        @ R0 = next x, R1 = next y

    @ check x
    LDR R2, =food_x             @ load food x address
    LDR R2, [R2]                @ dereference
    CMP R0, R2                  @ if food_x != next x
    BNE check_eat_false         @ ... return 0

    @ check y
    LDR R2, =food_y             @ load food y address
    LDR R2, [R2]                @ dereference
    CMP R1, R2                  @ if food_y != next y
    BNE check_eat_false         @ ... return 0

    @ else return true
    check_eat_true:
        MOV R0, #1              @ R0 = 1
        B check_eat_return      @ return
    check_eat_false:
        MOV R0, #0              @ R0 = 0
    check_eat_return:
        @ return
        POP {LR}                @ restore link register
        BX LR                   @ return

check_in_tail:
    @ check if position (x = R0, y = R1) is in tail

    @ back up link register
    PUSH {LR}                   @ push link register to stack

    @ starting index for loop
    LDR R2, =tail_front         @ load front of tail
    LDR R2, [R2]                @ dereference

    @ check for collision with tail
    check_in_tail_loop:
        @ while i < tail_rear:
        @     if R0 == tail_x[i] and R1 == tail_y[i]:
        @         return 1
        @     else:
        @         i++
        @ return 0

        @ check if we reached the end of the tail
        LDR R3, =tail_rear              @ load tail rear address
        LDR R3, [R3]                    @ dereference

        CMP R2, R3                      @ if we reach the end
        BEQ check_in_tail_not_found     @ ... break

        @ check x
        LDR R3, =snake_tail_x       @ load tail x position
        LDR R3, [R3, R2]            @ at address pointed by the index
        CMP R0, R3                  @ if R0 != snake_tail_x[i]
        BNE check_in_tail_incr      @ ... continue
        
        @ check y
        LDR R3, =snake_tail_y       @ load tail y position
        LDR R3, [R3, R2]            @ at address pointed by the index
        CMP R1, R3                  @ if R1 != snake_tail_y[i]
        BNE check_in_tail_incr      @ ... continue
        
        @ position found in tail
        B check_in_tail_found       @ return 1

    check_in_tail_incr:
        
        ADD R2, R2, #4                  @ else, increment index
        
        @ handle wrapping
        PUSH {R0, R1}                   @ temporarily back up R0 and R1
        MOV R0, R2                      @ move the index to R0
        LDR R1, =QUEUE_LIMIT            @ load end of queue
        BL modulo                       @ wrap
        MOV R2, R0                      @ move index back
        POP {R0, R1}                    @ restore R0 and R1

        B check_in_tail_loop          @ continue the loop

    check_in_tail_found:
        MOV R0, #1          @ we return 1 if found
        B check_in_tail_return
    check_in_tail_not_found:
        MOV R0, #0          @ we return 0 if not found
    check_in_tail_return:
        POP {LR}            @ restore link register            
        BX LR               @ return

check_collision:
    @ loop to check if the next position
    @ overlaps with the tail or outside the window

    @ back up link register
    PUSH {LR}                   @ push link register to stack

    @ get next position
    BL get_next_position        @ R0 = next x, R1 = next y

    @ check for going outside the window
    CMP R0, #0                  @ if x < 0
    BLT check_collision_found   @   return 1

    CMP R1, #0                  @ if y < 0
    BLT check_collision_found   @   return 1

    LDR R3, =GRID_WIDTH         @ load GRID_WIDTH
    CMP R0, R3                  @ if x >= GRID_WIDTH
    BGE check_collision_found   @   return 1

    LDR R3, =GRID_HEIGHT        @ load GRID_HEIGHT
    CMP R1, R3                  @ if y >= GRID_HEIGHT
    BGE check_collision_found   @   return 1

    @ check for collision with tail
    BL check_in_tail                @ R0 = 1 if (x=R0, y=R1) in tail else 0
    CMP R0, #0                      @ if R0 == 0:
    BEQ check_collision_not_found   @ ... return 0

    check_collision_found:
        MOV R0, #1          @ we return 1 if found
        B check_collision_return
    check_collision_not_found:
        MOV R0, #0          @ we return 0 if not found
    check_collision_return:
        POP {LR}            @ restore link register            
        BX LR               @ return

snake_update:
    @ back up link register
    PUSH {LR}               @ push link register to stack

    @ check if next position will overlap with food
    BL check_eat            @ R0 = 1 if overlaps else 0

    CMP R0, #0              @ if R0 == 0:
    BEQ update_continue_1   @ ... continue
    BL initialize_food      @ else: reset food
                            @ ... and increment tail length
    LDR R1, =target_length  @ load address of tail target length
    LDR R0, [R1]            @ dereference
    ADD R0, R0, #1          @ increment
    STR R0, [R1]            @ store back into variable

    LDR R1, =score          @ load address of score
    LDR R0, [R1]            @ dereference
    ADD R0, R0, #1          @ increment
    STR R0, [R1]            @ store back into variable

  update_continue_1:

    @ check if next position will kill snake
    BL check_collision      @ R0 = 1 if yes else 0

    CMP R0, #0              @ if R0 == 0:
    BEQ update_continue_2   @ ... continue

    BL initialize_snake

  update_continue_2:
    @ update snake position using snake velocity
    @ snake_x += snake_x_vel
    LDR R0, =snake_x        @ load x position address
    LDR R1, [R0]            @ dereference
    LDR R2, =snake_x_vel    @ load x velocity address
    LDR R2, [R2]            @ dereference
    ADD R2, R1, R2          @ add velocity to position
    STR R2, [R0]            @ store position back

    @ snake_y += snake_y_vel
    LDR R0, =snake_y        @ load y position address
    LDR R1, [R0]            @ dereference
    LDR R2, =snake_y_vel    @ load y velocity address
    LDR R2, [R2]            @ dereference
    ADD R2, R1, R2          @ add velocity to position
    STR R2, [R0]            @ store position back

    @ add current position to tail
    BL enqueue_tail         @ enqueue_tail()

    @ remove end of tail
    @ if actual length is more than target length remove
    @ else, actual length is less than target or correct
    LDR R0, =tail_length    @ load tail length address
    LDR R0, [R0]            @ dereference
    LDR R1, =target_length  @ load target length address
    LDR R1, [R1]            @ dereference

    CMP R0, R1              @ if actual length <= target length
    BLE update_return       @ ... continue
        @ else remove end of tail

        BL dequeue_tail     @ dequeue_tail()

    update_return:
        @ return
        POP {LR}            @ restore link register
        BX LR               @ return
