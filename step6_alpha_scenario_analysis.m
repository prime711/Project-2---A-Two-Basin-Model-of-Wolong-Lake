%% ================================================================
% WOLONG LAKE ALPHA SCENARIO ANALYSIS
% Test whether hydrological connectivity strength alpha
% produces changes in equilibrium structure or possible bifurcation
%
% Baseline ecological parameters are retained.
% Water-surface elevation is fixed at W = 87.30 m,
% which is above the sill elevation (87.15 m).
%
% Only alpha is varied.
%
% No formal fold refinement is performed.
% No hysteresis simulation is performed.
%% ================================================================

clear;
clc;
close all;

%% ================================================================
% 1. MODEL PARAMETERS
% ================================================================

p.b     = 0.2;          % d^-1
p.ha    = 25;           % ug/L
p.pa    = 0.01;

p.f     = 0.03;         % d^-1
p.g     = 0.01;         % d^-1
p.sv    = 0.02;         % d^-1

p.lp1   = 2;            % ug/L/day
p.lp2   = 5;            % ug/L/day

p.r     = 10;           % ug/L/day
p.n     = 25;           % ug/L
p.q     = 8;
p.e     = 0.65;

% Hydrological connectivity parameters
p.alpha = 0.15;         % baseline value; varied below
p.zsill = 87.15;        % m
p.k     = 2.0;

%% ================================================================
% 2. FIXED WATER-SURFACE ELEVATION
% ================================================================

W = 87.30;              % m

% IMPORTANT:
% W > zsill, therefore alpha affects connectivity.

%% ================================================================
% 3. ALPHA VALUES TO TEST
% ================================================================

alpha_values = [ ...
    0 ...
    0.05 ...
    0.10 ...
    0.15 ...
    0.20 ...
    0.30 ...
    0.50 ...
    0.75 ...
    1.00 ];

%% ================================================================
% 4. DISPLAY PARAMETERS
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf(' WOLONG LAKE ALPHA SCENARIO ANALYSIS\n');
fprintf('============================================================\n\n');

fprintf('Fixed water-surface elevation:\n');
fprintf('  W      = %.4f m\n',W);
fprintf('  sill   = %.4f m\n',p.zsill);
fprintf('  W-sill = %.4f m\n\n',W-p.zsill);

fprintf('Baseline parameterization:\n');
fprintf('  b      = %.4f d^-1\n',p.b);
fprintf('  ha     = %.2f ug/L\n',p.ha);
fprintf('  pa     = %.4f\n',p.pa);
fprintf('  f      = %.4f d^-1\n',p.f);
fprintf('  g      = %.4f d^-1\n',p.g);
fprintf('  sv     = %.4f d^-1\n',p.sv);
fprintf('  lp1    = %.2f ug/L/day\n',p.lp1);
fprintf('  lp2    = %.2f ug/L/day\n',p.lp2);
fprintf('  r      = %.2f ug/L/day\n',p.r);
fprintf('  n      = %.2f ug/L\n',p.n);
fprintf('  q      = %.2f\n',p.q);
fprintf('  e      = %.2f\n',p.e);
fprintf('  k      = %.2f\n\n',p.k);

fprintf('Alpha values to be tested:\n');
disp(alpha_values);

%% ================================================================
% 5. INITIAL GUESSES
% ================================================================

% Main ecological-scale guesses
A_guesses = [ ...
      1
      5
     10
     20
     30
     40
     50
     70
    100
    150
    250
    500
   1000 ];

P_guesses = [ ...
      1
      5
     10
     15
     20
     30
     50
    100
    300
   1000
   3000
   6000
  10000 ];

starts = [];

%% ------------------------------------------------
% Balanced states
% ------------------------------------------------

for i = 1:length(A_guesses)

    for j = 1:length(P_guesses)

        x0 = [ ...
            A_guesses(i), ...
            P_guesses(j), ...
            A_guesses(i), ...
            P_guesses(j) ];

        starts = [starts; x0]; %#ok<AGROW>

    end

end

%% ------------------------------------------------
% Asymmetric states
% ------------------------------------------------

