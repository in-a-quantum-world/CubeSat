MPU6050 - 3 axies accelerometer, 3 axes gyroscope

Sensor values: linear acc, angular velocity, orientation (general spatial arragenment, roll pitch yaw), attitude (arrangement in relation to a defined reference eg horizontal, vertical), displacement. contorl loop will use this


(irrelevant: temperature sensor)


- We need SPI commands to set the attitude
  - SPI commands:


VERY USEFUL DOCUMENT: [commons.erau.edu/cgi/viewcontent.cgi?article=1138&amp;context=beyond](https://commons.erau.edu/cgi/viewcontent.cgi?article=1138&context=beyond)


Combined energy and attitude contol sytsem for small satellites: [www.sciencedirect.com/science/article/pii/S0094576503003382](https://www.sciencedirect.com/science/article/pii/S0094576503003382)

Relevant for electronics as well:

- know which communication protocol to use (WiFi, UDP, TCP??)
- know all the sensors and all the relevant data from the sensors which we will be using directly for the control loop/


To do:

- (Learning): created inverted pendulum simulation model in both Simulink and MATLAB (as demonstrated in the  controls tutorial)
- (learning): understand at surface level, to the most extent that is actuallu relevant to this project: state spaces, fourier transforms, laplace transform
- (Learning): understand at surface level to the most extent that is relevant to the project - transfer functions and PID
- have a working knowlegde of the sensors that the electonics team has decided on adn their communication protocols
- design control loop to read sensor data and actuate the motors appropriately (read sensor data --> black box --> acutate motors approrpraitely)
  - use simulink fro design and testing
- decide on language to use
- Figure out HOW is attitude determined
  - reported via the GUI, but how is it determined??
