@ MC404 - Trabalho 2 - Subcamada SOUL
@ Ruy Castilho Barrichelo - RA 177012


@ ----------------- CODE ----------------- @

.org 0x0
.section .iv,"a"

_start:		

@ Contains branches to handlers that are used.
interrupt_vector:

    b RESET_HANDLER
    
 	b SYSCALL_HANDLER
 	
.org 0x18
	b IRQ_HANDLER

.org 0x100
.text

	@ Sets system time to zero.
    ldr r2, =SYSTEM_TIME
    mov r0,#0
    str r0,[r2]



@ Reset command handler.
RESET_HANDLER:

	@@@ -------------------------- CONSTANTS ------------------------ @@@

	.set MAX_CALLBACKS, 0x8
	.set MAX_ALARMS, 	0x8
	.set TIME_SZ, 		0x30D40		@ In this case, each cycle lasts 1 microsec.
	.set DIST_INTERVAL, 0x64

	@@@ --------------------------- STACKS -------------------------- @@@

	@ Initializes stacks for all processor modes.


	@ USER's stack.

	mrs r0, cpsr				@ Reads CSPR.
	bic r0, r0, #0x1F			@ Removes current mode (first five bits).
	orr r0, r0, #0xCF			@ Includes new mode - System.
								@ Also disables interruptions.

	msr cpsr, r0				@ Writes the result back to cspr.	
	ldr sp, =STACK_USER_BASE	@ Loads the address in Stack Pointer(r13).

	@ IRQ's stack.

	mrs r0, cpsr				@ Reads CSPR.
	bic r0, r0, #0x1F			@ Removes current mode (first five bits).
	orr r0, r0, #0x12			@ Includes new mode - IRQ..

	msr cpsr, r0				@ Writes the result back to cspr.	
	ldr sp, =STACK_IRQ_BASE		@ Loads the address in Stack Pointer(r13).

	@ SYSTEM's stack.

	mrs r0, cpsr				@ Reads CSPR.
	bic r0, r0, #0x1F			@ Removes current mode (first five bits).
	orr r0, r0, #0x13			@ Includes new mode - Supervisor.


	msr cpsr, r0				@ Writes the result back to cspr.
	ldr sp, = STACK_SYSTEM_BASE	@ Loads the address in Stack Pointer(r13_svc).


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

    @ Sets interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0
    
    @ Enables GTP_CR and configures clock_src to peripheral mode.
	mov r0, #0x00000041		@ Configuration value
	str r0, [r1, #GTP_CR]	@ Stores value in register

	@ Sets GPT_PR (prescaler) to zero(0).
	mov r0, #0				@ Configuration value - Zero
	str	r0, [r1, #GTP_PR]	@ Stores value in register

	@ Moves to GPT_OCR1 the value to be counted.
	mov r0, #TIME_SZ		@ Configuration value - TIME_SZ cycles.
	str r0, [r1, #GTP_OCR1]	@ Stores value in register

	@ Moves to GPT_OCR2 the value to be counted.
	mov r0, #DIST_INTERVAL	@ Configuration value - DIST_INTERVAL cycles.
	str r0, [r1, #GTP_OCR2]	@ Stores value in register

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
	.set GPIO_GDIR_CONFIG, 0xF8007FFF		@ I/O settings in hexadecimal.


	ldr r1, #GPIO_BASE

	@ Configures GDIR.

	LDR r0,= GPIO_GDIR_CONFIG	@ Loads I/0 settings to r0.
	ldr r0, [r1, #GPIO_GDIR]	@ Configures GDIR.


	@ Sets mode as USER.

	mrs r0, cpsr					@ Reads CSPR.
	bic r0, r0, #0x1F				@ Removes current mode.
	orr r0, r0, #0x10				@ Includes new mode -User.

	msr cpsr, r0					@ Writes the result back to cspr.

	b main							@ Branches into main function.


@ Just in case it happens.
main_returned:

	b main_returned



@ Syscall handler.
SYSCALL_HANDLER:

	ldmfd sp!, {r1-r11, lr}		@ Pushes registers into the stack.

	mrs r0, cpsr				@ Reads CSPR.
	orr r0, r0, #0x1F			@ Includes new mode - System.

	msr cpsr, r0				@ Writes the result back to cspr.

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

	cmp r8, #23						@ If it is return_syscall.
	beq return_syscall

	b syscall_end					@ If syscall id is not valid.

@ SYSCALL 18
read_sonar_syscall:

    ldmfd sp!, {r0}  		@ Pops the syscall's parameters.

	@ Checks if id is valid.
	cmp r0, #0				@ Tests if id < 0 and if id > 15
	movlt r0, #-1
							@ If yes (for any of the two), returns r0 = -1
	blt syscall_end

	cmp	 r0, #15.
	movgt r0, #-1

	bgt syscall_end

	@ Sets the multiplexers to reach the correct sonar.
	@ Pins 2-4 of GDIR.

	ldr r1,=GPIO_BASE
	ldr r2, [r1, GPIO_DR]	@ Loads the DR register.

	bic r2, r2, #3C			@ Clears the MUXs bits.
	orr r2, r2, r0, lsl #2	@ Sets the bits corresponding to the id, in the 
							@ correct bits. r0 already contains the id,
							@ so it's just shifted to the left.

	str r2, [r1, GPIO_DR]	@ Stores the result in DR.

	orr r2, r2, #2			@ Sets the trigger pin.

	str r2, [r1, GPIO_DR]

	@ 15ms delay. Waits for 20 clock cycles, that equals 20ms (safety measure).
	mov r3, #15
	ldr r2, = SYSTEM_TIME
	ldr r3, [r2]			@ Stores the system time in this moment.

sonar_trigger_delay:

	ldr r4, [r2]
	sub r4, r4, r3			@ Subtracts new time from old one. Sets flags.
	cmp r4, #20

	blt sonar_trigger_delay	@ If difference is less than 20, keeps waiting.

	bic r2, r2, #2			@ Clears the second bit.
	str r2, [r1, GPIO_DR]	@ Sets trigger as 0.


	@ Checks if flag pin was set to 1.
sonar_flag:
	ldr r2, [r1, GPIO_PSR]	@ Loads the PSR register.

	mov r0, r2, lsr	#6		@ Copies sonar data bits to r0.
	and r2, r2, #1			@ Bitmask to keep only bit 0. (flag)
	cmp r2, #1				@ Checks if flag is set.

	bne sonar_flag

	b syscall_end

@ SYSCALL 17
register_proximity_callback_syscall:

    ldmfd sp!, {r0-r2}  	@ Pops the syscall's parameters.

	@ Checks if id is valid.
	cmp r0, #0				@ Tests if id < 0 and if id > 15
	movlt r0, #-1
							@ If yes (for any of the two), returns r0 = -1
	blt syscall_end

	cmp	 r0, #15.
	movgt r0, #-1

	bgt syscall_end

	@ Checks the quantity of callbacks.
	ldr r3,=callback_quantity
	ldr r4, [r3]
	cmp r3, #MAX_CALLBACKS

	moveq r0, #-2			@ If the amount is already maxed, returns -2 in r0.
	beq syscall_end


	@ adicionar callback


	b syscall_end

@ SYSCALL 18
set_motor_speed_syscall:

    ldmfd sp!, {r0}  	@ Pops the syscall's parameters.

	@ Checks if id is valid.
	@ Tests if id < 0 and if id > 1
	@ If yes (for any of the two), returns r0 = -1

	cmp r0, #0
	movlt r0, #-1
	blt syscall_end

	beq set_motor_speed_validation	@ And skips the next verification.

	cmp	 r0, #1.
	movgt r0, #-1

	bgt syscall_end

set_motor_speed_validation:

	@ Checks if speed is valid.

	cmp r1, #63			@ Checks if speed is higher than 63 (6 bits).
	movgt r0, #-2													@@@@ DUVIDA, eh gt?
	bgt syscall_end		@ Skips to syscall_end, if it isn't valid.

	cmp r1, #0			@ Checks if speed is lower than 0.
	movlt r0, #-2
	blt syscall_end		@ Skips to syscall_end, if it isn't valid.

	@ Stores results.

	ldr r2,=GPIO_BASE			@ Loads GPIO's base address.
	ldr r3, [r2, GPIO_DR]		@ Loads GPIO_DR register.
	
	@ Sets speed pins.
	cmp r0, #0					@ If r0 = 0,
	biceq r3, r3, #0x1F80000	@ Clears speed pins.
	orreq r0, r3, r1 lsl #19	@ Shifts the bits related to the
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

    ldmfd sp!, {r0, r1}  	@ Pops the syscall's parameters.

	@ Checks if speeds are valid.

	@ For motor0:

	cmp r0, #63			@ Checks if speed is higher than 63 (6 bits).
	movgt r0, #-1													@@@@ DUVIDA, eh gt?
	bgt syscall_end		@ Skips to syscall_end, if it isn't valid.

	cmp r0, #0			@ Checks if speed is lower than 0.
	movlt r0, #-1
	blt syscall_end		@ Skips to syscall_end, if it isn't valid.

	cmp r1, #63			@ Checks if speed is higher than 63 (6 bits).
	movgt r0, #-2													@@@@ DUVIDA, eh gt?
	bgt syscall_end		@ Skips to syscall_end, if it isn't valid.

	cmp r1, #0			@ Checks if speed is lower than 0.
	movlt r0, #-2
	blt syscall_end		@ Skips to syscall_end, if it isn't valid.

	@ Stores results.

	ldr r2,=GPIO_BASE			@ Loads GPIO's base address.
	ldr r3, [r2, GPIO_DR]		@ Loads GPIO_DR register.

	bic r3, r3, #0xFDF80000		@ Clears speed pins.

	@ Sets speed pins.

	orr r3, r3, r0 lsl #19		@ Shifts the bits related to the
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

    ldmfd sp!, {r0}  		@ Pops the syscall's parameters.

	ldr r1, = SYSTEM_TIME	@ r1 contains the address to SYSTEM_TIME.
	str r0, [r1]			@ New time is stored in said address.

	b syscall_end

@ SYSCALL 22
set_alarm_syscall:

    ldmfd sp!, {r0, r1}  	@ Pops the syscall's parameters.

	b syscall_end

@ SYSCALL 23 - Required to return to supervisor mode after user's function
@ was called.
return_syscall:

	@ precisa fazer algo pra voltar pro lugar do alarm/callback

syscall_end:

	@ Returns to supervisor mode, so that the correct stack is used to return the
	@ saved state.

	mrs r0, cpsr				@ Reads CSPR.
	orr r0, r0, #0x13			@ Includes new mode - Supervisor.

	msr cpsr, r0				@ Writes the result back to cspr.

	stmfd sp!, {r1-r11, lr}		@ Pops registers from the stack.

	movs pc, lr					@ Returns to previous mode and to previous code.

@ Interruption Request Handler
IRQ_HANDLER:

	@ Disables new interruptions while request is handled.

	mrs r0, cpsr					@ Reads CSPR.
	orr r0, r0, #0x80				@ Keeps current mode, disables I bit.

	msr cpsr, r0					@ Writes the result back to cspr.


	stdfm sp!, {r0-r11, lr}		@ Pushes registers into the stack.

	@ Loads base address to access GTP registers.
	ldr r0,=GTP_BASE

	@ Loads GTP_SR's address.
	ldr r0, [r0, GTP_SR]

	@ Sets GPT_SR (status) to one(1).
	mov r0, #0x1			@ Writes 1 to clear OF1.
	str	r0, [r1, #GTP_SR]	@ Stores value in register

	@ Updates counter.
    ldr r2, =SYSTEM_TIME	@ Loads address.
    ldr r0, [r2]			@ Loads the current value.
    add r0, r0, #1			@ Increments value by 1.
    str r0,[r2]				@ Stores updated value.

	sub lr, lr, #4			@ Return address correction.
							@ ( LR = PC + 4 ) instead of ( LR = PC + 8 ).


	@ Checks and updates alarms.

	@ Considerar alarmes que nao tem tempo =0
	@ tirar 1 de cada tempo de alarme. Se der 0, avisar.

	@ Checks and updates callbacks.

	ldr r4,=callback_counter
	ldr r5, [r4]
	add r5, r5, #1			@ Updates counter.
	cmp r5, #DIST_INTERVAL	@ Compares counter to DIST_INTERVAL.

	moveq r5, #0			@ If counter reached DIST_INTERVAL, it becomes 0.
	str r5, [r4]			@ Stores new value in callback_counter.

	bne irq_handler_end		@ If counter is different to DIST_INTERVAL,
							@ skips to end. Else, checks callbacks


	@ checar callbacks

irq_handler_end:
	ldmfd sp!, {r1-r11, lr}	@ Pops registers from the stack.

	movs pc, lr				@ Returns.

@ ----------------- DATA ----------------- @

.data
@ Label to system time.
SYSTEM_TIME:
.skip 4

STACK_USER_BASE:
.skip 50

STACK_SYSTEM_BASE:
.skip 50

STACK_IRQ_BASE:
.skip 50

@ Auxiliar counter (clock related).
callback_counter:
.skip 4

@ Callback and alarm counters.
callback_quantity:
.skip 4
alarm_quantity:
.skip 4

@ Callback vector.
@ 8 structs that contain: 
@ Sonar id (1 byte), distance (2 bytes), function pointer (4 bytes)
callback_vector:
.skip 56

@ Alarm vector.
@ 8 structs that contain: 
@ Time period(4 bytes), function pointer (4 bytes)
alarm_vector:
.skip 64
