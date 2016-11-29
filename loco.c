// ----------------- @ MC404 - Trabalho 2 - Subcamada LoCo @ ---------------- \\ 
// ----------------- @ Ruy Castilho Barrichelo - RA 177012 @ ---------------- \\


// ----------------------------------------- //
// Includes
// ----------------------------------------- //
#include "uoli_api.h"

// ----------------------------------------- //
// Defines
// ----------------------------------------- //
#define DISTANCE_LIMIT 1600
#define DISTANCE_LIMIT_TURN 200


// -------------------------------------------------------------------------- \\
// ----------------------------------- CODE --------------------------------- \\
// -------------------------------------------------------------------------- \\

// ----------------------------------------- \\
// Function Headers
// ----------------------------------------- \\

void segueParede(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1);
void buscaParede(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1);
void reverse(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1);
void teste();
void teste2();


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


	// MUDAR O LOOP DOR READ SONAR, E CONSTANTE DO CALLBACK
	// MUDAR O POP DA BICO.S PRA NAO SOBRESCREVER O R0, OU TRATAR ISSO

	// Motors.
	motor_cfg_t motor1;
	motor_cfg_t motor0;

	// Distance array.
	int distances[16];

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
||	sonars. Once it does find it, the function calls segueParede, that	||
||	is responsible for following said wall from that moment onwards.	||
*/

void buscaParede(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1) {

	// Front sonars are read to check for initial obstacles.
	distances[3] = read_sonar(3);
	distances[4] = read_sonar(4);

	// If, initially, there's no obstacle, Uoli goes forward.
	if ( distances[3] > DISTANCE_LIMIT && distances[4] > DISTANCE_LIMIT ) {

		// Both motors are set to move forward.
		motor0->speed = 25;
		motor1->speed = 25;
		set_motors_speed(motor0, motor1);

		// It goes forward until an obstacle is found in front of it.
		do {

			distances[3] = read_sonar(3);
			distances[4] = read_sonar(4);

		} while (distances[3] > DISTANCE_LIMIT && distances[4] > DISTANCE_LIMIT );
	
		motor0->speed = 0;
		motor1->speed = 0;
		set_motors_speed(motor0, motor1);


	}

	// When an obstacle is found, Uoli stars to move in parallel to it.
	segueParede(distances, motor0, motor1);



}


// ----------------------------------------- \\
// Segue Parede
// ----------------------------------------- \\

/*
||	Parameters: Pointer to a array that stores distances.				||
||  			Pointers to 2 motor_cfg_t (motor0, motor1) variables.	||
||  Return: void.														||
||	Sets Uoli's behavior as a wall follower. It must follow a wall  	||
||	while remaining as parallel as it can to said wall.					||
*/

void segueParede(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1) {

	motor0->speed = 0;
	motor1->speed = 10;
	set_motors_speed(motor0, motor1);

	do {
		distances[0] = read_sonar(0);
		distances[15] = read_sonar(15);

	} while ( distances[0] != distances[15] && distances[0] > DISTANCE_LIMIT_TURN );

	motor0->speed = 0;
	motor1->speed = 0;
	set_motors_speed(motor0, motor1);



}

// ----------------------------------------- \\
// Ronda
// ----------------------------------------- \\

/*
||	Parameters: Pointer to a array that stores distances.				||
||  			Pointers to 2 motor_cfg_t (motor0, motor1) variables.	||
||  Return: void.														||
||	Sets Uoli's behavior as a patroller. It must patrol	an area	by   	||
||	moving in a square-like shape that grows larger.					||
||	Also, if it finds an obstacle, it should avoid it and keep the		||
||	described behavior.													||
*/




