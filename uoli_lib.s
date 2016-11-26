@ MC404 - Trabalho 2 - Subcamada BiCo
@ Ruy Castilho Barrichelo - RA 177012



@ ----------------------------------- CODE ----------------------------------- @
.text


@ ------------------------ MOTORS ------------------------ @

@
@ Sets motor speed. 
@ Parameter: 
@   motor: pointer to motor_cfg_t struct containing motor id and motor speed 
@ Returns:
@   void
@

set_motor_speed:



@ 
@ Sets both motors speed. 
@ Parameters: 
@   * m1: pointer to motor_cfg_t struct containing motor id and motor speed 
@   * m2: pointer to motor_cfg_t struct containing motor id and motor speed 
@ Returns:
@   void
@
set_motors_speed:



@ ------------------------ SONARS ------------------------ @
/* 
 * Reads one of the sonars.
 * Parameter:
 *   sonar_id: the sonar id (ranges from 0 to 15).
 * Returns:
 *   distance of the selected sonar
 */
unsigned short read_sonar(unsigned char sonar_id);


@ 
@ Reads all sonars at once.
@ Parameters: 
@   start: reading goes from this integer and
@   end: reading goes until this integer (a range of sonars to be read)
@   distances: pointer to array that must receive the distances. 
@ Returns:
@   void
@
read_sonars:




@ ------------------------ ALARM ------------------------ @
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
@   sensor_threshold: threshold distance.
@   f: address of the function that should be called when the robot gets close to an object.
@ Returns:
@   void
@
register_proximity_callback:

@ ----------------------------------- DATA ----------------------------------- @
.data
