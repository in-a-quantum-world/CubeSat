%%one axis model
%  I*theta_ddot = m*g*d*sin(theta) - tau        (cube, moments about the pin)
%  I_w*w_dot    = tau                           (wheel)
clear; clc; close all
P = svarog_params();
svarog_params();

%% linearisation error
th = deg2rad(0:0.5:30);
figure; plot(rad2deg(th), 100*(th - sin(th))./sin(th), 'LineWidth', 1.5); grid on
xlabel('tilt (deg)'); ylabel('error of sin\theta \approx \theta (%)')

%% open loop, no controller
p = sqrt(P.mgd/P.I);
[t1, x1] = ode45(@(t,x) [x(2); P.mgd*sin(x(1))/P.I], [0 0.6], [deg2rad(1); 0]);
[t2, x2] = ode45(@(t,x) [x(2); P.mgd*x(1)/P.I],      [0 0.6], [deg2rad(1); 0]);
figure; plot(t1, rad2deg(x1(:,1)), t2, rad2deg(x2(:,1)), '--', 'LineWidth', 1.5); grid on
ylim([0 90]); xlabel('t (s)'); ylabel('tilt (deg)'); legend('nonlinear', 'linear', 'Location', 'northwest')
title(sprintf('no control: e^{+%.1f t}, doubling every %.0f ms', p, 1000*log(2)/p))

%% state space
A = [0 1; P.mgd/P.I 0];  B = [0; -1/P.I];  C = [1 0];  D = 0;
sys = ss(A, B, C, D);
disp('open-loop eigenvalues'); disp(eig(A))
