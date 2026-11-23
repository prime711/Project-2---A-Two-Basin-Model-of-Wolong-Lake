%% Wolong_equilibrium_structure_r10_f003.m
%
% EQUILIBRIUM-STRUCTURE ANALYSIS FOR THE REVISED PARAMETERIZATION
%
% Revised baseline:
%       r = 10 ug/L/day
%       f = 0.03 d^-1
%
% Purpose:
%   1. Find equilibrium solutions across the water-surface-elevation range
%   2. Classify equilibria as stable or unstable
%   3. Examine the complete equilibrium structure
%   4. Count equilibria at each water-surface elevation
%   5. Check whether high-algal equilibria remain
%   6. Identify candidate fold regions using lambda_max
%
% IMPORTANT:
%   The equilibrium structure is searched independently for the
%   revised parameterization.
%
% State vector:
%       x = [A1 P1 A2 P2]
%
% Storage:
%       allEq columns:
%       1 = W
%       2 = A1
%       3 = P1
%       4 = A2
%       5 = P2
%       6 = lambdaMax
%       7 = stable
%       8 = residual
% ================================================================


clear;
clc;
close all;


%% ================================================================
% 1. MODEL PARAMETERS
% ================================================================

p.b     = 0.2;          % d^-1
p.ha    = 25;           % ug/L
p.pa    = 0.01;

% Revised flushing rate
p.f     = 0.03;         % d^-1

p.g     = 0.01;         % d^-1
p.sv    = 0.02;         % d^-1

p.lp1   = 2;            % ug/L/day
p.lp2   = 26.5;            % ug/L/day

% Revised internal phosphorus recycling rate
p.r     = 10;           % ug/L/day

p.n     = 25;           % ug/L
p.q     = 8;
p.e     = 0.65;

% Hydrological connectivity
p.alpha = 0.15;
p.zsill = 87.15;        % m
p.k     = 2.0;


fprintf('\n');
fprintf('============================================================\n');
fprintf(' WOLONG LAKE EQUILIBRIUM STRUCTURE ANALYSIS\n');
fprintf(' REVISED PARAMETERIZATION\n');
fprintf('============================================================\n\n');

fprintf('Parameterization used in this run:\n');
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
fprintf('  alpha  = %.4f\n',p.alpha);
fprintf('  sill   = %.4f m\n',p.zsill);
fprintf('  k      = %.2f\n\n',p.k);


%% ================================================================
% 2. WATER-SURFACE-ELEVATION RANGE
% ================================================================

Wmin = 86.8;
Wmax = 87.6;

% 161 points
Wgrid = linspace(Wmin,Wmax,161);

fprintf('Water-surface-elevation range:\n');
fprintf('  %.3f - %.3f m\n',Wmin,Wmax);
fprintf('Number of water-surface-elevation points: %d\n\n', ...
    length(Wgrid));


%% ================================================================
% 3. INITIAL GUESSES
% ================================================================
%
% The previous parameterization produced extremely high algal
% equilibria. The revised parameterization is expected to operate
% mainly at much lower concentrations.
%
% Therefore:
%
%   A. Main guesses cover the revised ecological scale.
%   B. A limited number of very high guesses are retained to test
%      explicitly whether high-algal equilibria still exist.
%
% ================================================================


%% ------------------------------------------------
% 3A. Main algal concentration guesses
% ------------------------------------------------

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


%% ------------------------------------------------
% 3B. Main phosphorus concentration guesses
% ------------------------------------------------

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


%% ------------------------------------------------
% 3C. Construct main initial guesses
% ------------------------------------------------
%
% Rather than forcing A2 = 0.5*A1 and P2 = 0.5*P1,
% use independent basin-2 values.
%
% A moderate number of combinations is generated here.
% Additional asymmetric states are added below.
%

starts = [];

% Main balanced states
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
% 3D. Asymmetric exploratory initial guesses
% ------------------------------------------------
%
% These are important because the two basins have different
% external phosphorus loading:
%
%       lp1 = 2
%       lp2 = 5
%
% Therefore, equilibria need not have identical states in
% the two basins.
%

