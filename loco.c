// ----------------- @ MC404 - Trabalho 2 - Subcamada LoCo @ ---------------- \\ 
// ----------------- @ Ruy Castilho Barrichelo - RA 177012 @ ---------------- \\


// ----------------------------------------- //
// Includes
// ----------------------------------------- //
#include "uoli_api.h"

// ----------------------------------------- //
// Constants
// ----------------------------------------- //
#define DISTANCE_THRESHOLD 900
#define DISTANCE_THRESHOLD_TURN 400
#define DISTANCE_THRESHOLD_FOLLOW 400
#define SONAR_ABSOLUTE_DIFFERENCE 1
#define CURVE_TIME 10
	
// -------------------------------------------------------------------------- \\
// ----------------------------------- CODE --------------------------------- \\
// -------------------------------------------------------------------------- \\

// ----------------------------------------- \\
// Function Headers
// ----------------------------------------- \\

void segueParede();
void alinhaParalelamenteParede();
void buscaParede();
void ronda();
void rondaDesvio();
void rondaCurva();
void rondaEspiral();

// ----------------------------------------- \\
// Global variables.
// ----------------------------------------- \\

// Motors.
motor_cfg_t motor1;
motor_cfg_t motor0;

// Distance array.
int distances[16];

// Counters/timers.
int time = 0;
int interval = 0;

// ----------------------------------------- \\
// Main Function - Segue-Parede
// ----------------------------------------- \\

/*
||	Parameters: void													||
||  Return: 0.															||
||	Initiates Uoli behavior as inactive, so it doesn't hit an obstacle	||
||	as soon as it stars moving. Calls buscaParede function to start 	||
||	its movement.														||
*/
int _start() {

	// Initial setup. Uoli inactive.
	motor0.id = 0;
	motor0.speed = 0;
	motor1.id = 1;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);

							//// MUDAR AREA DE DADOS E CODIGO NO MAKEFILE
	ronda();
/*
	// Initiate buscaParede ( Searches Wall ). Moves forward until it
	// finds an obstacle.
	buscaParede();

*/

	return 0;
}


// ----------------------------------------- \\
// Busca Parede:
// ----------------------------------------- \\

/*
||	Parameters: Pointer to a array that stores distances.				||
||  			Pointers to 2 motor_cfg_t (motor0, motor1) variables.	||
||  Return: void.														||
||	Moves forward until Uoli finds an obstacle (wall), through its 		||
||	sonars. Once it does find it, the function calls					||
||	alinhaParalelamenteParede, that is responsible for aligning Uoli	||
||	to said wall.														||
*/

void buscaParede() {

	// Front sonars are read to check for initial obstacles.
	distances[3] = read_sonar(3);
	distances[4] = read_sonar(4);

	// If, initially, there's no obstacle, Uoli goes forward.
	if ( distances[3] > DISTANCE_THRESHOLD &&
		distances[4] > DISTANCE_THRESHOLD ) {

		// Both motors are set to move forward.
		motor0.speed = 25;
		motor1.speed = 25;
		set_motors_speed(&motor0, &motor1);

		// It goes forward until an obstacle is found in front of it.
		do {

			distances[3] = read_sonar(3);
			distances[4] = read_sonar(4);

		} while (distances[3] > DISTANCE_THRESHOLD &&
				 distances[4] > DISTANCE_THRESHOLD );


		// Stops the robot.
		motor0.speed = 0;
		motor1.speed = 0;
		set_motors_speed(&motor0, &motor1);


	}

	// When Uoli finds a wall, alinhaParalelamenteParede is called to
	// align the robot to said obstacle.
	alinhaParalelamenteParede();

}


// ----------------------------------------- \\
// Alinha Paralelamente Parede
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Turns Uoli until it is positioned as parallel as it can to a wall.	||
||	sonars. Once it does align it, the function calls segueParede, that	||
||	is responsible for following said wall from that moment onwards.	||
*/

