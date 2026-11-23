%% ================================================================
% Wolong Lake: Revised r-n Sensitivity Analysis
%
% Baseline:
%   r = 10 ug/L/day
%   n = 25 ug/L
%   f = 0.03 /day
%
% Sensitivity:
%   r = [5 7.5 10 12.5 15]
%   n = [15 20 25 30 35]
%
% Method:
%   1. Search for multiple equilibria using many initial conditions
%   2. Deduplicate equilibria
%   3. Calculate numerical Jacobian
%   4. Classify equilibrium stability
%   5. Track the stable equilibrium over W
%
% This replaces the previous single-initial-condition ODE approach.
%% ================================================================

clear;
clc;
close all;

%% ================================================================
% 1. BASELINE PARAMETERS
% ================================================================

p.b     = 0.2;       % algal growth rate, day^-1
p.ha    = 25;        % half-saturation constant for algal growth, ug/L
p.pa    = 0.01;      % phosphorus content of algae

p.f     = 0.03;      % flushing rate, day^-1
p.g     = 0.01;      % zooplankton grazing rate, day^-1
p.sv    = 0.02;      % algal mortality rate, day^-1

p.lp1   = 2;         % external P loading, basin 1, ug/L/day
p.lp2   = 5;         % external P loading, basin 2, ug/L/day

p.r     = 10;        % maximum internal P recycling rate, ug/L/day
p.n     = 25;        % recycling half-saturation constant, ug/L
p.q     = 8;         % recycling steepness

p.e     = 0.65;      % fraction of grazed P recycled

p.alpha = 0.15;      % connectivity coefficient
p.zsill = 87.15;     % sill elevation, m
p.k     = 2.0;       % connectivity nonlinearity

%% ================================================================
% 2. PARAMETER RANGES
% ================================================================

r_values = [5 7.5 10 12.5 15];

n_values = [15 20 25 30 35];

Nr = length(r_values);
Nn = length(n_values);

%% ================================================================
% 3. WATER-SURFACE ELEVATION
% ================================================================

W_range = 87.00:0.005:87.35;

NW = length(W_range);

%% ================================================================
% 4. INITIAL CONDITIONS
% ================================================================
%
% Multiple initial conditions are used to search for all equilibria.
%
% State vector:
% x = [A1 P1 A2 P2]
%
% A = algal concentration
% P = phosphorus concentration

A_guesses = [ ...
    0 5 10 20 30 50 80 120 200 500 1000 2000];

P_guesses = [ ...
    0 2 5 10 20 30 50 100 300 600 1000 1500];

initial_guesses = [];

for A1 = A_guesses

    for P1 = P_guesses

        % Symmetric initial condition
        initial_guesses(end+1,:) = ...
            [A1 P1 A1 P1];

        % Mildly asymmetric initial condition
        initial_guesses(end+1,:) = ...
            [A1 P1 0.6*A1 1.2*P1 + 1];

    end
end

% Additional asymmetric initial conditions
specialStarts = [
     5    2    50    5
    10    5   100   10
    30   10   150   15
    50   20   300   30
   100   30   500   50
   300   50   100   20
   500  100    50   10
  1000  300    20    5
  2000  500    50   10
];

initial_guesses = [
    initial_guesses
    specialStarts
];

%% ================================================================
% 5. SOLVER SETTINGS
% ================================================================

options = optimoptions('fsolve', ...
    'Display','off', ...
    'FunctionTolerance',1e-10, ...
    'StepTolerance',1e-10, ...
    'OptimalityTolerance',1e-10, ...
    'MaxIterations',2000, ...
    'MaxFunctionEvaluations',5000);

tol_equilibrium = 1e-7;
tol_duplicate   = 1e-5;

%% ================================================================
% 6. STORAGE
% ================================================================

% Dimensions:
% r x n x W

A1_stable = NaN(Nr,Nn,NW);
P1_stable = NaN(Nr,Nn,NW);

A2_stable = NaN(Nr,Nn,NW);
P2_stable = NaN(Nr,Nn,NW);

total_eq = zeros(Nr,Nn,NW);
stable_eq = zeros(Nr,Nn,NW);

