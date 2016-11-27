@ MC404 - Trabalho 2 - Subcamada BiCo
@ Ruy Castilho Barrichelo - RA 177012



@ ----------------------------------- CODE ----------------------------------- @
.text

@ CONSTANTS
.set MAX_CALLBACKS, 8
.set MAX_ALARMS, 8
.set DIST_INTERVAL, 1200

@ ------------------------ MOTORS ------------------------ @

@
@ Sets motor speed. 
@ Parameter: 
@   motor: pointer to motor_cfg_t struct containing motor id and motor speed 
@ Returns:
@   void
@

.global set_motor_speed
.align 4
set_motor_speed:

    stmfd sp!, {r7, lr}		@ Save the callee-save registers.

	ldrb r1, [r0, #1]		@ Loads the speed field in r1.
	ldrb r0, [r0]			@ Loads the id field in r0

	cmp r1, #0				@ Compares the received id with 0
							@ to determine which motor should be set.

	mov r7, #18				@ Syscall to set_motor_speed.
	stmfd sp!, {r0, r1}		@ Pushes parameters to stack.
	svc 0x0					


    ldmfd sp!, {r7, pc}  	@ Restore the registers and return.


@ 
@ Sets both motors speed. 
@ Parameters: 
@   * m1: pointer to motor_cfg_t struct containing motor id and motor speed 
@   * m2: pointer to motor_cfg_t struct containing motor id and motor speed 
@ Returns:
@   void
@

.global set_motors_speed
.align 4
set_motors_speed:

    stmfd sp!, {r7, lr}		@ Saves the callee-save registers.

	mov r2, r0				@ Saves both mem addresses in r2, r3
	mov r3, r1				@ since r0 and r1 will be used as parameters.

	ldrb r0, [r2]			@ Loads the id field in r0.
	cmp r0, #0				@ Compares the received id with 0
							@ to determine which motor it corresponds to.

	bhi inverse_setup
							@ If it corresponds to motor0.

	ldrb r0, [r2, #1]		@ Loads the speed field of motor0 in r0.	
	ldrb r1, [r3, #1]		@ Loads the speed field of motor1 in r1.

	b setup_end

inverse_setup:				@ Else, it corresponds to motor1.

	ldrb r0, [r3, #1]		@ Loads the speed field of motor0 in r0.	
	ldrb r1, [r2, #1]		@ Loads the speed field of motor1 in r1.

setup_end:

	mov r7, #19				@ Syscall to set_motors_speed.
	stmfd sp!, {r0, r1}		@ Pushes parameters to stack.
	svc 0x0	
		
    ldmfd sp!, {r7, pc}		@ Restore the registers and return.

@ ------------------------ SONARS ------------------------ @

@ 
@ Reads one of the sonars.
@ Parameter:
@   sonar_id: the sonar id (ranges from 0 to 15).
@ Returns:
@   distance of the selected sonar
@
.global read_sonar
.align 4
read_sonar:

    stmfd sp!, {r7, lr}		@ Save the callee-save registers.

	mov r7, #16				@ Syscall to read_sonar.
	stmfd sp!, {r0}			@ Pushes parameters to stack.
	svc 0x0					

    ldmfd sp!, {r7, pc}		@ Restore the registers and return.


@ 
@ Reads all sonars at once.
@ Parameters: 
@   start: reading goes from this integer and
@   end: reading goes until this integer (a range of sonars to be read)
@   distances: pointer to array that must receive the distances. 
@ Returns:
@   void
@
.global read_sonars
.align 4
read_sonars:
 
    stmfd sp!, {r4-r7, lr}			@ Save the callee-save registers.
	mov r6, r0						@ Declares a counter that begins in 'start'.
	mov r5, r2						@ Saves array address in r5.
	mov r4, r1						@ Saves 'end' in r4.

loop:

	mov r7, #16					@ Syscall to read_sonar.
	stmfd sp!, {r0}				@ Pushes parameters to stack.
	svc 0x0					


								@@@ duvida nessa lsl #1 ou #2
	str r0, [r5, r6, lsl #1]	@ Stores value read from sonar in the correct array
								@ position. Index determined by: counter*4 (shifted).

	add r6, r6, #1				@ Updates counter.

	cmp r6, r4					@ Checks if counter reached 'end'. If yes, returns to
	ble loop					@ caller. Else, returns to loop.

		@@@ DUVIDA AQUI ble ou blt @@@

    ldmfd sp!, {r4-r7, pc}  	@ Restore the registers and return.


@ 
@ Register a function f to be called whenever the robot gets close to an object. The user
@ should provide the id of the sensor that must be monitored (sensor_id), a threshold 
@ distance (dist_threshold) and the user function that must be called. The system will 
@ register this information and monitor the sensor distance every DIST_INTERVAL cycles. 
@ Whenever the sensor distance becomes smaller than the dist_threshold, the system calls 
@ the user function.
@
@ Parameters: 
@   sensor_id: id of the sensor that must be monitored.
@   dist_threshold: threshold distance.
@   f: address of the function that should be called when the robot gets close to an object.
@ Returns:
@   void
@
.global register_proximity_callback
.align 4
register_proximity_callback:
	
	stmfd sp!, {r7, lr}		@ Saves the callee-save registers.

	mov r7, #17				@ Syscall to register_proximity_callback.
	stmfd sp!, {r0-r2}		@ Pushes parameters to stack.
	svc 0x0					

	ldmfd sp!, {r7, pc} 	@ Restore the registers and return.

@ ------------------------ TIMERS ------------------------ @

@ 
@ Adds an alarm to the system.
@ Parameter: 
@   f: function to be called when the alarm triggers.
@   time: the time to invoke the alarm function.
@ Returns:
@   void
@
.global add_alarm
.align 4
add_alarm:

	stmfd sp!, {r7, lr}		@ Saves the callee-save registers.

	mov r7, #22				@ Syscall to set_alarm.
	stmfd sp!, {r0, r1}		@ Pushes parameters to stack.
	svc 0x0					

	ldmfd sp!, {r7, pc} 	@ Restore the registers and return.

@
@ Reads the system time.
@ Parameter:
@   * t: pointer to a variable that will receive the system time.
@ Returns:
@   void
@
.global get_time
.align 4
get_time:

	stmfd sp!, {r4, r7, lr}		@ Saves the callee-save registers.
	
	mov r4, r0					@ Saves the pointer 't' in r4.
	
	mov r7, #20					@ Syscall to get_time.
	svc 0x0	

	str r0, [r4]				@ Stores the system time in the received variable.

	ldmfd sp! {r4, r7, pc} 		@ Restore the registers and return.


@
@ Sets the system time.
@ Parameter: 
@   t: the new system time.
@
.global set_time
.align 4
set_time:

	stmfd sp!, {lr}			@ Saves the callee-save registers.

	mov r7, #21				@ Syscall to set_time.
	stmfd sp!, {r0}			@ Pushes parameters to stack.
	svc 0x0		

	ldmfd sp! {pc} 			@ Restore the registers and return.

@ ----------------------------------- DATA ----------------------------------- @
.data