
clear; 
clc; 
close all;

%% 1. Model parameters
b     = 0.2;
ha    = 25;
pa    = 0.01;
f     = 0.03;
g     = 0.01;
sv    = 0.02;
lp1   = 2;
lp2   = 5;
r     = 10;
n     = 25;
q     = 8;
e     = 0.65;

W     = 87.30;
zsill = 87.15;
k     = 2;

%% 2. Stable equilibrium values from your alpha scenario
% Columns: A1, P1, A2, P2
equilibria = [
    31.466499, 11.028951, 87.357478, 11.587860;
    46.550651,  8.131812, 73.576751, 13.690657
];

alpha_values = [0, 1];

%% 3. Calculate the northern-basin phosphorus budget
% Connectivity function
D_base = max(0, W - zsill)^k;

% Preallocate results
budget = zeros(6, numel(alpha_values));

for i = 1:numel(alpha_values)

    alpha = alpha_values(i);

    A1 = equilibria(i,1);
    P1 = equilibria(i,2);
    A2 = equilibria(i,3);
    P2 = equilibria(i,4);

    % Available phosphorus, consistent with your manuscript equations
    P1avail = max(0, P1 - pa*A1);

    % Algal growth / phosphorus uptake term
    G1 = b*A1*P1avail/(ha + P1avail);

    % Internal phosphorus recycling
    hill1 = P1^q/(P1^q + n^q);
    R1 = r*hill1;

    % Six terms in dP1/dt
    external_loading = lp1;
    internal_recycling = R1;
    grazing_return = e*g*A1;
    algal_uptake = -G1;
    flushing_loss = -f*P1;
    net_exchange = alpha*D_base*(P2-P1);

    budget(:,i) = [
        external_loading;
        internal_recycling;
        grazing_return;
        algal_uptake;
        flushing_loss;
        net_exchange
    ];

    % Print detailed results
    fprintf('\n========================================\n');
    fprintf('alpha = %.2f, W = %.2f m\n', alpha, W);
    fprintf('A1 = %.6f, P1 = %.6f\n', A1, P1);
    fprintf('A2 = %.6f, P2 = %.6f\n', A2, P2);
    fprintf('========================================\n');

    fprintf('External phosphorus loading   = %12.8f\n', ...
        external_loading);
    fprintf('Internal phosphorus recycling= %12.8f\n', ...
        internal_recycling);
    fprintf('Phosphorus returned by grazing= %12.8f\n', ...
        grazing_return);
    fprintf('Algal phosphorus uptake      = %12.8f\n', ...
        algal_uptake);
    fprintf('Flushing loss                = %12.8f\n', ...
        flushing_loss);
    fprintf('Net inter-basin exchange     = %12.8f\n', ...
        net_exchange);

    % Check phosphorus equilibrium residual
    residual = sum(budget(:,i));

    fprintf('----------------------------------------\n');
    fprintf('Sum of phosphorus budget terms = %.10e\n', ...
        residual);
end

%% 4. Display comparison table
term_names = {
    'External loading';
    'Internal recycling';
    'Grazing return';
    'Algal uptake';
    'Flushing loss';
    'Net exchange'
};

T = table(term_names, budget(:,1), budget(:,2), ...
    'VariableNames', {'Term','Alpha_0','Alpha_1'});

fprintf('\nPhosphorus budget comparison:\n');
disp(T);

%% 5. Plot the comparison
figure('Color','w','Position',[100 100 900 500]);

bar(budget','grouped');

set(gca,'XTickLabel',{'alpha = 0','alpha = 1'}, ...
    'FontName','Arial','FontSize',11);

ylabel('Contribution to dP_1/dt (\mug L^{-1} d^{-1})');
title('Northern-basin phosphorus budget');
legend(term_names,'Location','bestoutside');
yline(0,'k-');
box on;

exportgraphics(gcf,'Wolong_phosphorus_budget.png', ...
    'Resolution',300);