asymmetricStarts = [

     10    10    30    20
     20    10    40    30
     30    20    50    30
     50    20    30    10
     70    30    40    20
     10    20    30    50
     20    30    50    50
     30    20    50   100
     50    50    30    20

    100    50   300   100
    300   100   100    30
    500    50   300   100
    300    30   500    50
    500   100   100    20

   1000   100    500    50
   1500   500   1000   300
   2000  1000   1500   500
   2500  3000   2000  1000
   3000 10000   3000 10000

     30  1000     30  3000
     50  3000     50  6000
    100  6000    100 10000

];

starts = [starts; asymmetricStarts];

%% ------------------------------------------------
% Explicit boundary equilibria
%
% These are added because the previous analysis showed
% that equilibria with A = 0 can otherwise be missed.
% ------------------------------------------------

boundaryStarts = [

      0   400      0   1200
      0   400    500     20
     30    10      0   1200
     30    10    500     20

      0   400    100    100
     30    10    100    100

      0   400    300    100
      0   400    500    100
      0   400    700    100

];

starts = [starts; boundaryStarts];

%% ------------------------------------------------
% Remove duplicate initial guesses
% ------------------------------------------------

starts = unique(starts,'rows');

fprintf('Number of initial guesses: %d\n\n',size(starts,1));

%% ================================================================
% 6. FSOLVE OPTIONS
% ================================================================

options = optimoptions('fsolve', ...
    'Display','off', ...
    'FunctionTolerance',1e-10, ...
    'StepTolerance',1e-10, ...
    'OptimalityTolerance',1e-10, ...
    'MaxIterations',1000, ...
    'MaxFunctionEvaluations',5000);

%% ================================================================
% 7. STORAGE
% ================================================================

% Columns of alphaResults:
%
% 1 = alpha
% 2 = number of equilibria
% 3 = number of stable equilibria
% 4 = number of non-stable equilibria
% 5 = minimum absolute lambdaMax
% 6 = maximum lambdaMax
% 7 = maximum A1
% 8 = maximum P1

alphaResults = [];

% Store all equilibria from all alpha values
allAlphaEq = [];

%% ================================================================
% 8. EQUILIBRIUM SEARCH FOR EACH ALPHA
% ================================================================

fprintf('Searching for equilibria...\n');

