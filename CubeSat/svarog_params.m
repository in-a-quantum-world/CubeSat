function P = svarog_params()
% Plant, motor, requirement and controller parameters

% cube
P.m_cube = 0.500;   P.h_cube = 0.045;        % kg, m  
P.m_batt = 0.230;   P.h_batt = 0.010;        % battery pack + BMS at the base
P.a      = 0.100;
P.m = P.m_cube + P.m_batt;
P.d = (P.m_cube*P.h_cube + P.m_batt*P.h_batt)/P.m;
P.I = P.m_cube*P.a^2/6 + P.m_cube*P.h_cube^2 + P.m_batt*P.h_batt^2;   % about the pin

% flywheel (rim mass)
P.m_w = 0.150;  P.r_w = 0.035;
P.I_w = P.m_w*P.r_w^2;

% motor: iPower GM2804 + AS5048A, SimpleFOCMini
P.tau_max = 0.030;              % N m, 250-350 gcm listed
P.rpm_max = 1600;               % no-load at 10 V
P.Kt      = 0.030/0.8;          % N m/A
P.I_max   = 1.5;                % A, current clamp set in SimpleFOC
P.w_max   = P.rpm_max*2*pi/60;
P.tau_lim = min(P.tau_max, P.Kt*P.I_max);

% requirement and loop
P.theta_rec = deg2rad(5);
P.f_ctrl    = 200;              % Hz
P.delay     = 3;                % control periods of measurement lag
P.angle_noise = deg2rad(0.05);  % rad rms
P.gyro_noise  = deg2rad(0.05);  % rad/s rms

% controller (from part4_tune)
P.wn = 18;  P.zeta = 0.8;  P.Ki = 1;
P.g   = 9.81;
P.mgd = P.m*P.g*P.d;
P.Kp  = P.I*P.wn^2 + P.mgd;
P.Kd  = 2*P.zeta*P.I*P.wn;

if nargout == 0
    fprintf('m %.3f kg  d %.1f cm  I %.3f g m^2  I_w %.0f mg m^2\n', P.m, 100*P.d, 1e3*P.I, 1e6*P.I_w);
    fprintf('mgd %.4f N m/rad   gravity at 5 deg %.4f N m   motor %.4f N m  (%.2fx)\n', ...
        P.mgd, P.mgd*sin(P.theta_rec), P.tau_lim, P.tau_lim/(P.mgd*sin(P.theta_rec)));
    fprintf('unstable pole %.1f 1/s   Kp %.3f   Kd %.4f\n', sqrt(P.mgd/P.I), P.Kp, P.Kd);
end
end