asymmetricStarts = [

    % ------------------------------------------------------------
    % Low/moderate asymmetric states
    % ------------------------------------------------------------
      10    10    30    20
      20    10    40    30
      30    20    50    30
      50    20    30    10
      70    30    40    20

      10    20    30    50
      20    30    50    50
      30    20    50    100
      50    50    30    20

    % ------------------------------------------------------------
    % Intermediate asymmetric states
    % ------------------------------------------------------------
     100    50   300   100
     300   100   100    30
     500    50   300   100
     300    30   500    50
     500   100   100    20

    % ------------------------------------------------------------
    % High-algal exploratory states
    % ------------------------------------------------------------
    1000   100   500    50
    1500   500  1000   300
    2000  1000  1500   500
    2500  3000  2000  1000
    3000 10000  3000 10000

    % ------------------------------------------------------------
    % High phosphorus exploratory states
    % ------------------------------------------------------------
      30  1000    30  3000
      50  3000    50  6000
     100  6000   100 10000
];


starts = [starts; asymmetricStarts];


%% ------------------------------------------------
% 3E. Explicit high-algal exploratory states
% ------------------------------------------------
%
% These are deliberately retained even though they are not
% considered physically realistic.
%
% Their purpose is diagnostic:
% Does the revised parameterization still admit the
% old high-algal equilibrium branch?
%
% They should NOT be interpreted as realistic lake states.
%

highStarts = [

    3000 10000 3000 10000
    3000  8000 2500  7000
    2800  5000 2500  4000
    2500  3000 2000  2000
    2000  1000 1500   500
    1500   500 1000   300
    1000   300  500   100
];

starts = [starts; highStarts];


%% ------------------------------------------------
% 3F. Remove duplicate initial guesses
% ------------------------------------------------

starts = unique(starts,'rows');

fprintf('Number of initial guesses: %d\n\n', ...
    size(starts,1));


%% ================================================================
% 4. FSOLVE OPTIONS
% ================================================================

options = optimoptions('fsolve', ...
    'Display','off', ...
    'FunctionTolerance',1e-10, ...
    'StepTolerance',1e-10, ...
    'OptimalityTolerance',1e-10, ...
    'MaxIterations',1000, ...
    'MaxFunctionEvaluations',5000);


%% ================================================================
% 5. STORAGE
% ================================================================

% Each row of allEq:
%
% [W A1 P1 A2 P2 lambdaMax stable residual]

allEq = [];


%% ================================================================
% 6. FIND EQUILIBRIA AT EACH WATER-SURFACE ELEVATION
% ================================================================

fprintf('Searching for equilibria...\n\n');


for iw = 1:length(Wgrid)

    W = Wgrid(iw);

    % Temporary storage for this water-surface elevation.
    %
    % Columns:
    % 1 = A1
    % 2 = P1
    % 3 = A2
    % 4 = P2
    % 5 = lambdaMax
    % 6 = stable
    % 7 = residual

    eqAtW = [];


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


        % Stable if all eigenvalues have negative real parts.
        if lambdaMax < -1e-7

            stable = 1;

        else

            stable = 0;

        end


        %% --------------------------------------------------------
        % Check duplicate equilibrium
        % --------------------------------------------------------

        isDuplicate = false;


        if ~isempty(eqAtW)

            for ie = 1:size(eqAtW,1)

                old = eqAtW(ie,1:4)';

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

            eqAtW = [eqAtW; newEq]; %#ok<AGROW>

        end

    end


    %% ------------------------------------------------------------
    % Add W column
    % ------------------------------------------------------------

    if ~isempty(eqAtW)

        Wcolumn = W*ones(size(eqAtW,1),1);

        allEq = [ ...
            allEq;
            Wcolumn eqAtW ]; %#ok<AGROW>

    end


    %% ------------------------------------------------------------
    % Progress report
    % ------------------------------------------------------------

    if mod(iw,10)==0 || ...
            iw==1 || ...
            iw==length(Wgrid)

        fprintf( ...
            'W = %.4f m : %d equilibria\n', ...
            W, ...
            size(eqAtW,1));

    end