for ia = 1:length(alpha_values)

    p.alpha = alpha_values(ia);

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('ALPHA = %.4f\n',p.alpha);
    fprintf('============================================================\n');

    % Temporary storage for this alpha
    %
    % Columns:
    % 1 = A1
    % 2 = P1
    % 3 = A2
    % 4 = P2
    % 5 = lambdaMax
    % 6 = stable
    % 7 = residual

    eqAtAlpha = [];

    %% ------------------------------------------------------------
    % Search from every initial guess
    % ------------------------------------------------------------

    for is = 1:size(starts,1)

        x0 = starts(is,:)';

        try

            [xsol,fval,exitflag] = fsolve( ...
                @(x) lake_rhs(x,W,p), ...
                x0, ...
                options);

        catch

            continue;

        end

        %% --------------------------------------------------------
        % Check convergence
        % --------------------------------------------------------

        if exitflag <= 0
            continue;
        end

        if any(~isfinite(xsol))
            continue;
        end

        %% --------------------------------------------------------
        % Physical constraints
        % --------------------------------------------------------

        if any(xsol < -1e-6)
            continue;
        end

        % Remove tiny negative numerical values
        xsol = max(xsol,0);

        %% --------------------------------------------------------
        % Equilibrium residual
        % --------------------------------------------------------

        residual = norm(fval,inf);

        if residual > 1e-7
            continue;
        end

        %% --------------------------------------------------------
        % Jacobian and stability
        % --------------------------------------------------------

        J = numerical_jacobian( ...
            @(x) lake_rhs(x,W,p), ...
            xsol);

        eigJ = eig(J);

        lambdaMax = max(real(eigJ));

        if lambdaMax < -1e-7
            stable = 1;
        else
            stable = 0;
        end

        %% --------------------------------------------------------
        % Check duplicate equilibrium
        % --------------------------------------------------------

        isDuplicate = false;

        if ~isempty(eqAtAlpha)

            for ie = 1:size(eqAtAlpha,1)

                old = eqAtAlpha(ie,1:4)';

                scale = max(1,abs(old));

                relativeDifference = ...
                    max(abs(xsol-old)./scale);

                if relativeDifference < 1e-5

                    isDuplicate = true;
                    break;

                end

            end

        end

        %% --------------------------------------------------------
        % Store unique equilibrium
        % --------------------------------------------------------

        if ~isDuplicate

            newEq = [ ...
                xsol(1), ...
                xsol(2), ...
                xsol(3), ...
                xsol(4), ...
                lambdaMax, ...
                stable, ...
                residual ];

            eqAtAlpha = [eqAtAlpha; newEq]; %#ok<AGROW>

        end

    end

    %% ------------------------------------------------------------
    % Sort equilibria
    % ------------------------------------------------------------

    if ~isempty(eqAtAlpha)

        eqAtAlpha = sortrows(eqAtAlpha,[1 2 3 4]);

    end

    %% ------------------------------------------------------------
    % Summary for this alpha
    % ------------------------------------------------------------

    nEq = size(eqAtAlpha,1);

    if nEq > 0

        stableEq = eqAtAlpha(eqAtAlpha(:,6)==1,:);
        nonStableEq = eqAtAlpha(eqAtAlpha(:,6)==0,:);

        nStable = size(stableEq,1);
        nNonStable = size(nonStableEq,1);

        minAbsLambda = min(abs(eqAtAlpha(:,5)));
        maxLambda = max(eqAtAlpha(:,5));

        maxA1 = max(eqAtAlpha(:,1));
        maxP1 = max(eqAtAlpha(:,2));

    else

        nStable = 0;
        nNonStable = 0;
        minAbsLambda = NaN;
        maxLambda = NaN;
        maxA1 = NaN;
        maxP1 = NaN;

    end

    %% ------------------------------------------------------------
    % Save summary
    % ------------------------------------------------------------

    alphaResults = [ ...
        alphaResults;
        p.alpha, ...
        nEq, ...
        nStable, ...
        nNonStable, ...
        minAbsLambda, ...
        maxLambda, ...
        maxA1, ...
        maxP1 ]; %#ok<AGROW>

    %% ------------------------------------------------------------
    % Save equilibria
    % ------------------------------------------------------------

    if ~isempty(eqAtAlpha)

        alphaColumn = ...
            p.alpha*ones(size(eqAtAlpha,1),1);

        Wcolumn = ...
            W*ones(size(eqAtAlpha,1),1);

        allAlphaEq = [ ...
            allAlphaEq;
            alphaColumn Wcolumn eqAtAlpha ]; %#ok<AGROW>

    end

    %% ------------------------------------------------------------
    % Print summary
    % ------------------------------------------------------------

    fprintf('\n');
    fprintf('Total equilibria     = %d\n',nEq);
    fprintf('Stable equilibria    = %d\n',nStable);
    fprintf('Non-stable equilibria = %d\n',nNonStable);

    if nEq > 0

        fprintf('Minimum |lambdaMax|  = %.6e d^-1\n', ...
            minAbsLambda);

        fprintf('Maximum lambdaMax    = %.6e d^-1\n', ...
            maxLambda);

    end

    %% ------------------------------------------------------------
    % Print all equilibria
    % ------------------------------------------------------------

    fprintf('\n');
    fprintf('Equilibria:\n');

    fprintf(['       A1          P1          A2          P2       ', ...
             'lambdaMax   Stable\n']);

    fprintf(['------------------------------------------------------------------', ...
             '------\n']);

    for ie = 1:nEq

        fprintf( ...
            '%11.6f %11.6f %11.6f %11.6f %13.6e %8d\n', ...
            eqAtAlpha(ie,1), ...
            eqAtAlpha(ie,2), ...
            eqAtAlpha(ie,3), ...
            eqAtAlpha(ie,4), ...
            eqAtAlpha(ie,5), ...
            eqAtAlpha(ie,6));

    end

