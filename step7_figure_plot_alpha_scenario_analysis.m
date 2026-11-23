
clear; 
clc; 
close all;

%% Figure 5: Scenario analysis

% Scenario 1: Varying south-basin phosphorus loading
lp2 = [5 10 15 20 25 30];

% Maximum concentrations among all identified equilibria
max_A1 = [49.011659 76.384093 103.032146 ...
          129.572149 156.235817 183.137117];

max_P1 = [433.471074 489.256198 545.041322 ...
          600.826446 656.611570 712.396694];

% Scenario 2: Varying connectivity strength
alpha = [0 0.05 0.10 0.15 0.20 0.30 ...
         0.50 0.75 1.00];

% Locally stable equilibrium concentrations at W = 87.30 m
A1 = [31.466499 32.789218 34.018726 35.159351 ...
      36.218297 38.121304 41.245360 44.240719 ...
      46.550651];

A2 = [87.357478 86.164917 85.055597 84.023000 ...
      83.060598 81.322319 78.452024 75.696302 ...
      73.576751];

P1 = [11.028951 10.581036 10.213629 9.908113 ...
      9.651033 9.245207 8.712839 8.337514 ...
      8.131812];

P2 = [11.587860 11.754603 11.912607 12.062333 ...
      12.204239 12.466303 12.913810 13.354454 ...
      13.690657];

%% Create four-panel figure
fig = figure('Color','w','Position',[100 100 1000 700]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% (a) Maximum algal concentration versus lp2
nexttile;
plot(lp2,max_A1,'o-','LineWidth',1.6,'MarkerSize',6);
xlabel('South-basin loading lp_2 (\mug/L/day)');
ylabel('Maximum A_1 (\mug/L)');
title('(a) South-basin loading: algal response');
box on;

% (b) Maximum phosphorus concentration versus lp2
nexttile;
plot(lp2,max_P1,'s-','LineWidth',1.6,'MarkerSize',6);
xlabel('South-basin loading lp_2 (\mug/L/day)');
ylabel('Maximum P_1 (\mug/L)');
title('(b) South-basin loading: phosphorus response');
box on;

% (c) Stable-equilibrium algal concentrations versus alpha
nexttile;
plot(alpha,A1,'o-','LineWidth',1.6,'MarkerSize',5);
hold on;
plot(alpha,A2,'s--','LineWidth',1.6,'MarkerSize',5);
xlabel('Connectivity coefficient \alpha');
ylabel('Algal concentration (\mug/L)');
title('(c) Connectivity strength: algal biomass');
legend('North basin (A_1)','South basin (A_2)', ...
       'Location','best');
box on;

% (d) Stable-equilibrium phosphorus concentrations versus alpha
nexttile;
plot(alpha,P1,'o-','LineWidth',1.6,'MarkerSize',5);
hold on;
plot(alpha,P2,'s--','LineWidth',1.6,'MarkerSize',5);
xlabel('Connectivity coefficient \alpha');
ylabel('Phosphorus concentration (\mug/L)');
title('(d) Connectivity strength: phosphorus');
legend('North basin (P_1)','South basin (P_2)', ...
       'Location','best');
box on;

% Consistent formatting
ax = findall(fig,'Type','axes');
set(ax,'FontName','Arial','FontSize',10,'LineWidth',0.8);

% Export high-resolution figure
exportgraphics(fig,'Figure5_scenario_analysis.png','Resolution',300);
exportgraphics(fig,'Figure5_scenario_analysis.pdf', ...
               'ContentType','vector');

disp('Figure 5 saved as PNG and PDF.');