end


fprintf('\n');
fprintf('============================================================\n');
fprintf('Equilibrium search completed.\n');
fprintf('============================================================\n');

fprintf('Total equilibrium points detected: %d\n', ...
    size(allEq,1));


%% ================================================================
% 7. SORT EQUILIBRIA
% ================================================================

allEq = sortrows(allEq,[1 2]);


%% ================================================================
% 8. VALIDITY CHECK
% ================================================================

if isempty(allEq)

    error('No valid equilibrium points were detected.');

end


valid = ...
    isfinite(allEq(:,1)) & ...
    isfinite(allEq(:,2)) & ...
    isfinite(allEq(:,3)) & ...
    isfinite(allEq(:,4)) & ...
    isfinite(allEq(:,5)) & ...
    isfinite(allEq(:,6)) & ...
    isfinite(allEq(:,7)) & ...
    allEq(:,2) >= 0 & ...
    allEq(:,3) >= 0 & ...
    allEq(:,4) >= 0 & ...
    allEq(:,5) >= 0;


allEq = allEq(valid,:);


fprintf('Valid equilibrium points retained: %d\n', ...
    size(allEq,1));


%% ================================================================
% 9. EXTRACT STABLE AND UNSTABLE EQUILIBRIA
% ================================================================

% Column 6 = lambdaMax
% Column 7 = stable flag
% Column 8 = residual

stableEq = allEq(allEq(:,7)==1,:);

unstableEq = allEq(allEq(:,7)==0,:);


%% ================================================================
% 10. EQUILIBRIUM SUMMARY
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('EQUILIBRIUM SUMMARY\n');
fprintf('============================================================\n');

fprintf('r = %.2f ug/L/day\n',p.r);
fprintf('f = %.4f d^-1\n',p.f);

fprintf('Total equilibria: %d\n', ...
    size(allEq,1));

fprintf('Stable equilibria: %d\n', ...
    size(stableEq,1));

fprintf('Unstable/non-stable equilibria: %d\n', ...
    size(unstableEq,1));


fprintf('Maximum equilibrium residual: %.3e\n', ...
    max(allEq(:,8)));

fprintf('Median equilibrium residual: %.3e\n', ...
    median(allEq(:,8)));


%% ================================================================
% 11. NUMBER OF EQUILIBRIA AT EACH WATER-SURFACE ELEVATION
% ================================================================

fprintf('\n');
fprintf('Number of equilibria at selected water-surface elevations:\n\n');

fprintf('       W (m)      Total       Stable      Unstable\n');
fprintf('------------------------------------------------------------\n');


for iw = 1:10:length(Wgrid)

    W = Wgrid(iw);

    rows = abs(allEq(:,1)-W) < 1e-10;

    totalN = sum(rows);

    stableN = sum(allEq(rows,7)==1);

    unstableN = sum(allEq(rows,7)==0);


    fprintf( ...
        '%12.4f %10d %12d %12d\n', ...
        W, ...
        totalN, ...
        stableN, ...
        unstableN);

end


%% ================================================================
% 12. PLOT A1 EQUILIBRIUM STRUCTURE
% ================================================================

figure('Color','w','Position',[100 100 850 550]);

hold on;
box on;
grid on;


%% ------------------------------------------------
% Stable equilibria
% ------------------------------------------------

if ~isempty(stableEq)

    % Sort by water surface elevation
    stableSort = sortrows(stableEq,1);

    % Smooth stable branch
    hStableA = plot( ...
        stableSort(:,1), ...
        stableSort(:,2), ...
        'k-', ...
        'LineWidth',2.2, ...
        'DisplayName','Stable equilibrium');

    % Sparse open-circle markers
    markerStep = 8;

    idxStable = 1:markerStep:size(stableSort,1);

    plot( ...
        stableSort(idxStable,1), ...
        stableSort(idxStable,2), ...
        'ko', ...
        'MarkerSize',5, ...
        'MarkerFaceColor','w', ...
        'HandleVisibility','off');