end

%% ================================================================
% 9. ALPHA SUMMARY TABLE
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('ALPHA SCENARIO SUMMARY\n');
fprintf('============================================================\n');

fprintf([' alpha      Total     Stable    Non-stable   ', ...
         'Min|lambda|    Max lambda\n']);

fprintf(['----------------------------------------------------------------', ...
         '----\n']);

for ia = 1:size(alphaResults,1)

    fprintf( ...
        '%6.3f %10d %10d %12d %14.6e %14.6e\n', ...
        alphaResults(ia,1), ...
        alphaResults(ia,2), ...
        alphaResults(ia,3), ...
        alphaResults(ia,4), ...
        alphaResults(ia,5), ...
        alphaResults(ia,6));

end

%% ================================================================
% 10. PLOT EQUILIBRIUM A1 AGAINST ALPHA
% ================================================================

figure('Color','w','Position',[100 100 850 550]);

hold on;
box on;
grid on;

for ia = 1:length(alpha_values)

    alphaNow = alpha_values(ia);

    rows = abs(allAlphaEq(:,1)-alphaNow) < 1e-10;

    eqNow = allAlphaEq(rows,:);

    if isempty(eqNow)
        continue;
    end

    stableNow = eqNow(eqNow(:,7)==1,:);
    nonStableNow = eqNow(eqNow(:,7)==0,:);

    if ~isempty(stableNow)

        plot( ...
            stableNow(:,1), ...
            stableNow(:,3), ...
            'ko', ...
            'MarkerSize',7, ...
            'MarkerFaceColor','w');

    end

    if ~isempty(nonStableNow)

        plot( ...
            nonStableNow(:,1), ...
            nonStableNow(:,3), ...
            'kx', ...
            'MarkerSize',7, ...
            'LineWidth',1.2);

    end

end

xlabel('\alpha','FontSize',12);
ylabel('Equilibrium A_1 (\mug/L)','FontSize',12);

title('Equilibrium A_1 versus Connectivity Strength \alpha', ...
    'FontSize',14);

%% ================================================================
% 11. PLOT EQUILIBRIUM P1 AGAINST ALPHA
% ================================================================

figure('Color','w','Position',[100 100 850 550]);

hold on;
box on;
grid on;

for ia = 1:length(alpha_values)

    alphaNow = alpha_values(ia);

    rows = abs(allAlphaEq(:,1)-alphaNow) < 1e-10;

    eqNow = allAlphaEq(rows,:);

    if isempty(eqNow)
        continue;
    end

    stableNow = eqNow(eqNow(:,7)==1,:);
    nonStableNow = eqNow(eqNow(:,7)==0,:);

    if ~isempty(stableNow)

        plot( ...
            stableNow(:,1), ...
            stableNow(:,3), ...
            'ko', ...
            'MarkerSize',7, ...
            'MarkerFaceColor','w');

    end

    if ~isempty(nonStableNow)

        plot( ...
            nonStableNow(:,1), ...
            nonStableNow(:,3), ...
            'kx', ...
            'MarkerSize',7, ...
            'LineWidth',1.2);

    end

end

xlabel('\alpha','FontSize',12);
ylabel('Equilibrium P_1 (\mug/L)','FontSize',12);

title('Equilibrium P_1 versus Connectivity Strength \alpha', ...
    'FontSize',14);

%% ================================================================
% 12. PLOT MAXIMUM REAL EIGENVALUE
% ================================================================

figure('Color','w','Position',[100 100 850 550]);

hold on;
box on;
grid on;

for ia = 1:length(alpha_values)

    alphaNow = alpha_values(ia);

    rows = abs(allAlphaEq(:,1)-alphaNow) < 1e-10;

    eqNow = allAlphaEq(rows,:);

    if isempty(eqNow)
        continue;
    end

    plot( ...
        eqNow(:,1), ...
        eqNow(:,6), ...
        'ko', ...
        'MarkerSize',6, ...
        'MarkerFaceColor','w');