% Maximum real eigenvalue of the stable equilibrium
stable_maxEig = NaN(Nr,Nn,NW);

% Number of unstable equilibria
unstable_eq = zeros(Nr,Nn,NW);

%% ================================================================
% 7. MAIN r-n-W SENSITIVITY LOOP
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('WOLONG LAKE r-n SENSITIVITY ANALYSIS\n');
fprintf('============================================================\n');

for ir = 1:Nr

    for in = 1:Nn

        p_current = p;

        p_current.r = r_values(ir);
        p_current.n = n_values(in);

        fprintf('\n');
        fprintf('r = %.2f, n = %.2f\n', ...
            p_current.r,p_current.n);

        for iw = 1:NW

            W = W_range(iw);

            % ----------------------------------------------------
            % Find all equilibria
            % ----------------------------------------------------

            equilibria = find_equilibria( ...
                p_current, ...
                W, ...
                initial_guesses, ...
                options, ...
                tol_equilibrium, ...
                tol_duplicate);

            total_eq(ir,in,iw) = size(equilibria,1);

            % ----------------------------------------------------
            % Classify stability
            % ----------------------------------------------------

            [stableEq,stableEig,unstableCount] = ...
                classify_equilibria( ...
                equilibria,p_current,W);

            stable_eq(ir,in,iw) = size(stableEq,1);

            unstable_eq(ir,in,iw) = unstableCount;

            % ----------------------------------------------------
            % Store stable equilibrium
            % ----------------------------------------------------

            if ~isempty(stableEq)

                % If more than one stable equilibrium exists,
                % select the stable equilibrium with the lowest P1.
                %
                % This represents the low-phosphorus stable state.
                [~,idx] = min(stableEq(:,2));

                xstable = stableEq(idx,:);

                A1_stable(ir,in,iw) = xstable(1);
                P1_stable(ir,in,iw) = xstable(2);

                A2_stable(ir,in,iw) = xstable(3);
                P2_stable(ir,in,iw) = xstable(4);

                % Eigenvalue information for the selected stable state
                stable_maxEig(ir,in,iw) = stableEig(idx);

            end

        end
    end
end

fprintf('\n');
fprintf('============================================================\n');
fprintf('Sensitivity analysis completed.\n');
fprintf('============================================================\n');

%% ================================================================
% 8. BASELINE RESULT
% ================================================================

[~,ir0] = min(abs(r_values - 10));
[~,in0] = min(abs(n_values - 25));
[~,iw0] = min(abs(W_range - 87.00));

fprintf('\n');
fprintf('BASELINE RESULT\n');
fprintf('------------------------------------------------------------\n');

fprintf('r = %.2f ug/L/day\n',r_values(ir0));
fprintf('n = %.2f ug/L\n',n_values(in0));
fprintf('f = %.3f /day\n',p.f);
fprintf('W = %.3f m\n',W_range(iw0));

fprintf('\nStable A1 = %.6f ug/L\n', ...
    A1_stable(ir0,in0,iw0));

fprintf('Stable P1 = %.6f ug/L\n', ...
    P1_stable(ir0,in0,iw0));

fprintf('Stable A2 = %.6f ug/L\n', ...
    A2_stable(ir0,in0,iw0));

fprintf('Stable P2 = %.6f ug/L\n', ...
    P2_stable(ir0,in0,iw0));

fprintf('Total equilibria = %d\n', ...
    total_eq(ir0,in0,iw0));

fprintf('Stable equilibria = %d\n', ...
    stable_eq(ir0,in0,iw0));

fprintf('Unstable equilibria = %d\n', ...
    unstable_eq(ir0,in0,iw0));

fprintf('Max real eigenvalue of selected stable state = %.6e\n', ...
    stable_maxEig(ir0,in0,iw0));

%% ================================================================
% 9. FIGURE 1
% Stable A1 at baseline W = 87.00 m
% as a function of r and n
% ================================================================

A1_baselineW = squeeze(A1_stable(:,:,iw0));

figure;

imagesc(n_values,r_values,A1_baselineW);