else

    hStableA = [];

end


%% ------------------------------------------------
% Unstable equilibria
% ------------------------------------------------

if ~isempty(unstableEq)

    unstableSort = sortrows(unstableEq,1);

    % Sparse x markers only
    markerStep = 8;

    idxUnstable = 1:markerStep:size(unstableSort,1);

    hUnstableA = plot( ...
        unstableSort(idxUnstable,1), ...
        unstableSort(idxUnstable,2), ...
        'kx', ...
        'MarkerSize',6, ...
        'LineWidth',1.2, ...
        'DisplayName','Unstable equilibrium');

else

    hUnstableA = [];

end


%% ------------------------------------------------
% Sill elevation
% ------------------------------------------------

hSillA = xline( ...
    p.zsill, ...
    '--', ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.5, ...
    'DisplayName','Sill elevation');


%% ------------------------------------------------
% Axis labels
% ------------------------------------------------

xlabel('Water surface elevation (m)', ...
    'FontSize',12);

ylabel('Equilibrium A_1 (\mug/L)', ...
    'FontSize',12);

title(sprintf( ...
    'Equilibrium Structure of A_1 (r = %.1f, f = %.2f)', ...
    p.r,p.f), ...
    'FontSize',14);


xlim([Wmin Wmax]);


%% ------------------------------------------------
% Legend
% ------------------------------------------------

legend( ...
    [hStableA hUnstableA hSillA], ...
    {'Stable equilibrium', ...
     'Unstable equilibrium', ...
     'Sill elevation'}, ...
    'Location','southeast', ...
    'FontSize',10);


%% ------------------------------------------------
% Direct annotation
% ------------------------------------------------

if ~isempty(stableEq)

    % Use the final stable point for annotation
    stableSort = sortrows(stableEq,1);

    text( ...
        stableSort(end,1)-0.12, ...
        stableSort(end,2)+1.0, ...
        'Stable equilibrium', ...
        'FontSize',10, ...
        'HorizontalAlignment','left');

end


if ~isempty(unstableEq)

    % Identify the lowest-A1 unstable branch
    [~,idxLowUnstable] = min(unstableEq(:,2));

    text( ...
        unstableEq(idxLowUnstable,1)+0.015, ...
        unstableEq(idxLowUnstable,2)+1.0, ...
        'Unstable equilibrium', ...
        'FontSize',10, ...
        'HorizontalAlignment','left');

end


%% ================================================================
% 13. PLOT P1 EQUILIBRIUM STRUCTURE
% ================================================================

figure('Color','w','Position',[100 100 850 550]);

hold on;
box on;
grid on;


%% ------------------------------------------------
% Stable equilibria
% ------------------------------------------------

if ~isempty(stableEq)

    stableSort = sortrows(stableEq,1);

    hStableP = plot( ...
        stableSort(:,1), ...
        stableSort(:,3), ...
        'k-', ...
        'LineWidth',2.2, ...
        'DisplayName','Stable equilibrium');

    markerStep = 8;

    idxStable = 1:markerStep:size(stableSort,1);

    plot( ...
        stableSort(idxStable,1), ...
        stableSort(idxStable,3), ...
        'ko', ...
        'MarkerSize',5, ...
        'MarkerFaceColor','w', ...
        'HandleVisibility','off');

else

    hStableP = [];

end


%% ------------------------------------------------
% Unstable equilibria
% ------------------------------------------------

if ~isempty(unstableEq)

    unstableSort = sortrows(unstableEq,1);

    markerStep = 8;

    idxUnstable = 1:markerStep:size(unstableSort,1);

    hUnstableP = plot( ...
        unstableSort(idxUnstable,1), ...
        unstableSort(idxUnstable,3), ...
        'kx', ...
        'MarkerSize',6, ...
        'LineWidth',1.2, ...
        'DisplayName','Unstable equilibrium');

