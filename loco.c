// MC404 - Trabalho 2 - Subcamada LoCo - Segue-Parede
// Ruy Castilho Barrichelo - RA 177012


// INCLUDES
#include "uoli_api.h"

// DEFINES

#define DISTANCE_LIMIT 1500
#define DISTANCE_LIMIT_TURN 200


// CODE

void segueParede(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1);
void buscaParede(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1);
void reverse(short* distances, motor_cfg_t* motor0, motor_cfg_t* motor1);

int a =1;

void teste() {
	a=0;
	
}

int _start() {


	//short distances[16];
	motor_cfg_t motor0;
	motor_cfg_t motor1;


	//motor0.id = 0;
	//motor0.speed = 0;
	//motor1.id = 1;
	//motor1.speed = 0;

	//set_motors_speed(&motor0, &motor1);

	//buscaParede(distances, &motor0, &motor1);



		motor0.speed = 25;
		motor1.speed = 25;
		set_motors_speed(&motor0, &motor1);

while(1){}
	return 0;
}


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


