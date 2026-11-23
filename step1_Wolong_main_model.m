clear;
clc;
close all

%% 1. Parameters)
p.b = 0.2;
p.ha = 25;
p.pa = 0.01;
p.f = 0.03; 
p.g = 0.01;
p.sv = 0.02;
p.lp1 = 2;
p.lp2 = 5;   
p.r = 10;
p.n = 25;
p.q = 8;
p.e = 0.65;
p.alpha = 0.15;

% --- Hydrological threshold---
p.zsill = 87.15;    % 物理门槛抬高到常态水位之上
p.k = 2.0;          % 增加非线性，使突变点后移
W_range = 87.0:0.005:87.35; % 从常态水位扫描到高水位

%% 2. Storage
P1_steady = zeros(size(W_range));
A1_steady = zeros(size(W_range));

options = odeset('RelTol',1e-8,'AbsTol',1e-10);
tspan = [0 5000];

%% 3. Simulation loop
for i = 1:length(W_range)
    W = W_range(i);

    % Hydrological connectivity
    D_w = (W > p.zsill) * p.alpha * (W - p.zsill)^p.k;

    % ODE system
    ode_fun = @(t, x) [
        % A1
        p.b*x(1)*((x(2)-p.pa*x(1))/(p.ha+(x(2)-p.pa*x(1)))) ...
        - (p.f+p.g+p.sv)*x(1) + D_w*(x(3)-x(1));

        % P1
        p.lp1 + p.r*(x(2)^p.q/(x(2)^p.q+p.n^p.q)) + p.e*p.g*x(1) ...
        - p.b*x(1)*((x(2)-p.pa*x(1))/(p.ha+(x(2)-p.pa*x(1)))) ...
        - p.f*x(2) + D_w*(x(4)-x(2));

        % A2
        p.b*x(3)*((x(4)-p.pa*x(3))/(p.ha+(x(4)-p.pa*x(3)))) ...
        - (p.f+p.g+p.sv)*x(3) + D_w*(x(1)-x(3));

        % P2
        p.lp2 + p.r*(x(4)^p.q/(x(4)^p.q+p.n^p.q)) + p.e*p.g*x(3) ...
        - p.b*x(3)*((x(4)-p.pa*x(3))/(p.ha+(x(4)-p.pa*x(3)))) ...
        - p.f*x(4) + D_w*(x(2)-x(4))
    ];

    % Initial conditions
    x0 = [30, 20, 30, 20];

    % Solve
    [~, sol] = ode15s(ode_fun, tspan, x0, options);

    % Steady state
    A1_steady(i) = sol(end,1);
    P1_steady(i) = sol(end,2);
end

P1_steady(1)
A1_steady(1)

%% 4. Sensitivity analysis
% dP1/dW describes how strongly the equilibrium P concentration
% responds to changes in water surface elevation.

dP1_dW = diff(P1_steady) ./ diff(W_range);
W_mid = W_range(1:end-1) + diff(W_range)/2;

% Since P1 decreases with W, the strongest response corresponds
% to the most negative derivative.
[sens_min, idx] = min(dP1_dW);
W_sensitive = W_mid(idx);

fprintf('\nMaximum-magnitude phosphorus sensitivity:\n');
fprintf('Water surface elevation = %.4f m\n', W_sensitive);
fprintf('dP1/dW = %.4f (ug/L)/m\n', sens_min);

%% =========================
%% FIGURE 3: P1 vs Water Level
%% =========================
figure('Color','w','Position',[100 100 700 500]);

plot(W_range, P1_steady, 'k-', 'LineWidth', 2.5); hold on;

% sill line
xline(p.zsill, '--', 'Color',[0.5 0.5 0.5], 'LineWidth',1.5);

xlabel('Water Level (m)');
ylabel('North Basin P Concentration (\mug/L)');
title('Steady-state Nutrient Dynamics');
grid on;

%% =========================
%% FIGURE 4: Sensitivity Analysis
%% =========================
figure('Color','w','Position',[100 100 850 550]);

% -------------------------------------------------
% Left axis: equilibrium P concentration
% -------------------------------------------------
yyaxis left

plot(W_range, P1_steady, 'k-', 'LineWidth', 2.5);
hold on;

ylabel('North Basin P Concentration (\mug/L)');

% Sill elevation
xline(p.zsill, '--', ...
    'Color',[0.5 0.5 0.5], ...
    'LineWidth',1.5);

% Baseline water surface elevation
xline(W_range(1), ':', ...
    'Color',[0 0.5 0], ...
    'LineWidth',1.5);

% -------------------------------------------------
% Right axis: sensitivity
% -------------------------------------------------
yyaxis right

plot(W_mid, dP1_dW, 'r-', 'LineWidth', 2);

ylabel('Sensitivity, dP/d\omega ((\mug/L)/m)');
ax = gca;
ax.YColor = 'r';

% Mark strongest sensitivity point
plot(W_sensitive, sens_min, 'bo', ...
    'MarkerFaceColor','b', ...
    'MarkerSize',7);

% Vertical line at strongest sensitivity
xline(W_sensitive, '--b', ...
    'LineWidth',1.5);

% -------------------------------------------------
% Label positions
% -------------------------------------------------

% Label baseline
text(W_range(1) + 0.005, ...
     0.90*max(dP1_dW), ...
     sprintf('Baseline: %.2f m', W_range(1)), ...
     'Color',[0 0.5 0], ...
     'FontSize',10, ...
     'VerticalAlignment','top');

% Label strongest sensitivity
text(W_sensitive + 0.005, ...
     sens_min + 0.3, ...
     sprintf('Strongest sensitivity: %.3f m', W_sensitive), ...
     'Color','b', ...
     'FontSize',10, ...
     'VerticalAlignment','bottom');

xlabel('Water Surface Elevation (m)');
title('Sensitivity of Equilibrium P Concentration to Water Surface Elevation');

grid on;
box on;

legend({'Equilibrium P concentration', ...
        'Sill elevation', ...
        'Baseline water surface elevation', ...
        'dP/d\omega', ...
        'Strongest sensitivity'}, ...
        'Location','best');
%% =========================
%% FIGURE 5: A1 vs Water Level
%% =========================
figure('Color','w','Position',[100 100 700 500]);
       
plot(W_range, A1_steady, 'g-', 'LineWidth', 2.5); hold on;

% sill line
xline(p.zsill, '--', 'Color',[0.5 0.5 0.5], 'LineWidth',1.5);

xlabel('Water Level (m)');
ylabel('North Basin Algal Biomass (\mug/L)');
title('Algal Response');
grid on;