set(gca,'YDir','normal');

xlabel('Recycling half-saturation constant n (\mug/L)');
ylabel('Maximum recycling rate r (\mug/L/day)');

title('Stable equilibrium A_1 at \omega = 87.00 m');

cb = colorbar;
ylabel(cb,'A_1 (\mug/L)');

hold on;

plot(25,10,'ko', ...
    'MarkerSize',9, ...
    'LineWidth',2);

box on;

%% ================================================================
% 10. FIGURE 2
% Stable P1 at baseline W = 87.00 m
% ================================================================

P1_baselineW = squeeze(P1_stable(:,:,iw0));

figure;

imagesc(n_values,r_values,P1_baselineW);

set(gca,'YDir','normal');

xlabel('Recycling half-saturation constant n (\mug/L)');
ylabel('Maximum recycling rate r (\mug/L/day)');

title('Stable equilibrium P_1 at \omega = 87.00 m');

cb = colorbar;
ylabel(cb,'P_1 (\mug/L)');

hold on;

plot(25,10,'ko', ...
    'MarkerSize',9, ...
    'LineWidth',2);

box on;

%% ================================================================
% 11. FIGURE 3
% Number of stable equilibria at W = 87.00 m
% ================================================================

stable_baselineW = squeeze(stable_eq(:,:,iw0));

figure;

imagesc(n_values,r_values,stable_baselineW);

set(gca,'YDir','normal');

xlabel('Recycling half-saturation constant n (\mug/L)');
ylabel('Maximum recycling rate r (\mug/L/day)');

title('Number of stable equilibria at \omega = 87.00 m');

cb = colorbar;
ylabel(cb,'Number of stable equilibria');

hold on;

plot(25,10,'ko', ...
    'MarkerSize',9, ...
    'LineWidth',2);

box on;

%% ================================================================
% 12. FIGURE 4
% Maximum A1 over W range
% ================================================================

A1_max = NaN(Nr,Nn);

for ir = 1:Nr
    for in = 1:Nn

        values = squeeze(A1_stable(ir,in,:));

        if any(~isnan(values))
            A1_max(ir,in) = max(values,[],'omitnan');
        end

    end
end

figure;

imagesc(n_values,r_values,A1_max);

set(gca,'YDir','normal');

xlabel('Recycling half-saturation constant n (\mug/L)');
ylabel('Maximum recycling rate r (\mug/L/day)');

title('Maximum stable A_1 over \omega = 87.00-87.35 m');

cb = colorbar;
ylabel(cb,'Maximum A_1 (\mug/L)');

hold on;

plot(25,10,'ko', ...
    'MarkerSize',9, ...
    'LineWidth',2);

box on;

%% ================================================================
% 13. FIGURE 5
% Stable A1 response to W for each r at baseline n = 25
% ================================================================

figure;
hold on;

[~,in25] = min(abs(n_values - 25));

for ir = 1:Nr

    plot(W_range, ...
        squeeze(A1_stable(ir,in25,:)), ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('r = %.1f',r_values(ir)));

end

xline(p.zsill,'--', ...
    'Sill elevation', ...
    'LineWidth',1.2);

xlabel('Water surface elevation (m)');
ylabel('Stable equilibrium A_1 (\mug/L)');

title('Effect of r on stable A_1 response');

legend('Location','best');

grid on;
box on;

%% ================================================================
% 14. FIGURE 6
% Stable P1 response to W for each r at baseline n = 25
% ================================================================

figure;
hold on;

for ir = 1:Nr

    plot(W_range, ...
        squeeze(P1_stable(ir,in25,:)), ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('r = %.1f',r_values(ir)));

end

xline(p.zsill,'--', ...
    'Sill elevation', ...
    'LineWidth',1.2);

xlabel('Water surface elevation (m)');
ylabel('Stable equilibrium P_1 (\mug/L)');

title('Effect of r on stable P_1 response');

legend('Location','best');

grid on;
box on;

%% ================================================================
% 15. FIGURE 7
% Stable A1 response to W for each n at baseline r = 10
% ================================================================

figure;
hold on;

