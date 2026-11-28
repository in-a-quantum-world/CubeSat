%%  nonlinear discrete simulation with motor limits, noise and lag
clear; clc; close all
P = svarog_params();
show = @(name, R) fprintf('%-22s rise %.2f  over %.2f  settle %.2f  rmse %.2f  peak %.4f N m %4.0f rpm  sat %2.0f%%%s\n', ...
    name, R.rise, R.overshoot, R.settle, R.rmse, R.peak_tau, R.peak_rpm, 100*R.sat_frac, repmat('  FELL', R.fell));

%% 5 deg recovery three motors
R0 = svarog_simulate(P);
Pl = P;  Pl.tau_max = 0.020;  Pl.tau_lim = 0.020;
Pw = P;  Pw.rpm_max = 150;    Pw.w_max = 150*2*pi/60;
Rl = svarog_simulate(Pl);
Rw = svarog_simulate(Pw);
show('GM2804 nominal', svarog_metrics(R0));
show('torque 0.020 N m', svarog_metrics(Rl));
show('wheel limit 150 rpm', svarog_metrics(Rw));
plot_runs({R0, Rl, Rw}, {'nominal', 'torque 0.020', 'wheel 150 rpm'}, P, '5 deg recovery');

%% disturbances from upright
Rp = svarog_simulate(P, theta0=0, tau_dist=0.01, dist_t=[1 1.2]);
Rs = svarog_simulate(P, theta0=0, tau_dist=P.m*P.g*0.001, T=6, Ki=0);
Ri = svarog_simulate(P, theta0=0, tau_dist=P.m*P.g*0.001, T=6);
show('0.01 N m pulse', svarog_metrics(Rp));
show('1 mm offset, PD', svarog_metrics(Rs));
show('1 mm offset, PID', svarog_metrics(Ri));
plot_runs({Rp, Rs, Ri}, {'pulse', '1 mm offset PD', '1 mm offset PID'}, P, 'disturbance rejection');

%% Monte Carlo nominal gains on 200 perturbed plants
rng(1); N = 200; fell = false(N,1); settle = nan(N,1); tg = zeros(N,1); tl = zeros(N,1);
for k = 1:N
    Q = P;
    Q.m_cube = P.m_cube*(0.9 + 0.3*rand);   Q.h_cube = P.h_cube*(0.8 + 0.5*rand);
    Q.m_w    = P.m_w*(0.7 + 0.6*rand);      Q.tau_max = P.tau_max*(0.8 + 0.3*rand);
    Q.rpm_max = P.rpm_max*(0.6 + 0.4*rand);
    Q.m = Q.m_cube + Q.m_batt;  Q.d = (Q.m_cube*Q.h_cube + Q.m_batt*Q.h_batt)/Q.m;
    Q.I = Q.m_cube*Q.a^2/6 + Q.m_cube*Q.h_cube^2 + Q.m_batt*Q.h_batt^2;
    Q.I_w = Q.m_w*Q.r_w^2;  Q.mgd = Q.m*Q.g*Q.d;  Q.w_max = Q.rpm_max*2*pi/60;
    Q.tau_lim = min(Q.tau_max, Q.Kt*Q.I_max);
    M = svarog_metrics(svarog_simulate(Q, T=2, seed=k, Kp=P.Kp, Kd=P.Kd));
    fell(k) = M.fell;  settle(k) = M.settle;  tg(k) = Q.mgd*sin(P.theta_rec);  tl(k) = Q.tau_lim;
end
fprintf('Monte Carlo: fell %d/%d, settling median %.2f s, 90th pct %.2f s\n', ...
    sum(fell), N, median(settle(~fell), 'omitnan'), prctile(settle(~fell), 90));
figure; scatter(tg, tl, 14, double(fell), 'filled'); colormap([0 0.4 0.8; 0.8 0 0]); grid on; hold on
x = linspace(0.015, 0.035, 2); plot(x, x, 'k--', x, 1.5*x, 'k:')
xlabel('gravity torque at 5 deg (N m)'); ylabel('motor torque limit (N m)'); title('red = fell')

%% helper func
function plot_runs(Rs, names, P, ttl)
figure; ax = gobjects(3,1);
for i = 1:3, ax(i) = subplot(3,1,i); hold on; grid on; end
for j = 1:numel(Rs)
    plot(ax(1), Rs{j}.t, Rs{j}.theta, 'LineWidth', 1.4, 'DisplayName', names{j});
    plot(ax(2), Rs{j}.t, Rs{j}.rpm,   'LineWidth', 1.4);
    plot(ax(3), Rs{j}.t, Rs{j}.tau,   'LineWidth', 1.4);
end
yline(ax(2), [P.rpm_max -P.rpm_max], 'r--');  yline(ax(3), [P.tau_lim -P.tau_lim], 'r--');
ylabel(ax(1), 'tilt (deg)'); ylabel(ax(2), 'wheel (rpm)'); ylabel(ax(3), '\tau (N m)'); xlabel(ax(3), 't (s)')
legend(ax(1), 'Location', 'best'); title(ax(1), ttl)
end