else

    hUnstableP = [];

end


%% ------------------------------------------------
% Sill elevation
% ------------------------------------------------

hSillP = xline( ...
    p.zsill, ...
    '--', ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.5, ...
    'DisplayName','Sill elevation');


%% ------------------------------------------------
% Labels
% ------------------------------------------------

xlabel('Water surface elevation (m)', ...
    'FontSize',12);

ylabel('Equilibrium P_1 (\mug/L)', ...
    'FontSize',12);

title(sprintf( ...
    'Equilibrium Structure of P_1 (r = %.1f, f = %.2f)', ...
    p.r,p.f), ...
    'FontSize',14);


xlim([Wmin Wmax]);


%% ------------------------------------------------
% Legend
% ------------------------------------------------

legend( ...
    [hStableP hUnstableP hSillP], ...
    {'Stable equilibrium', ...
     'Unstable equilibrium', ...
     'Sill elevation'}, ...
    'Location','southeast', ...
    'FontSize',10);


%% ------------------------------------------------
% Direct annotations
% ------------------------------------------------

if ~isempty(stableEq)

    stableSort = sortrows(stableEq,1);

    text( ...
        stableSort(end,1)-0.12, ...
        stableSort(end,3)+15, ...
        'Stable equilibrium', ...
        'FontSize',10);

end


if ~isempty(unstableEq)

    % Highest P1 unstable equilibrium
    [~,idxHighUnstable] = max(unstableEq(:,3));

    text( ...
        unstableEq(idxHighUnstable,1)-0.12, ...
        unstableEq(idxHighUnstable,3)+12, ...
        'Unstable equilibrium', ...
        'FontSize',10);

end


%% ================================================================
% 14. NUMBER OF EQUILIBRIA AT EACH WATER-SURFACE ELEVATION
% ================================================================

stableCount = zeros(size(Wgrid));
totalCount = zeros(size(Wgrid));
unstableCount = zeros(size(Wgrid));


for iw = 1:length(Wgrid)

    W = Wgrid(iw);

    rows = abs(allEq(:,1)-W) < 1e-10;

    totalCount(iw) = sum(rows);

    stableCount(iw) = ...
        sum(allEq(rows,7)==1);

    unstableCount(iw) = ...
        sum(allEq(rows,7)==0);

end

%% ================================================================
% EQUILIBRIA AT W = 87.0 m
% ================================================================

W_target = 87.0;

rows87 = abs(allEq(:,1) - W_target) < 1e-10;

eq87 = allEq(rows87,:);

fprintf('\n');
fprintf('============================================================\n');
fprintf('EQUILIBRIA AT W = %.2f m\n', W_target);
fprintf('============================================================\n');

fprintf('      A1          P1          A2          P2       lambdaMax   Stable\n');
fprintf('--------------------------------------------------------------------------\n');

for i = 1:size(eq87,1)

    fprintf('%10.6f %10.6f %10.6f %10.6f %12.6e %8d\n', ...
        eq87(i,2), ...
        eq87(i,3), ...
        eq87(i,4), ...
        eq87(i,5), ...
        eq87(i,6), ...
        eq87(i,7));

end
%% ================================================================
% 15. NUMBER OF STABLE EQUILIBRIA
% ================================================================

figure('Color','w','Position',[100 100 850 500]);

hold on;
box on;
grid on;


hStableCount = stairs( ...
    Wgrid, ...
    stableCount, ...
    'k-', ...
    'LineWidth',2.0);


% Add sparse markers
idxCount = 1:10:length(Wgrid);

plot( ...
    Wgrid(idxCount), ...
    stableCount(idxCount), ...
    'ko', ...
    'MarkerSize',5, ...
    'MarkerFaceColor','w');


% Sill
hSillCount = xline( ...
    p.zsill, ...
    '--', ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.5);


