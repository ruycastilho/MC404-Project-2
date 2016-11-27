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


callback_vector:					@@@ checar isso
.skip 56

alarm_vector:
.skip 64

.org 0x100
.text

	@ Sets system time to zero.
    ldr r2, =SYSTEM_TIME
    mov r0,#0
    str r0,[r2]



@ Reset command handler.
RESET_HANDLER:


	@@@ -------------------------- CONSTANTS ------------------------ @@@

	.set MAX_CALLBACKS, 8
	.SET MAX_ALARMS, 8

	@@@ --------------------------- STACKS -------------------------- @@@

	@ Sets constants as memory addresses to initialize stacks.
	.set STACK_USER_BASE, 0x80000000
	.set STACK_SYSTEM_BASE, 0x79000000

	@ Initializes stacks for all processor modes.


	@ USER stack.

	mrs r0, cpsr				@ Reads CSPR.
	bic r0, r0, #0x1F			@ Removes current mode (first five bits).
	orr r0, r0, #0xCF			@ Includes new mode - System.
								@ Also disables interruptions.

	msr cpsr, r0				@ Writes the result back to cspr.	
	ldr sp, =STACK_USER_BASE	@ Loads the address in Stack Pointer(r13).


	@ SYSTEM stack.

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

	.set TIME_SZ, 100
	.set DIST_INTERVAL, 100				@@@ Mudar aqui

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

	@ Sets GPT_IR to three(3).
	mov r0, #3				@ Configuration value - OCR1 and OCR2 enabled.
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

	@@@ Duvida, como vai pro programa .c?


@ Syscall handler.
SYSCALL_HANDLER:

	@@ disable nas interrupcoes?

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

	mov r0, r0, lsl #2		@ Shifts bits to match pins.


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

	b syscall_end

@ SYSCALL 18
set_motor_speed_syscall:

    ldmfd sp!, {r0, r1}  	@ Pops the syscall's parameters.

	@ Checks if id is valid.
	@ Tests if id < 0 and if id > 1
	@ If yes (for any of the two), returns r0 = -1

	cmp r0, #0
	movlt r0, #-1
	blt syscall_end

	moveq r0, #1, lsl #18		@ If r0 = 0, sets pin 18 as 1.
	orreq r0, r0, r1, lsl #19	@ And sets the bits related to the speed to
								@ the correct pins (19-24)

	beq set_motor_speed_write	@ And skips the next verification.

	cmp	 r0, #1.
	movgt r0, #-1
	moveq r0, #1, lsl #25		@ If r0 = 1, sets pin 25 as 1.
	orreq r0, r0, r1, lsl #26	@ And shifts the bits related to the speed to
								@ the correct pins (26-31)
	bgt syscall_end

set_motor_speed_write:

	@@@ CHECAR VELOCIDADE INVALIDA

	ldr r2,=GPIO_BASE			@ Loads GPIO's base address.
	str r0, [r2, #GPIO_DR]		@ Stores the bit mask in the DR register.

	b syscall_end

@ SYSCALL 19
set_motors_speed_syscall:

    ldmfd sp!, {r0, r1}  	@ Pops the syscall's parameters.

	@@@ CHECAR VELOCIDADE INVALIDA

	b syscall_end

@ SYSCALL 20
get_time_syscall:

	ldr r0, = SYSTEM_TIME
	ldr r0, [r0]

	b syscall_end

@ SYSCALL 21
set_time_syscall:

    ldmfd sp!, {r0}  		@ Pops the syscall's parameters.
	stmfd sp!, {r1}			@ Pushes r1 into the stack.

	ldr r1, = SYSTEM_TIME	@ r1 contains the address to SYSTEM_TIME.
	str r0, [r1]			@ New time is stored in said address.

	ldmfd sp!, {r1}			@ Pops r1 out of the stack.

	b syscall_end

@ SYSCALL 22
set_alarm_syscall:

    ldmfd sp!, {r0, r1}  	@ Pops the syscall's parameters.




syscall_end:

	stmfd sp!, {r1-r11, lr}		@ Pops registers from the stack.

	movs pc, lr					@ Returns to user mode and to user's code.

@ Interruption Request Handler
IRQ_HANDLER:

	@ Disables new interruptions while request is handled.

	mrs r0, cpsr					@ Reads CSPR.
	orr r0, r0, #0x80				@ Keeps current mode, disables I bit.

	msr cpsr, r0					@ Writes the result back to cspr.


	@ Checks which Output Compare Channel is activated.
	stdfm sp!, {r0-r11, r14}		@ Pushes registers into the stack.

	@ Loads base address to access GTP registers.
	ldr r0,=GTP_BASE

	@ Loads GTP_SR's address.
	ldr r0, [r0, GTP_SR]

	cmp r0, #1
	beq output_compare_channel_1

output_compare_channel_2:

	@ Sets GPT_SR (status) to one(2).
	mov r0, #0x2			@ Writes 1 to clear OF2.
	str	r0, [r1, #GTP_SR]	@ Stores value in register

	b request_handler_end

output_compare_channel_1:

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

request_handler_end:
	ldmfd sp!, {r1-r11, lr}	@ Pops registers from the stack.

	movs pc, lr				@ Returns.

@ ----------------- DATA ----------------- @

.data
@ Label to system time.
SYSTEM_TIME:
