// svarog_controller.h  --  attitude PID, one axis. Gains from svarog_tune (23 Nov 2026).
// Call step() every control period (5 ms at 200 Hz) with theta and theta_dot in
// rad and rad/s, theta = 0 upright, both positive in the same direction.
// Returns the current command in A for SimpleFOC (motor.move(i) in current mode,
// or motor.move(i * R_phase) in voltage mode).
#pragma once
#include <math.h>

struct SvarogPid {
  // tuned gains, nominal plant: m 0.73 kg, d 3.4 cm, I 1.87e-3 kg m^2
  float kp = 0.85f;        // N m / rad
  float kd = 0.054f;       // N m s / rad
  float ki = 0.0f;         // N m / (rad s). Use 1.0 once PD balances.

  // motor: GM2804 on SimpleFOCMini
  float tau_lim = 0.030f;  // N m
  float kt      = 0.0375f; // N m / A, replace with measured stall torque / stall current
  float i_max   = 1.5f;    // A, must equal motor.current_limit
  float sign    = 1.0f;    // flip to -1 if the rig runs away on first power-up

  float integ = 0.0f;

  float step(float theta, float theta_dot, float dt) {
    float tau = kp * theta + kd * theta_dot + ki * integ;
    bool sat = fabsf(tau) > tau_lim;
    if (sat) tau = copysignf(tau_lim, tau);
    float i = tau / kt;
    if (fabsf(i) > i_max) { i = copysignf(i_max, i); sat = true; }
    if (!sat) integ += theta * dt;      // anti-windup: hold the integral while clamped
    return sign * i;
  }

  void reset() { integ = 0.0f; }
};