xlabel('Water surface elevation (m)', ...
    'FontSize',12);

ylabel('Number of stable equilibria', ...
    'FontSize',12);

title(sprintf( ...
    'Number of Stable Equilibria (r = %.1f, f = %.2f)', ...
    p.r,p.f), ...
    'FontSize',14);


xlim([Wmin Wmax]);

ylim([ ...
    0 ...
    max(1,max(stableCount))+0.5 ]);


legend( ...
    [hStableCount hSillCount], ...
    {'Stable equilibrium count', ...
     'Sill elevation'}, ...
    'Location','best', ...
    'FontSize',10);


%% ================================================================
% 16. TOTAL NUMBER OF EQUILIBRIA
% ================================================================

figure('Color','w','Position',[100 100 850 500]);

hold on;
box on;
grid on;


%% Total equilibrium count

hTotalCount = stairs( ...
    Wgrid, ...
    totalCount, ...
    'k-', ...
    'LineWidth',2.2);


%% Sparse markers

idxCount = 1:10:length(Wgrid);

plot( ...
    Wgrid(idxCount), ...
    totalCount(idxCount), ...
    'ko', ...
    'MarkerSize',5, ...
    'MarkerFaceColor','w');


%% Sill

hSillTotal = xline( ...
    p.zsill, ...
    '--', ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.5);


%% Labels

xlabel('Water surface elevation (m)', ...
    'FontSize',12);

ylabel('Total number of equilibria', ...
    'FontSize',12);

title(sprintf( ...
    'Total Number of Equilibria (r = %.1f, f = %.2f)', ...
    p.r,p.f), ...
    'FontSize',14);


xlim([Wmin Wmax]);

ylim([ ...
    0 ...
    max(1,max(totalCount))+1 ]);


%% Legend

legend( ...
    [hTotalCount hSillTotal], ...
    {'Total equilibrium count', ...
     'Sill elevation'}, ...
    'Location','best', ...
    'FontSize',10);


%% Direct annotation of the two regimes

text( ...
    Wmin+0.03, ...
    max(totalCount)-0.25, ...
    sprintf('%.0f equilibria',max(totalCount)), ...
    'FontSize',10, ...
    'HorizontalAlignment','left');


text( ...
    p.zsill+0.03, ...
    min(totalCount)+0.15, ...
    sprintf('%.0f equilibria',min(totalCount)), ...
    'FontSize',10, ...
    'HorizontalAlignment','left');

%% ================================================================
% 17. CHECK FOR HIGH-ALGAL EQUILIBRIA
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('HIGH-ALGAL EQUILIBRIUM CHECK\n');
fprintf('============================================================\n');


highThreshold1 = 1000;
highThreshold2 = 2000;


highEq1000 = allEq(allEq(:,2) > highThreshold1,:);

highEq2000 = allEq(allEq(:,2) > highThreshold2,:);


if isempty(highEq1000)

    fprintf('No equilibrium with A1 > %.0f ug/L detected.\n', ...
        highThreshold1);

else

    fprintf( ...
        'Equilibria with A1 > %.0f ug/L detected: %d\n', ...
        highThreshold1, ...
        size(highEq1000,1));

    fprintf('Maximum A1 = %.6f ug/L\n', ...
        max(highEq1000(:,2)));

end


if isempty(highEq2000)

    fprintf('No equilibrium with A1 > %.0f ug/L detected.\n', ...
        highThreshold2);

else

    fprintf( ...
        'Equilibria with A1 > %.0f ug/L detected: %d\n', ...
        highThreshold2, ...
        size(highEq2000,1));

    fprintf('Maximum A1 = %.6f ug/L\n', ...
        max(highEq2000(:,2)));

end


