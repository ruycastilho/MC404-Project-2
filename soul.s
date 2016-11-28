@ MC404 - Trabalho 2 - Subcamada SOUL
@ Ruy Castilho Barrichelo - RA 177012


@ ----------------- CODE ----------------- @

.org 0x0
.section .iv,"a"

_start:		

@ Contains branches to handlers that are used.
interrupt_vector:

    b RESET_HANDLER
   
.org 0x08
 	b SYSCALL_HANDLER
 	
.org 0x18
	b IRQ_HANDLER

.org 0x100
.text

@ Reset command handler.
RESET_HANDLER:

	@@@ -------------------------- CONSTANTS ------------------------ @@@

	.set MAX_CALLBACKS, 			0x8
	.set MAX_ALARMS, 				0x8
	.set CALLBACK_SIZE,			 	0x7
	.set ALARM_SIZE,				0x8
	.set TIME_SZ, 					0x1A1F8	@ = 107. In this case, each cycle lasts 1 microsec.
	.set DIST_INTERVAL, 			0x64
	.set USER_CODE_START, 			0x77802000

	.set CLEAR_BOTH_MOTORS_SPEEDS, 	0xFFFC0000
	.set SONAR_DATA_READ_BITMASK, 	0xFFF

	@@@ ------------------------------------------------------------- @@@

    @ Sets interrupt table base address on coprocessor 15 - Copied from the lab page.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0

	@ Sets the system time to zero.
    ldr r2, =SYSTEM_TIME
    mov r0,#0
    str r0,[r2]

	@@@ --------------------------- STACKS -------------------------- @@@

	@ Initializes stacks for all modes.

	@ USER's stack.

	msr cpsr_c, #0xDF			@ Includes new mode - System.
								@ Also disables interruptions.
	
	ldr sp, =STACK_USER_BASE	@ Loads the address in Stack Pointer(r13).

	@ IRQ's stack.

	msr cpsr_c, #0x12			@ Includes new mode - IRQ.
	
	ldr sp, =STACK_IRQ_BASE		@ Loads the address in Stack Pointer(r13).

	@ SUPERVISOR's stack.

	msr cpsr_c, #0x13			@ Includes new mode - Supervisor.

	ldr sp, = STACK_SUPERVISOR_BASE	@ Loads the address in Stack Pointer(r13_svc).


	@@@ ----------------------------- GPT --------------------------- @@@

	@ Sets constants to access GTP registers.
	.set GTP_BASE, 0x53FA0000
	.set GTP_CR, 0x0
	.set GTP_PR, 0x4
	.set GTP_SR, 0x8
	.set GTP_OCR1, 0x10
	.set GTP_OCR2, 0x14
	.set GTP_IR, 0xC

	@ Loads base address to access GTP registers.
    ldr	r1, =GTP_BASE
    
    @ Enables GTP_CR and configures clock_src to peripheral mode.
	mov r0, #0x00000041		@ Configuration value
	str r0, [r1, #GTP_CR]	@ Stores value in register

	@ Sets GPT_PR (prescaler) to zero(0).
	mov r0, #0				@ Configuration value - Zero
	str	r0, [r1, #GTP_PR]	@ Stores value in register

	@ Moves to GPT_OCR1 the value to be counted.
	ldr r0, =TIME_SZ		@ Configuration value - TIME_SZ cycles.
	str r0, [r1, #GTP_OCR1]	@ Stores value in register

	@ Sets GPT_IR to one(1).
	mov r0, #1				@ Configuration value - OCR1 enabled.
	str r0, [r1, #GTP_IR]	@ Stores value in register

	@@@ ---------------------------- TZIC  -------------------------- @@@

@ Enables TZIC
ET_TZIC:
    @ Constants to TZIC's addresses
    .set TZIC_BASE,             0x0FFFC000
    .set TZIC_INTCTRL,          0x0
    .set TZIC_INTSEC1,          0x84 
    .set TZIC_ENSET1,           0x104
    .set TZIC_PRIOMASK,         0xC
    .set TZIC_PRIORITY9,        0x424

    @ Loads the interruption controller.
    @ R1 <= TZIC_BASE

    ldr	r1, =TZIC_BASE

    @ Configures interruption 39 from GPT as unsafe
    mov	r0, #(1 << 7)	
    str	r0, [r1, #TZIC_INTSEC1]

    @ Enables interruption 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configures interrupt 39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configures PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Enables the interruption controller.
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]

	@ Enables interruptions.
    msr  CPSR_c,  #0x13   @ SUPERVISOR mode, IRQ/FIQ enabled


	@@@ ---------------------------- GPIO  -------------------------- @@@

	@ Sets constants to access GPIO registers.
	.set GPIO_BASE, 0x53F84000
	.set GPIO_DR, 0x0
	.set GPIO_GDIR, 0x4
	.set GPIO_PSR, 0x8
	.set GPIO_GDIR_CONFIG, 0xFFFC003E		@ I/O settings in hexadecimal.


	ldr r1, =GPIO_BASE

	@ Configures GDIR.

	ldr r0,= GPIO_GDIR_CONFIG	@ Loads I/0 settings to r0.
	str r0, [r1, #GPIO_GDIR]	@ Configures GDIR.


	@ Sets mode as USER.

	msr cpsr_c, #0x10			@ Includes new mode - User.

	@ Branches to user's code.
	ldr pc, = USER_CODE_START


@ Syscall handler.
SYSCALL_HANDLER:

	stmfd sp!, {r1-r11, lr}		@ Pushes registers into the stack.

	msr cpsr_c, #0x1F			@ Includes new mode - System.

	@ Determination of current syscall.
	cmp r7, #16						@ If is is read_sonar. 
	beq read_sonar_syscall

	cmp r7, #17						@ If is is register_proximity_callback. 
	beq register_proximity_callback_syscall

	cmp r7, #18						@ If is is set_motor_speed. 
	beq set_motor_speed_syscall		

	cmp r7, #19						@ If is is set_motors_speed. 
	beq set_motors_speed_syscall

	cmp r7, #20						@ If is is get_time. 
	beq get_time_syscall

	cmp r7, #21						@ If is is set_time. 
	beq set_time_syscall

	cmp r8, #22						@ If it is set_alarm.
	beq set_alarm_syscall

	b syscall_end					@ If syscall id is not valid.

@ SYSCALL 16
read_sonar_syscall:

    ldr r0, [sp]  					@ Loads the syscall's parameters.

	@ Checks if id is valid.
	@ Tests if id < 0 and if id > 15. (Treated as unsigned)
	@ If yes (for any of the two), returns r0 = -1

	cmp r0, #15
	movhi r0, #-1
	bhi syscall_end

	@ Sets the multiplexers to reach the correct sonar.
	@ Pins 2-4 of GDIR.

	ldr r1,=GPIO_BASE
	ldr r2, [r1, #GPIO_DR]	@ Loads the DR register.

	bic r2, r2, #0x3C		@ Clears the MUXs bits.
	orr r2, r2, r0, lsl #2	@ Sets the bits corresponding to the id, in the 
							@ correct bits. r0 already contains the id,
							@ so it's just shifted to the left.

	str r2, [r1, #GPIO_DR]	@ Stores the result in DR.

	orr r2, r2, #2			@ Sets the trigger pin.

	str r2, [r1, #GPIO_DR]

	@ 15ms delay. Waits for 20 clock cycles, that equals 20ms (safety measure).

	ldr r5, = SYSTEM_TIME
	ldr r3, [r5]			@ Loads the system time in this moment.

sonar_trigger_delay:

	ldr r4, [r5]
	sub r4, r4, r3			@ Subtracts new time from old one. Sets flags.
	cmp r4, #20

	blo sonar_trigger_delay	@ If difference is less than 20, keeps waiting.

	bic r2, r2, #2			@ Clears the second bit.
	str r2, [r1, #GPIO_DR]	@ Sets trigger as 0.


	@ Checks if flag pin was set to 1.
sonar_flag:
	ldr r2, [r1, #GPIO_DR]	@ Loads the DR register.

	mov r0, r2				@ Copies bits to r0.
	and r2, r2, #1			@ Bitmask to keep only bit 0. (flag)
	cmp r2, #1				@ Checks if flag is set.

	bne sonar_flag
	lsr r0, r0, #6			@ Shifts bits.

	ldr r1,= SONAR_DATA_READ_BITMASK
	and r0, r0, r1			@ Bitmask to keep only 12 bits.
	
	b syscall_end

@ SYSCALL 17
register_proximity_callback_syscall:

    ldr r0, [sp]  					@ Loads the syscall's parameters.
	ldr r1, [sp, #4]
	ldr r2, [sp, #8]

	@ Checks if id is valid.
	cmp r0, #0				@ Tests if id < 0 and if id > 15
	movlt r0, #-1
							@ If yes (for any of the two), returns r0 = -1
	blt syscall_end

	cmp	r0, #15
	movgt r0, #-1

	bgt syscall_end

	@ Checks the quantity of callbacks.
	ldr r3,=callback_quantity
	ldr r4, [r3]
	cmp r4, #MAX_CALLBACKS

	moveq r0, #-2				@ If the amount is already maxed, returns -2 in r0.
	beq syscall_end

	ldr r5,=callback_vector		@ Loads the address to callback_vector.
	mov r6, r4					@ Copies the amount of callbacks.
	add r6, r6, #1				@ Adds the new callback.

register_callback_find_last:

	cmp r4, #0
	sub r4, r4, #CALLBACK_SIZE		@ Moves the pointer forward until it reaches
									@ the last callback added in the vector,
									@ i.e., until the quantity reaches 0.
	addgt r5, r5, #CALLBACK_SIZE

	bgt register_callback_find_last

	str r6, [r3]					@ Stores the new amount of callbacks

	strb r0, [r5], #1				@ Stores the id (byte) in the callback, 
									@ Updates address.
	strh r1, [r5], #2				@ Stores the distance (2bytes) in the callback,
									@ Updates address.		
	str r2, [r5], #2				@ Stores the pointer (4bytes) in the callback,
									@ Updates address.		

	mov r0, #0						@ Parameters are valid. Returns 0.

	b syscall_end

@ SYSCALL 18
set_motor_speed_syscall:

    ldr r0, [sp]  					@ Loads the syscall's parameters.
	ldr r1, [sp, #4]

	@ Checks if id is valid.
	@ Tests if id < 0 and if id > 1. (Treated as unsigned)
	@ If yes (for any of the two), returns r0 = -1

	cmp r0, #1
	movhi r0, #-1
	bhi syscall_end

	@ Checks if speed is valid.

	cmp r1, #63			@ Checks if speed uses more than 6 bits.
	movhi r0, #-1		@ Whether its negative or higher than 63.
	bhi syscall_end		@ Skips to syscall_end, if it isn't valid.

	@ Stores results.

	ldr r2,=GPIO_BASE			@ Loads GPIO's base address.
	ldr r3, [r2, #GPIO_DR]		@ Loads GPIO_DR register.
	
	@ Sets speed pins.
	cmp r0, #0					@ If r0 = 0,
	biceq r3, r3, #0x1F80000	@ Clears speed pins.
	orreq r0, r3, r1, lsl #19	@ Shifts the bits related to the
								@ speed to  the correct pins (19-24).

								@ If r0 = 1,
	bicgt r3, r3, #0xFC000000	@ Clears speed pins.
	orrgt r0, r3, r1, lsl #26	@ If r0 = 1, shifts the bits related to the
								@ speed to the correct pins (26-31).

	str r0, [r2, #GPIO_DR]		@ Stores the bit mask in the DR register.

	mov r0, #0					@ Parameters are valid.

	b syscall_end

@ SYSCALL 19
set_motors_speed_syscall:

    ldr r0, [sp]  					@ Loads the syscall's parameters.
	ldr r1, [sp, #4]

	@ Checks if speeds are valid.

	@ For motor0:

	cmp r0, #63			@ Checks if speed uses more than 6 bits.
	movhi r0, #-1		@ Whether its negative or higher than 63.
	bhi syscall_end		@ Skips to syscall_end, if it isn't valid.

	cmp r1, #63			@ Checks if speed uses more than 6 bits.
	movhi r0, #-2		@ Whether its negative or higher than 63.
	bhi syscall_end		@ Skips to syscall_end, if it isn't valid.

	cmp r1, #0			@ Checks if speed is lower than 0.
	movlt r0, #-2
	blt syscall_end		@ Skips to syscall_end, if it isn't valid.

	@ Stores results.

	ldr r2,=GPIO_BASE			@ Loads GPIO's base address.
	ldr r3, [r2, #GPIO_DR]		@ Loads GPIO_DR register.

	ldr r4,= CLEAR_BOTH_MOTORS_SPEEDS
	bic r3, r3, r4				@ Clears speed pins.

	@ Sets speed pins.

	orr r3, r3, r0, lsl #19		@ Shifts the bits related to the
								@ speed of motor0 to the correct pins (19-24).

	orr r3, r3, r1, lsl #26		@ Shifts the bits related to the
								@ speed of motor1 to the correct pins (26-31).

	str r3, [r2, #GPIO_DR]		@ Stores the bit mask in the DR register.

	mov r0, #0					@ Parameters are valid.

	b syscall_end

@ SYSCALL 20
get_time_syscall:

	ldr r0, = SYSTEM_TIME
	ldr r0, [r0]

	b syscall_end

@ SYSCALL 21
set_time_syscall:

    ldr r0, [sp]  					@ Loads the syscall's parameters.

	ldr r1, = SYSTEM_TIME	@ r1 contains the address to SYSTEM_TIME.
	str r0, [r1]			@ New time is stored in said address.

	b syscall_end

@ SYSCALL 22
set_alarm_syscall:

    ldr r0, [sp]  					@ Loads the syscall's parameters.
	ldr r1, [sp, #4]

	@ Checks the quantity of alarms.
	ldr r2,=alarm_quantity
	ldr r3, [r2]
	cmp r3, #MAX_ALARMS

	moveq r0, #-1				@ If the amount is already maxed, returns -1 in r0.
	beq syscall_end

	@ Checks if time is valid.
	ldr r6,=SYSTEM_TIME			@ Loads address to system time.
	ldr r6, [r6]				@ Loads the system time.

	cmp r1, r6					@ Compares given time to system time.
	movlt r0, #-2				@ If it is in the past, returns -2.			
	blt syscall_end

	ldr r4,=alarm_vector		@ Loads the address to alarm_vector.
	add r3, r3, #1				@ Adds the new alarm.
	str r3, [r2]				@ Stores new amount in alarm_quantity.

alarm_find_unused:
	ldr r3, [r4]				@ Loads first alarm.
	cmp r3, #-1					@ Checks if is unused. ( time = -1 ).

	addgt r4, #ALARM_SIZE		@ If is in use, updates address.
	bgt alarm_find_unused

	str r1, [r4]				@ Stores time value in new alarm.
	str r0, [r4, #4]			@ Stores pointer in new alarm.

syscall_end:

	@ Returns to supervisor mode, so that the correct stack is used to return the
	@ saved state.

	msr cpsr_c, #0x13			@ Includes new mode - Supervisor.

	ldmfd sp!, {r1-r11, lr}		@ Pops registers from the stack.

	movs pc, lr					@ Returns to previous mode and to previous code.


	@@@ alarms: saber qnts pela quantidade, só checar o que nao for time=zero
	@@@ adicionar se nao tiver max, e no primeiro que for zero, no vetor;


@ Interruption Request Handler
IRQ_HANDLER:

	stmfd sp!, {r0-r11, lr}			@ Pushes registers into the stack.

	@ Disables new interruptions while request is handled.
	msr cpsr_c, #0x92				@ Includes new mode - IRQ.	
									@ Also, disables regular interruptions.

	@ Loads base address to access GTP registers.
	ldr r0,=GTP_BASE

	@ Loads GTP_SR's address.
	ldr r0, [r0, #GTP_SR]

	@ Sets GPT_SR (status) to one(1).
	mov r0, #0x1			@ Writes 1 to clear OF1.
	str	r0, [r1, #GTP_SR]	@ Stores value in register

	@ Updates counter.
    ldr r2, =SYSTEM_TIME	@ Loads address.
    ldr r0, [r2]			@ Loads the current value.
    add r0, r0, #1			@ Increments value by 1.
    str r0,[r2]				@ Stores updated value.




	b irq_handler_end



	@ Checks and updates alarms.

	ldr r4,= alarm_quantity	@ Loads address to amount of alarms.
	ldr r4, [r4]			@ Loads amount of alarms.
	cmp r4, #0

	beq irq_checks_callbacks

	ldr r5, = alarm_vector	@ Loads address to alarm vector.
	ldr r3, = MAX_ALARMS	@ Loads the maximum amount of alarms
	ldr r3, [r3]			@ Initializes counter with maximum amount of alarms.

irq_alarm_loop:

	sub r3, r3, #1				@ Updates counter.
	ldr r6, [r5]				@ Loads first alarm struct.
	cmp r6, #-1

	addeq r5, r5, #ALARM_SIZE	@ If it is unused, skips to the next.
	beq irq_alarm_loop

	sub r6, r0					@ Compares to system time (in r0).
	cmp r6, #0					@ Checks if it is zero.
	moveq r6, #-1				@ If it is, changes to time and stores -1.

	ldr r6, [r5]				@ Stores updated time.

	beq alarm_reached_zero		@ Also, the user function is called.

	cmp r3, #0
	bgt irq_alarm_loop			@ If there are more alarms, returns to the
								@ alarm loop.

alarm_reached_zero:

	@ Changes mode to System mode.

	msr cpsr_c, #0x1F			@ Includes new mode - System.

	stmfd sp!, {lr}				@ Stores system's lr.

	@ Branches to user's function.

	ldr r4, [r5, #4]			@ Loads pointer to function.
	blx	r4						@ Branches with link to return.
								@ User's code will return to this point,
								@ since user's lr was changed.

	ldmfd sp!, {lr}				@ Restores system's lr.

	@ Changes mode to Supervisor mode.

	msr cpsr_c, #0x13			@ Includes new mode - Supervisor.

	cmp r3, #0
	bgt irq_alarm_loop			@ If there are more alarms, returns to the
								@ alarm loop.

irq_checks_callbacks:

	@ Checks and updates callbacks.

	ldr r4,=callback_quantity	@ Loads the amount of callbacks.
	ldr r5, [r4]

	cmp r5, #0					@ If it is zero, skips the verifications.
	beq irq_handler_end

	add r5, r5, #1			@ Updates counter.
	cmp r5, #DIST_INTERVAL	@ Compares counter to DIST_INTERVAL.

	moveq r5, #0			@ If counter reached DIST_INTERVAL, it becomes 0.
	str r5, [r4]			@ Stores new value in callback_counter.

	bne irq_handler_end		@ If counter is different to DIST_INTERVAL,
							@ skips to end. Else, checks callbacks


	@ checar callbacks

irq_handler_end:
	ldmfd sp!, {r0-r11, lr}	@ Pops registers from the stack.

	sub lr, lr, #4			@ Return address correction.
							@ ( LR = PC + 4 ) instead of ( LR = PC + 8 ).

	movs pc, lr				@ Returns.

@ ----------------- DATA ----------------- @

.data
@ Label to system time.
SYSTEM_TIME:
.skip 4

@ Stacks

.skip 0x100
STACK_USER_BASE:

.skip 0x30
STACK_SUPERVISOR_BASE:

.skip 0x30
STACK_IRQ_BASE:

@ Auxiliar counter (clock related).
callback_counter:
.word 0

@ Callback and alarm counters.
callback_quantity:
.word 0
alarm_quantity:
.word 0

@ Callback vector.
@ 8 structs that contain: 
@ Sonar id (1 byte), distance (2 bytes), function pointer (4 bytes)
callback_vector:
.skip MAX_CALLBACKS*CALLBACK_SIZE

@ Alarm vector.
@ 8 structs that contain: 
@ Time period(4 bytes), function pointer (4 bytes) in this order.
@ Initializes with -1 in every field, to indicate is unused.
alarm_vector:
.fill MAX_ALARMS*2, 4, -1
