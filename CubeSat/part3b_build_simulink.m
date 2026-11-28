%%building svarog_1axis.slx by script and running
clear; clc; close all
P = svarog_params();
v = struct('I_cube', P.I, 'I_w', P.I_w, 'mgd', P.mgd, 'tau_lim', P.tau_lim, ...
           'Kp', P.Kp, 'Kd', P.Kd, 'Ki', P.Ki, 'theta0', P.theta_rec, 'theta_ref', 0, ...
           'rpm_max', P.rpm_max, 'Ts', 1/P.f_ctrl);
f = fieldnames(v);
for k = 1:numel(f), assignin('base', f{k}, v.(f{k})); end

sys = 'svarog_1axis';
if bdIsLoaded(sys), close_system(sys, 0); end
if isfile([sys '.slx']), delete([sys '.slx']); end
new_system(sys); open_system(sys);
set_param(sys, 'StopTime', '3', 'Solver', 'ode45', 'MaxStep', '0.001');

add = @(lib, name, col, row, varargin) add_block(lib, [sys '/' name], ...
    'Position', [60+140*col, 60+110*row, 120+140*col, 100+110*row], varargin{:});

add('simulink/Sources/Constant',                        'ref',     0, 0, 'Value', 'theta_ref');
add('simulink/Math Operations/Sum',                     'err',     1, 0, 'Inputs', '-+');
add('simulink/Discrete/Discrete PID Controller',        'PID',     2, 0, 'P', 'Kp', 'I', 'Ki', 'D', 'Kd', 'N', '200', 'SampleTime', 'Ts');
add('simulink/Discontinuities/Saturation',              'sat',     3, 0, 'UpperLimit', 'tau_lim', 'LowerLimit', '-tau_lim');
add('simulink/Math Operations/Sum',                     'body',    4, 1, 'Inputs', '+-');
add('simulink/Math Operations/Gain',                    'invI',    5, 1, 'Gain', '1/I_cube');
add('simulink/Continuous/Integrator',                   'int_w',   6, 1);
add('simulink/Continuous/Integrator',                   'int_th',  7, 1, 'InitialCondition', 'theta0');
add('simulink/Math Operations/Trigonometric Function',  'sin',     5, 2, 'Operator', 'sin');
add('simulink/Math Operations/Gain',                    'mgd',     4, 2, 'Gain', 'mgd');
add('simulink/Math Operations/Gain',                    'invIw',   4, 3, 'Gain', '1/I_w');
add('simulink/Continuous/Integrator',                   'int_ww',  5, 3);
add('simulink/Math Operations/Gain',                    'to_rpm',  6, 3, 'Gain', '60/(2*pi)');
add('simulink/Math Operations/Gain',                    'to_deg',  8, 1, 'Gain', '180/pi');
add('simulink/Sinks/To Workspace',                      'log_th',  9, 1, 'VariableName', 'theta_log', 'SaveFormat', 'Array');
add('simulink/Sinks/To Workspace',                      'log_rpm', 7, 3, 'VariableName', 'rpm_log',   'SaveFormat', 'Array');
add('simulink/Sinks/To Workspace',                      'log_tau', 4, 0, 'VariableName', 'tau_log',   'SaveFormat', 'Array');

L = @(a, b) add_line(sys, a, b, 'autorouting', 'on');
L('ref/1', 'err/1');      L('int_th/1', 'err/2');    L('err/1', 'PID/1');     L('PID/1', 'sat/1');
L('sat/1', 'body/2');     L('sat/1', 'invIw/1');     L('sat/1', 'log_tau/1');
L('int_th/1', 'sin/1');   L('sin/1', 'mgd/1');       L('mgd/1', 'body/1');
L('body/1', 'invI/1');    L('invI/1', 'int_w/1');    L('int_w/1', 'int_th/1');
L('int_th/1', 'to_deg/1');L('to_deg/1', 'log_th/1');
L('invIw/1', 'int_ww/1'); L('int_ww/1', 'to_rpm/1'); L('to_rpm/1', 'log_rpm/1');
save_system(sys);

out = sim(sys);
t = out.tout;  th = out.theta_log;  rpm = out.rpm_log;  tau = out.tau_log;
fprintf('Simulink: RMSE %.3f deg, peak %.4f N m, %.0f rpm\n', sqrt(mean(th.^2)), max(abs(tau)), max(abs(rpm)));
figure
subplot(3,1,1); plot(t, th);  grid on; ylabel('tilt (deg)')
subplot(3,1,2); plot(t, rpm); grid on; ylabel('wheel (rpm)'); yline([rpm_max -rpm_max], 'r--')
subplot(3,1,3); plot(t, tau); grid on; ylabel('\tau (N m)'); xlabel('t (s)'); yline([tau_lim -tau_lim], 'r--')
