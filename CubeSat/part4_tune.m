%% gain tuning by sweep over (wn, zeta), lag test
clear; clc; close all
P = svarog_params();
WN = [6 8 10 12 15 18 22 26 30];
ZE = [0.5 0.7 0.8 1.0 1.2];

%% sweep on the nominal model
settle = nan(numel(ZE), numel(WN));  ripple = settle;  satf = settle;  ok = false(size(settle));
fprintf('%4s %5s %6s %7s | %5s %5s %6s %5s %4s %6s\n', 'wn', 'zeta', 'Kp', 'Kd', 'rise', 'over', 'settle', 'rmse', 'sat%', 'ripple');
for i = 1:numel(ZE)
    for j = 1:numel(WN)
        Kp = P.I*WN(j)^2 + P.mgd;  Kd = 2*ZE(i)*P.I*WN(j);
        Q = P;  Q.delay = 0;
        M = svarog_metrics(svarog_simulate(Q, Kp=Kp, Kd=Kd, Ki=0));
        settle(i,j) = M.settle;  ripple(i,j) = M.ripple;  satf(i,j) = M.sat_frac;
        ok(i,j) = ~M.fell && M.sat_frac <= 0.15 && M.ripple <= 0.1*P.tau_lim && M.overshoot <= 1 && ~isnan(M.settle);
        fprintf('%4.0f %5.2f %6.3f %7.4f | %5.2f %5.2f %6.2f %5.2f %4.0f %6.4f %s\n', ...
            WN(j), ZE(i), Kp, Kd, M.rise, M.overshoot, M.settle, M.rmse, 100*M.sat_frac, M.ripple, repmat('x', ~ok(i,j)));
    end
end

%% lag test: 3 control periods of measurement delay
lag_ok = false(size(ok));
for i = 1:numel(ZE)
    for j = 1:numel(WN)
        if ~ok(i,j), continue; end
        Kp = P.I*WN(j)^2 + P.mgd;  Kd = 2*ZE(i)*P.I*WN(j);
        M = svarog_metrics(svarog_simulate(P, Kp=Kp, Kd=Kd, Ki=0));
        lag_ok(i,j) = ~M.fell && M.overshoot <= 1.5 && ~isnan(M.settle);
    end
end

%% pick lowest wn within 30 % of the best settling time among lag survivors
best = min(settle(lag_ok));
cand = lag_ok & settle <= 1.3*best;
[i, j] = find(cand);
[~, k] = min(WN(j) + 0.01*abs(ZE(i) - 0.8));
wn = WN(j(k));  zeta = ZE(i(k));
Kp = P.I*wn^2 + P.mgd;  Kd = 2*zeta*P.I*wn;
fprintf('\nchosen: wn %.0f  zeta %.1f  ->  Kp %.3f  Kd %.4f\n', wn, zeta, Kp, Kd);

%% heatmaps
figure;
data = {settle, ripple, satf};  names = {'settling (s)', 'torque ripple (N m)', 'saturation fraction'};
for q = 1:3
    subplot(1,3,q); imagesc(data{q}); colorbar; axis xy
    set(gca, 'XTick', 1:numel(WN), 'XTickLabel', WN, 'YTick', 1:numel(ZE), 'YTickLabel', ZE)
    xlabel('\omega_n'); ylabel('\zeta'); title(names{q}); hold on
    [ii, jj] = find(~lag_ok); plot(jj, ii, 'rx', 'MarkerSize', 8, 'LineWidth', 2)
    plot(j(k), i(k), 'wo', 'MarkerSize', 12, 'LineWidth', 2)
end

%% Ki sweep on a 1 mm offset held from upright
fprintf('\nKi   tilt at 2 s   wheel saturates at\n');
for Ki = [0 1 2 3 5]
    R = svarog_simulate(P, theta0=0, tau_dist=P.m*P.g*0.001, T=4, Kp=Kp, Kd=Kd, Ki=Ki);
    ks = find(abs(R.rpm) >= 0.99*P.rpm_max, 1);
    ts = NaN;  if ~isempty(ks), ts = R.t(ks); end
    fprintf('%2.0f   %+6.2f deg    %5.2f s\n', Ki, R.theta(2*P.f_ctrl), ts);
end