end

yline(0,'k--','LineWidth',1.2);

xlabel('\alpha','FontSize',12);
ylabel('\lambda_{max} (d^{-1})','FontSize',12);

title('Maximum Real Eigenvalue versus Connectivity Strength', ...
    'FontSize',14);

%% ================================================================
% 13. SAVE RESULTS
% ================================================================

save( ...
    'Wolong_alpha_equilibrium_test.mat', ...
    'p', ...
    'W', ...
    'alpha_values', ...
    'alphaResults', ...
    'allAlphaEq');

fprintf('\n');
fprintf('============================================================\n');
fprintf('RESULTS SAVED\n');
fprintf('============================================================\n');

fprintf('File: Wolong_alpha_equilibrium_test.mat\n');

fprintf('\n');
fprintf('No formal fold refinement was performed.\n');
fprintf('No hysteresis simulation was performed.\n');

fprintf('\n');
fprintf('This analysis only screens for possible changes in\n');
fprintf('equilibrium structure as alpha is varied.\n');

fprintf('============================================================\n');

%% ================================================================
% LOCAL FUNCTION 1: LAKE MODEL
% ================================================================

function dx = lake_rhs(x,W,p)

    % ------------------------------------------------------------
    % State variables
    % ------------------------------------------------------------

    A1 = x(1);
    P1 = x(2);
    A2 = x(3);
    P2 = x(4);

    %% ------------------------------------------------------------
    % Hydrological connectivity
    % ------------------------------------------------------------

    if W <= p.zsill

        D_w = 0;

    else

        D_w = ...
            p.alpha*(W-p.zsill)^p.k;

    end

    %% ------------------------------------------------------------
    % Available phosphorus
    % ------------------------------------------------------------

    P1avail = ...
        max(0,P1-p.pa*A1);

    P2avail = ...
        max(0,P2-p.pa*A2);

    %% ------------------------------------------------------------
    % Hill-type phosphorus recycling
    % ------------------------------------------------------------

    hill1 = ...
        (P1/p.n)^p.q;

    hill2 = ...
        (P2/p.n)^p.q;

    R1 = ...
        p.r*hill1/(1+hill1);

    R2 = ...
        p.r*hill2/(1+hill2);

    %% ------------------------------------------------------------
    % Algal growth
    % ------------------------------------------------------------

    G1 = ...
        p.b*A1* ...
        (P1avail/(p.ha+P1avail));

    G2 = ...
        p.b*A2* ...
        (P2avail/(p.ha+P2avail));

    %% ------------------------------------------------------------
    % Algal equations
    % ------------------------------------------------------------

    dA1 = ...
        G1 ...
        -(p.f+p.g+p.sv)*A1 ...
        +D_w*(A2-A1);

    dA2 = ...
        G2 ...
        -(p.f+p.g+p.sv)*A2 ...
        +D_w*(A1-A2);

    %% ------------------------------------------------------------
    % Phosphorus equations
    % ------------------------------------------------------------

    dP1 = ...
        p.lp1 ...
        +R1 ...
        +p.e*p.g*A1 ...
        -G1 ...
        -p.f*P1 ...
        +D_w*(P2-P1);

    dP2 = ...
        p.lp2 ...
        +R2 ...
        +p.e*p.g*A2 ...
        -G2 ...
        -p.f*P2 ...
        +D_w*(P1-P2);

    %% ------------------------------------------------------------
    % Output
    % ------------------------------------------------------------

    dx = [
        dA1
        dP1
        dA2
        dP2
    ];

end

%% ================================================================
% LOCAL FUNCTION 2: NUMERICAL JACOBIAN
% ================================================================

function J = numerical_jacobian(fun,x)

    n = length(x);

    J = zeros(n,n);

    h = 1e-6;

    for j = 1:n

        dx = zeros(n,1);

        step = ...
            h*max(1,abs(x(j)));

        dx(j) = step;

        fp = fun(x+dx);

        fm = fun(x-dx);

        J(:,j) = ...
            (fp-fm)/(2*step);

    end

end