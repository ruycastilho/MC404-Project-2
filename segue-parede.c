// --------------- @ MC404 Trabalho 2 - Segue-Parede.c - LoCo @ ------------- \\ 
// ----------------- @ Ruy Castilho Barrichelo - RA 177012 @ ---------------- \\


// ----------------------------------------- //
// Includes
// ----------------------------------------- //
#include "uoli_api.h"

// ----------------------------------------- //
// Constants
// ----------------------------------------- //
#define DISTANCE_THRESHOLD 					900
#define DISTANCE_THRESHOLD_TURN 			400
#define DISTANCE_THRESHOLD_FOLLOW		 	600
#define SONAR_ABSOLUTE_DIFFERENCE 			1

// -------------------------------------------------------------------------- \\
// ----------------------------------- CODE --------------------------------- \\
// -------------------------------------------------------------------------- \\

// ----------------------------------------- \\
// Function Headers
// ----------------------------------------- \\

void segueParede();
void alinhaParalelamenteParede();
void buscaParede();

// ----------------------------------------- \\
// Global variables.
// ----------------------------------------- \\

// Motors.
motor_cfg_t motor1;
motor_cfg_t motor0;

// Distance array.
int distances[16];

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

	// Initiate buscaParede ( Searches Wall ). Moves forward until it
	// finds an obstacle.
	buscaParede();


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

	// Both motors are set to move forward.
	motor0.speed = 25;
	motor1.speed = 25;
	set_motors_speed(&motor0, &motor1);

	// It goes forward until an obstacle is found in front of it.
	do {

	} while (read_sonar(3) > DISTANCE_THRESHOLD &&
			 read_sonar(4) > DISTANCE_THRESHOLD );


	// Stops the robot.
	motor0.speed = 0;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);


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
				( distances[15] - distances[0] > SONAR_ABSOLUTE_DIFFERENCE )) );

	motor0.speed = 0;
	motor1.speed = 0;
	set_motors_speed(&motor0, &motor1);



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
	if ( read_sonar(3) < DISTANCE_THRESHOLD_FOLLOW ||
		 read_sonar(4) < DISTANCE_THRESHOLD_FOLLOW ) {

		alinhaParalelamenteParede();

	}

	// Else, starts the movement.
	motor0.speed = 10;
	motor1.speed = 10;
	set_motors_speed(&motor0, &motor1);

	// Follows wall.
	do {

		if ( read_sonar(1) > DISTANCE_THRESHOLD_FOLLOW ) {

			motor1.speed = 7;
			motor0.speed = 10;
			set_motors_speed(&motor0, &motor1);

		}


		else if ( read_sonar(14) > DISTANCE_THRESHOLD_FOLLOW ) {

			motor1.speed = 10;
			motor0.speed = 7;
			set_motors_speed(&motor0, &motor1);


		}


		if ( read_sonar(3) < DISTANCE_THRESHOLD_FOLLOW ||
			read_sonar(4) < DISTANCE_THRESHOLD_FOLLOW ) {

			motor1.speed = 4;
			motor0.speed = 0;
			set_motors_speed(&motor0, &motor1);

			while ( read_sonar(3) < DISTANCE_THRESHOLD_FOLLOW ||
					read_sonar(4) < DISTANCE_THRESHOLD_FOLLOW ) {}

		}



	} while ( 1 );

}