%% ================================================================
% 18. POSSIBLE FOLD REGIONS
% ================================================================
%
% A saddle-node equilibrium is associated with a zero eigenvalue.
%
% Therefore, lambda_max approximately equal to zero can be used
% to identify candidate regions.
%
% IMPORTANT:
%   This section ONLY identifies candidate regions.
%
%   It does NOT formally confirm a saddle-node bifurcation.
%
%   Formal confirmation requires solving the augmented fold
%   conditions or an equivalent continuation analysis.
%
% ================================================================


fprintf('\n');
fprintf('============================================================\n');
fprintf('POSSIBLE FOLD REGIONS\n');
fprintf('============================================================\n');


lambdaThreshold = 1e-3;


candidate = ...
    abs(allEq(:,6)) < lambdaThreshold;


foldCandidates = allEq(candidate,:);


if isempty(foldCandidates)

    fprintf( ...
        'No candidate points with |lambda_max| < %.1e.\n', ...
        lambdaThreshold);

else

    foldCandidates = ...
        sortrows(foldCandidates,[1 2]);


    fprintf( ...
        ['Candidate equilibria with |lambda_max| < ', ...
         '%.1e:\n\n'], ...
        lambdaThreshold);


    fprintf( ...
        ['       W          A1          P1      ', ...
         'lambda_max     Stable\n']);


    fprintf( ...
        '------------------------------------------------------------\n');


    nPrint = min(100,size(foldCandidates,1));


    for i = 1:nPrint

        fprintf( ...
            '%10.5f %11.3f %11.3f %14.6e %8d\n', ...
            foldCandidates(i,1), ...
            foldCandidates(i,2), ...
            foldCandidates(i,3), ...
            foldCandidates(i,6), ...
            foldCandidates(i,7));

    end

end


%% ================================================================
% 19. SMALLEST ABSOLUTE EIGENVALUE
% ================================================================

[minAbsLambda,idxLambda] = ...
    min(abs(allEq(:,6)));


fprintf('\n');
fprintf('============================================================\n');
fprintf('CLOSEST APPROACH TO A ZERO EIGENVALUE\n');
fprintf('============================================================\n');

fprintf('Minimum |lambda_max| = %.6e d^-1\n', ...
    minAbsLambda);

fprintf('At:\n');

fprintf('  W  = %.6f m\n', ...
    allEq(idxLambda,1));

fprintf('  A1 = %.6f ug/L\n', ...
    allEq(idxLambda,2));

fprintf('  P1 = %.6f ug/L\n', ...
    allEq(idxLambda,3));

fprintf('  A2 = %.6f ug/L\n', ...
    allEq(idxLambda,4));

fprintf('  P2 = %.6f ug/L\n', ...
    allEq(idxLambda,5));

fprintf('  lambda_max = %.6e d^-1\n', ...
    allEq(idxLambda,6));

fprintf('  stable flag = %d\n', ...
    allEq(idxLambda,7));


%% ================================================================
% 20. SUMMARY OF MAXIMUM AND MINIMUM A1
% ================================================================

[maxA1,idxMaxA1] = max(allEq(:,2));

[minA1,idxMinA1] = min(allEq(:,2));


fprintf('\n');
fprintf('============================================================\n');
fprintf('ALGAL CONCENTRATION RANGE\n');
fprintf('============================================================\n');

fprintf( ...
    'Minimum equilibrium A1 = %.6f ug/L\n', ...
    minA1);

fprintf( ...
    '  at W = %.6f m\n', ...
    allEq(idxMinA1,1));

fprintf( ...
    'Maximum equilibrium A1 = %.6f ug/L\n', ...
    maxA1);

fprintf( ...
    '  at W = %.6f m\n', ...
    allEq(idxMaxA1,1));


%% ================================================================
% 21. SUMMARY OF P1
% ================================================================

[maxP1,idxMaxP1] = max(allEq(:,3));

[minP1,idxMinP1] = min(allEq(:,3));


fprintf('\n');
fprintf('============================================================\n');
fprintf('PHOSPHORUS CONCENTRATION RANGE\n');
fprintf('============================================================\n');

fprintf( ...
    'Minimum equilibrium P1 = %.6f ug/L\n', ...
    minP1);