void alinhaParalelamenteParede() {


	// Starts a turn to the right so that the wall remains to the left of
	// the robot.
	motor0.speed = 0;
	motor1.speed = 2;
	set_motors_speed(&motor0, &motor1);

	// Keeps turning until the left side sonars (0;15) indicate the 
	// alignment. It does so by calculating the difference between the 
	// them, that should be less than a defined value to guarantee
	// reasonable alignment. In addition, distances from both 
	// sonars 0 and 15 have to be greater than a defined threshold.
	do {
		distances[0] = read_sonar(0);
		distances[15] = read_sonar(15);

	} while ( 	read_sonar(3) < DISTANCE_THRESHOLD	|| 
				read_sonar(4) < DISTANCE_THRESHOLD	||
				(( distances[0] - distances[15] > SONAR_ABSOLUTE_DIFFERENCE ) || 
				( distances[15] - distances[0] > SONAR_ABSOLUTE_DIFFERENCE )) ||	
				distances[0] > DISTANCE_THRESHOLD_TURN ||
				distances[15] > DISTANCE_THRESHOLD_TURN );

	motor0.speed = 0;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);



	// After the primary alignment, a second test is made.
	// Sonars (1: 14) are checked in 2 steps:
	// The first one consists of checking if both of them hava vision of the
	// wall. If they do, the second step starts; else, it is skipped.
	// The second one consists of ajusting Uoli so that the mentioned sonars
	// return a similar distance, aswell as the first pair tested. 

	// Reads sonars 1 and 14.
	distances[1] = read_sonar(1);
	distances[14] = read_sonar(14);

	// First step.
	if ( distances[1] < DISTANCE_THRESHOLD &&
		distances[14] < DISTANCE_THRESHOLD ) {


		int first_step_valid = 1;
		// Second step.

		// Determines the direction the robot should turn to ajust its position.
		// Then, sets the motors with the appropriate speeds. 

		// In case the turn should be made to the right.
		if ( distances[1] < distances[14] ) {
			motor0.speed = 0;
			motor1.speed = 1;
			set_motors_speed(&motor0, &motor1);
		}


		// In case the turn should be made to the left.
		else {
			motor0.speed = 1;
			motor1.speed = 0;
			set_motors_speed(&motor0, &motor1);

		}

		// Ajusts position.
		while ( first_step_valid &&
				(( distances[1] - distances[14] > SONAR_ABSOLUTE_DIFFERENCE) || 
				( distances[14] - distances[1] > SONAR_ABSOLUTE_DIFFERENCE )) ||	
				distances[0] > DISTANCE_THRESHOLD_TURN ||
				distances[15] > DISTANCE_THRESHOLD_TURN ) {

			distances[0] = read_sonar(0);
			distances[1] = read_sonar(1);
			distances[14] = read_sonar(14);
			distances[15] = read_sonar(15);

			if ( distances[1] > DISTANCE_THRESHOLD ||
				distances[14] > DISTANCE_THRESHOLD ) {

				first_step_valid = 0;
			}


		}

		// Stops the robot, after the ajust is done.
		motor0.speed = 0;
		motor1.speed = 0;
		set_motors_speed(&motor0, &motor1);

	}


	// When Uoli is parallel to the wall, the segueParede function is called
	// to initiate the wall-follower behavior.
	segueParede();


}

// ----------------------------------------- \\
// Segue Parede
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Sets Uoli's behavior as a wall-follower. It must follow a wall  	||
||	while remaining as parallel as it can to said wall.					||
*/

void segueParede() {

	// Front sonars are read to check for initial obstacles.
	// If, initially, there's an obstacle, alinhaParalelamenteParede is
	// called again.
	if ( read_sonar(3) < DISTANCE_THRESHOLD ||
		 read_sonar(4) < DISTANCE_THRESHOLD ) {

		motor0.speed = 0;
		motor1.speed = 0;
		set_motors_speed(&motor0, &motor1);
		alinhaParalelamenteParede();

	}

	else {

		motor0.speed = 5;
		motor1.speed = 5;
		set_motors_speed(&motor0, &motor1);

	}

	do {


		if ( read_sonar(3) < DISTANCE_THRESHOLD ||
			 read_sonar(4) < DISTANCE_THRESHOLD ) {

			motor0.speed = 0;
			motor1.speed = 0;
			set_motors_speed(&motor0, &motor1);
			alinhaParalelamenteParede();

		}


		if ( read_sonar(2) > DISTANCE_THRESHOLD_FOLLOW &&
			read_sonar(1) > DISTANCE_THRESHOLD_FOLLOW &&
			read_sonar(0) > DISTANCE_THRESHOLD_FOLLOW ) {

			motor1.speed = 4;
			set_motor_speed(&motor1);

		}


		else if ( read_sonar(2) < DISTANCE_THRESHOLD_FOLLOW ) {

			motor1.speed = 6;
			set_motor_speed(&motor1);

		}


	} while ( 1 );

}

// ----------------------------------------- \\
// Ronda
// ----------------------------------------- \\

/*
||	Parameters: void.													||
||  Return: void.														||
||	Sets Uoli's behavior as a patroller. It must patrol	an area	by   	||
||	moving in a square-like spiral pattern.								||
||	Also, if it finds an obstacle, it should avoid it and keep the		||
||	described behavior.													||
*/

void ronda() {

	interval = 10;
	set_time(0);

	motor0.speed = 0;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);

	//register_proximity_callback(3, DISTANCE_THRESHOLD, rondaDesvio);
	//register_proximity_callback(4, DISTANCE_THRESHOLD, rondaDesvio);

	rondaEspiral();

	while (interval != 50) {
	}

	ronda();

}


void rondaEspiral() {

	motor0.speed = 20;
	motor1.speed = 20;
	set_motors_speed(&motor0, &motor1);

	get_time(&time); 
	add_alarm(rondaCurva, time + interval);
	interval += 1;


}

void rondaCurva() {

	motor0.speed = 0;
	motor1.speed = 5;
	set_motors_speed(&motor0, &motor1);

	get_time(&time); 
	add_alarm(rondaEspiral, time + CURVE_TIME);

}

void rondaDesvio() {

	motor0.speed = 0;
	motor1.speed = 1;
	set_motors_speed(&motor0, &motor1);


	while ( read_sonar(3) < DISTANCE_THRESHOLD ||
			read_sonar(4) < DISTANCE_THRESHOLD ) {

	}

	motor0.speed = 10;
	motor1.speed = 10;
	set_motors_speed(&motor0, &motor1);

}
