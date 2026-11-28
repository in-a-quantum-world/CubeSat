%% transfer function, poles, PD design on the linear model
clear; clc; close all
P = svarog_params();
s = tf('s');

%% plant and open-loop poles
Gp = -1/(P.I*s^2 - P.mgd);
disp('open-loop poles'); disp(pole(Gp))
figure; pzmap(Gp); grid on; title('one pole in the right half plane')

%% closed loop with PD:  I s^2 + Kd s + (Kp - mgd) = 0
Kd = P.Kd;
figure; hold on; grid on
for Kp = [0.1 0.2 P.mgd 0.4 0.85 1.5]
    r = roots([P.I, Kd, Kp - P.mgd]);
    plot(real(r), imag(r), 'x', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', sprintf('Kp = %.2f', Kp));
end
xline(0); legend('Location', 'southwest'); xlabel('Re s'); ylabel('Im s')
title(sprintf('closed-loop poles as Kp increases (mgd = %.3f)', P.mgd))

%% gains from (wn, zeta)
Gcl = (P.Kp + P.Kd*s)/(P.I*s^2 + P.Kd*s + (P.Kp - P.mgd));
disp('closed-loop poles'); disp(pole(Gcl))
figure; step(Gcl, 1); grid on
S = stepinfo(Gcl);
fprintf('wn %.0f  zeta %.2f  ->  Kp %.3f  Kd %.4f   settling %.2f s  overshoot %.1f %%\n', ...
    P.wn, P.zeta, P.Kp, P.Kd, S.SettlingTime, S.Overshoot);

%% constant disturbance: steady tilt = tau_d / (Kp - mgd)
Gd = 1/(P.I*s^2 + P.Kd*s + (P.Kp - P.mgd));
tau_d = P.m*P.g*0.001;
figure; step(Gd*tau_d, 1); grid on; ylabel('tilt (rad)')
title(sprintf('1 mm CoM offset, PD only: settles at %.2f deg', rad2deg(tau_d/(P.Kp - P.mgd))))

%% torque demanded at t = 0 for a 5 deg recovery
fprintf('initial torque demand %.4f N m, motor limit %.4f N m\n', P.Kp*P.theta_rec, P.tau_lim);