fprintf( ...
    '  at W = %.6f m\n', ...
    allEq(idxMinP1,1));

fprintf( ...
    'Maximum equilibrium P1 = %.6f ug/L\n', ...
    maxP1);

fprintf( ...
    '  at W = %.6f m\n', ...
    allEq(idxMaxP1,1));


%% ================================================================
% 22. SAVE RESULTS
% ================================================================

save( ...
    'Wolong_equilibrium_structure_r10_f003.mat', ...
    'p', ...
    'Wgrid', ...
    'allEq', ...
    'stableEq', ...
    'unstableEq', ...
    'stableCount', ...
    'unstableCount', ...
    'totalCount', ...
    'foldCandidates', ...
    'minAbsLambda', ...
    'idxLambda');


fprintf('\n');
fprintf('============================================================\n');
fprintf('RESULTS SAVED\n');
fprintf('============================================================\n');

fprintf( ...
    'File: Wolong_equilibrium_structure_r10_f003.mat\n');


%% ================================================================
% 23. FINAL SUMMARY
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('FINAL ANALYSIS SUMMARY\n');
fprintf('============================================================\n');

fprintf( ...
    'IPR rate r = %.2f ug/L/day\n', ...
    p.r);

fprintf( ...
    'Flushing rate f = %.4f d^-1\n', ...
    p.f);

fprintf( ...
    'Total equilibrium points: %d\n', ...
    size(allEq,1));

fprintf( ...
    'Stable equilibrium points: %d\n', ...
    size(stableEq,1));

fprintf( ...
    'Unstable/non-stable equilibrium points: %d\n', ...
    size(unstableEq,1));

fprintf( ...
    'Maximum residual: %.3e\n', ...
    max(allEq(:,8)));

fprintf( ...
    'Median residual: %.3e\n', ...
    median(allEq(:,8)));

fprintf( ...
    'Maximum equilibrium A1: %.3f ug/L\n', ...
    maxA1);

fprintf( ...
    'Maximum equilibrium P1: %.3f ug/L\n', ...
    maxP1);

fprintf( ...
    'Minimum |lambda_max|: %.3e d^-1\n', ...
    minAbsLambda);


fprintf('\nParameter values:\n');

fprintf('  r     = %.2f ug/L/day\n',p.r);
fprintf('  f     = %.4f d^-1\n',p.f);
fprintf('  n     = %.2f ug/L\n',p.n);
fprintf('  q     = %.2f\n',p.q);
fprintf('  ha    = %.2f ug/L\n',p.ha);
fprintf('  sill  = %.4f m\n',p.zsill);


fprintf('\n');
fprintf('No formal fold refinement was performed.\n');
fprintf('No hysteresis simulation was performed.\n');

fprintf('\n');
fprintf(['The equilibrium structure should be inspected before ', ...
         'drawing conclusions about saddle-node behavior.\n']);

fprintf('============================================================\n');

%% ================================================================
% TEST POSSIBLE MISSING EQUILIBRIUM AT W = 87.0 m
% ================================================================

W_test = 87.0;

x_guess = [0; 400; 490.814347; 15.622429];

[x_test,fval_test,exitflag_test] = fsolve( ...
    @(x) lake_rhs(x,W_test,p), ...
    x_guess, ...
    options);

residual_test = norm(fval_test,inf);

fprintf('\n');
fprintf('============================================================\n');
fprintf('TEST POSSIBLE MISSING EQUILIBRIUM\n');
fprintf('============================================================\n');

fprintf('Exit flag = %d\n',exitflag_test);

fprintf('Solution:\n');
fprintf('A1 = %.15f\n',x_test(1));
fprintf('P1 = %.15f\n',x_test(2));
fprintf('A2 = %.15f\n',x_test(3));
fprintf('P2 = %.15f\n',x_test(4));

fprintf('\nResiduals:\n');
disp(fval_test);

fprintf('Maximum absolute residual = %.6e\n',residual_test);


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