[~,ir10] = min(abs(r_values - 10));

for in = 1:Nn

    plot(W_range, ...
        squeeze(A1_stable(ir10,in,:)), ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('n = %.0f',n_values(in)));

end

xline(p.zsill,'--', ...
    'Sill elevation', ...
    'LineWidth',1.2);

xlabel('Water surface elevation (m)');
ylabel('Stable equilibrium A_1 (\mug/L)');

title('Effect of n on stable A_1 response');

legend('Location','best');

grid on;
box on;

%% ================================================================
% 16. FIGURE 8
% Stable P1 response to W for each n at baseline r = 10
% ================================================================

figure;
hold on;

for in = 1:Nn

    plot(W_range, ...
        squeeze(P1_stable(ir10,in,:)), ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('n = %.0f',n_values(in)));

end

xline(p.zsill,'--', ...
    'Sill elevation', ...
    'LineWidth',1.2);

xlabel('Water surface elevation (m)');
ylabel('Stable equilibrium P_1 (\mug/L)');

title('Effect of n on stable P_1 response');

legend('Location','best');

grid on;
box on;

%% ================================================================
% 17. FIGURE 9
% Stable equilibrium count over r-n-W
%
% For each r-n combination, calculate the minimum and maximum
% number of stable equilibria over the W range.
% ================================================================

minStable = NaN(Nr,Nn);
maxStable = NaN(Nr,Nn);

for ir = 1:Nr
    for in = 1:Nn

        values = squeeze(stable_eq(ir,in,:));

        minStable(ir,in) = min(values);
        maxStable(ir,in) = max(values);

    end
end

figure;

imagesc(n_values,r_values,maxStable);

set(gca,'YDir','normal');

xlabel('Recycling half-saturation constant n (\mug/L)');
ylabel('Maximum recycling rate r (\mug/L/day)');

title('Maximum number of stable equilibria over \omega range');

cb = colorbar;
ylabel(cb,'Maximum stable equilibrium count');

hold on;

plot(25,10,'ko', ...
    'MarkerSize',9, ...
    'LineWidth',2);

box on;

%% ================================================================
% 18. FIGURE 10
% Stability of baseline parameterization over W
% ================================================================

figure;

plot(W_range, ...
    squeeze(stable_maxEig(ir10,in25,:)), ...
    'LineWidth',1.8);

hold on;

yline(0,'k--','Stability boundary');

xline(p.zsill,'--', ...
    'Sill elevation', ...
    'LineWidth',1.2);

xlabel('Water surface elevation (m)');
ylabel('Maximum real eigenvalue (d^{-1})');

title('Stability of baseline equilibrium');

grid on;
box on;

%% ================================================================
% 19. CHECK FOR POSSIBLE STABILITY LOSS
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('STABILITY CHECK\n');
fprintf('============================================================\n');

for ir = 1:Nr

    for in = 1:Nn

        eigvals = squeeze( ...
            stable_maxEig(ir,in,:));

        valid = ~isnan(eigvals);

        if any(valid)

            maxValue = max(eigvals(valid));

            minValue = min(eigvals(valid));

            fprintf(['r = %5.2f, n = %5.2f: ', ...
                     'stable eigenvalue range = ', ...
                     '[%+.4e, %+.4e]\n'], ...
                     r_values(ir), ...
                     n_values(in), ...
                     minValue, ...
                     maxValue);

        else

            fprintf(['r = %5.2f, n = %5.2f: ', ...
                     'NO STABLE EQUILIBRIUM FOUND\n'], ...
                     r_values(ir), ...
                     n_values(in));

        end
    end
end

%% ================================================================
% 20. SAVE RESULTS
% ================================================================

save('Wolong_r_n_sensitivity_revised.mat', ...
    'p', ...
    'r_values', ...
    'n_values', ...
    'W_range', ...
    'A1_stable', ...
    'P1_stable', ...
    'A2_stable', ...
    'P2_stable', ...
    'total_eq', ...
    'stable_eq', ...
    'unstable_eq', ...
    'stable_maxEig');

