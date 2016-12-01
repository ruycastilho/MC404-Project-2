// ----------------- @ MC404 - Trabalho 2 - Ronda.c - LoCo @ ---------------- \\ 
// ----------------- @ Ruy Castilho Barrichelo - RA 177012 @ ---------------- \\


// ----------------------------------------- //
// Includes
// ----------------------------------------- //
#include "uoli_api.h"

// ----------------------------------------- //
// Constants
// ----------------------------------------- //
#define DISTANCE_THRESHOLD 					900
#define CURVE_TIME 							13
#define INTERVAL_THRESHOLD 					50
#define INTERVAL_START						1
#define RIGHT_CURVE_SPEED					5
#define AVOID_OBSTACLE_RIGHT_CURVE_SPEED	7

// -------------------------------------------------------------------------- \\
// ----------------------------------- CODE --------------------------------- \\
// -------------------------------------------------------------------------- \\

// ----------------------------------------- \\
// Function Headers
// ----------------------------------------- \\

void rondaDesvio();
void rondaCurva();
void rondaEspiral();

// ----------------------------------------- \\
// Global variables.
// ----------------------------------------- \\

// Motors.
motor_cfg_t motor1;
motor_cfg_t motor0;

// Counters/timers.
int time = 0;
int interval = 0;


// ----------------------------------------- \\
// Start - Ronda
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Sets Uoli's behavior as a patroller. It must patrol	an area	by   	||
||	moving in a square-like spiral pattern.								||
||	Also, if it finds an obstacle, it should avoid it and keep the		||
||	described behavior.													||
*/

int _start() {

	// Sets the system time as zero, to avoid possible errors when
	// restarting the interval loop and sets the initial value for
	// interval.
	interval = INTERVAL_START;
	set_time(0);

	// Initially, stops the robot.
	motor0.speed = 0;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);

	// Registers the proximity callbacks, that are responsibles
	// for avoiding obstacles in front of Uoli.
	register_proximity_callback(3, DISTANCE_THRESHOLD, rondaDesvio);
	register_proximity_callback(4, DISTANCE_THRESHOLD, rondaDesvio);

	// Starts the spiral-like movement.
	rondaEspiral();

	// Loop to maintain the robot's movement until the interval
	// reaches a specific value. When it does, resets the program.
	while (interval != INTERVAL_THRESHOLD) {
	}

	// Resets the program.
	_start();

}

// ----------------------------------------- \\
//  Ronda Espiral
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Starts Uoli's movement forward. Adds an alarm to start the right 	||
||	curve, that will be begin in a specific system time.				||
*/


void rondaEspiral() {

	// Sets the speeds to move forward.
	motor0.speed = 20;
	motor1.speed = 20;
	set_motors_speed(&motor0, &motor1);

	// Adds alarm responsible for starting a right curve
	// i.e., responsible for stopping the movement forward.
	// The movement lasts for a 'interval' period of time, that
	// is incremented to generate the square-like spiral shape.
	get_time(&time); 
	add_alarm(rondaCurva, time + interval);
	interval += 1;


}

// ----------------------------------------- \\
//  Ronda Curva
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Starts Uoli's curve to the right. Adds an alarm to restart the 	 	||
||	robot's movement forward, that will begin after a specific system	||
||	time interval.														||
*/

void rondaCurva() {

	// Sets the curve speeds to make a right turn.
	motor0.speed = 0;
	motor1.speed = RIGHT_CURVE_SPEED;
	set_motors_speed(&motor0, &motor1);

	// Adds alarm responsible for resuming the movement forward
	// i.e., responsible for stopping the curve.
	// The curve lasts for a CURVE_TIME interval of time.
	get_time(&time); 
	add_alarm(rondaEspiral, time + CURVE_TIME);

}

// ----------------------------------------- \\
//  Ronda Desvio
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Called whenever Uoli fints itself in front of an obstacle.	 	 	||
||	Turns the robot until its path is free.								||
*/

void rondaDesvio() {

	// Sets the curve speeds to avoid obstacles.
	motor0.speed = 0;
	motor1.speed = AVOID_OBSTACLE_RIGHT_CURVE_SPEED;
	set_motors_speed(&motor0, &motor1);

	// Keeps turning until path is clear ahead of it.
	while ( read_sonar(3) < DISTANCE_THRESHOLD ||
			read_sonar(4) < DISTANCE_THRESHOLD ) {

	}

	// Resets the movement.
	motor0.speed = 0;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);

}
