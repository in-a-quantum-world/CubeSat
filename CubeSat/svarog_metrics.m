function M = svarog_metrics(R, band)
% Rise (90 % of initial error removed) overshoot past target, settling into +/- band, RMSE
if nargin < 2, band = 0.2; end
th = R.theta;  t = R.t;  th0 = th(1);
k = find(abs(th) <= 0.1*abs(th0), 1);
M.rise = NaN;  if ~isempty(k), M.rise = t(k); end
M.overshoot = max(0, -sign(th0)*min(sign(th0)*th));
out = find(abs(th) > band, 1, 'last');
if isempty(out), M.settle = 0; elseif out < numel(t), M.settle = t(out+1); else, M.settle = NaN; end
M.rmse     = sqrt(mean(th.^2));
M.peak_tau = max(abs(R.tau));
M.peak_rpm = max(abs(R.rpm));
M.sat_frac = mean(R.sat);
n_last     = min(numel(t)-1, round(0.5/(t(2)-t(1))));
M.ripple   = std(R.tau(end-n_last:end));
M.fell     = max(abs(th)) >= 89;
end