fprintf('\n');
fprintf('Results saved as:\n');
fprintf('Wolong_r_n_sensitivity_revised.mat\n');

%% ================================================================
% LOCAL FUNCTION 1
% Model equations
%% ================================================================

function dx = lake_rhs(x,p,W)

A1 = x(1);
P1 = x(2);
A2 = x(3);
P2 = x(4);

% Available phosphorus
P1avail = max(0,P1 - p.pa*A1);
P2avail = max(0,P2 - p.pa*A2);

% Internal phosphorus recycling
hill1 = (max(P1,0)/p.n)^p.q;
hill2 = (max(P2,0)/p.n)^p.q;

R1 = p.r * hill1/(1 + hill1);
R2 = p.r * hill2/(1 + hill2);

% Algal growth
G1 = p.b*A1 * ...
    P1avail/(p.ha + P1avail);

G2 = p.b*A2 * ...
    P2avail/(p.ha + P2avail);

% Water-level-dependent connectivity
if W <= p.zsill
    Dw = 0;
else
    Dw = p.alpha*(W-p.zsill)^p.k;
end

% Algal equations
dA1 = G1 ...
    - (p.f+p.g+p.sv)*A1 ...
    + Dw*(A2-A1);

dA2 = G2 ...
    - (p.f+p.g+p.sv)*A2 ...
    + Dw*(A1-A2);

% Phosphorus equations
dP1 = p.lp1 ...
    + R1 ...
    + p.e*p.g*A1 ...
    - G1 ...
    - p.f*P1 ...
    + Dw*(P2-P1);

dP2 = p.lp2 ...
    + R2 ...
    + p.e*p.g*A2 ...
    - G2 ...
    - p.f*P2 ...
    + Dw*(P1-P2);

dx = [dA1;dP1;dA2;dP2];

end

%% ================================================================
% LOCAL FUNCTION 2
% Find all equilibria
%% ================================================================

function equilibria = find_equilibria( ...
    p,W,initial_guesses,options, ...
    tol_equilibrium,tol_duplicate)

equilibria = [];

for i = 1:size(initial_guesses,1)

    x0 = initial_guesses(i,:)';

    try

        [xsol,~,exitflag] = fsolve( ...
            @(x) lake_rhs(x,p,W), ...
            x0, ...
            options);

        residual = norm( ...
            lake_rhs(xsol,p,W),inf);

        if exitflag > 0 && residual < tol_equilibrium

            % Reject clearly negative concentrations
            if all(xsol >= -1e-6)

                xsol(abs(xsol)<1e-8) = 0;

                % Check duplicate
                if isempty(equilibria)

                    equilibria = xsol';

                else

                    distance = sqrt(sum( ...
                        (equilibria-xsol').^2,2));

                    if all(distance > tol_duplicate)

                        equilibria(end+1,:) = xsol';

                    end
                end
            end
        end

    catch
        % Ignore failed fsolve attempts
    end
end

end

%% ================================================================
% LOCAL FUNCTION 3
% Stability classification
%% ================================================================

function [stableEq,stableMaxEig,unstableCount] = ...
    classify_equilibria(equilibria,p,W)

stableEq = [];
stableMaxEig = [];
unstableCount = 0;

for i = 1:size(equilibria,1)

    xeq = equilibria(i,:)';

    J = numerical_jacobian( ...
        @(x) lake_rhs(x,p,W),xeq);

    lambda = eig(J);

    maxReal = max(real(lambda));

    % Stable equilibrium
    if maxReal < -1e-8

        stableEq(end+1,:) = xeq';

        stableMaxEig(end+1,1) = maxReal;

    else

        unstableCount = unstableCount + 1;

    end
end

end

%% ================================================================
% LOCAL FUNCTION 4
% Numerical Jacobian
%% ================================================================

function J = numerical_jacobian(fun,x)

n = length(x);

J = zeros(n);

for j = 1:n

    h = 1e-6*max(1,abs(x(j)));

    xp = x;
    xm = x;

    xp(j) = xp(j)+h;
    xm(j) = xm(j)-h;

    J(:,j) = ...
        (fun(xp)-fun(xm))/(2*h);

end

end