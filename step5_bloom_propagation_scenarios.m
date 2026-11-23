%% Step 9: Bloom propagation between basins (Section 2.6 / Figure 5)
% Reproduces the numbers and Figure 5 in the manuscript.
% South bloom -> north basin response, and north bloom -> south basin response.
% Bloom = algae in the source basin multiplied by bloomFac at t = 0, starting
% from the stable equilibrium at a fixed water level W (same model as step1).
clear; 
clc; 
close all;

%% 1. Parameters (identical to step1)
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
p.zsill = 87.15; 
p.k = 2;

%% 2. Scenario settings
W_list   = 87.20:0.05:87.60;   % above the sill only (D = 0 at or below it)
bloomFac = 3;                  % algae in the source basin multiplied by this
Tend     = 400;                % days after the bloom
opts = odeset('RelTol',1e-9,'AbsTol',1e-11);
dirs = {'S2N','N2S'};          % south->north, north->south
nW = numel(W_list);
% columns: [baseline  peak  peak%  t_peak  transfer%  t_bloom_recovery  dP_peak]
res = struct('S2N',nan(nW,7),'N2S',nan(nW,7));

%% 3. Loop over water levels and directions
for iw = 1:nW
    W  = W_list(iw);
    Dw = (W > p.zsill) * p.alpha * (W - p.zsill)^p.k;

    [~,s] = ode15s(@(t,x) rhs(x,Dw,p), [0 5000], [30 20 30 20], opts);
    xe = s(end,:);                              % stable equilibrium

    for d = 1:2
        if d == 1, src = 3; rcv = 1;            % south bloom, north receives
        else,      src = 1; rcv = 3;            % north bloom, south receives
        end
        x0 = xe;  x0(src) = bloomFac*xe(src);
        added = (bloomFac-1)*xe(src);           % algae added to source basin

        tt = linspace(0,Tend,8001);
        [t,x] = ode15s(@(t,x) rhs(x,Dw,p), tt, x0, opts);

        dA = x(:,rcv)   - xe(rcv);              % receiving-basin algae change
        dP = x(:,rcv+1) - xe(rcv+1);            % receiving-basin P change
        [~,ip] = max(abs(dA));
        [~,iq] = max(abs(dP));

        % time for the BLOOM basin to return to within 1% of equilibrium
        isrc = find(abs(x(:,src)-xe(src)) < 0.01*xe(src), 1);

        res.(dirs{d})(iw,:) = [xe(rcv), dA(ip), 100*dA(ip)/xe(rcv), t(ip), ...
                               100*dA(ip)/added, t(isrc), dP(iq)];
    end
end

%% 4. Print table
for d = 1:2
    fprintf('\n%s (bloom x%.1f)\n', dirs{d}, bloomFac);
    fprintf('  W(m)  base   peak dA  peak%%  t_peak(d)  transfer%%  t_bloom_rec(d)  dP_peak\n');
    R = res.(dirs{d});
    for iw = 1:nW
        fprintf('%6.2f %6.2f %8.3f %6.2f %9.1f %10.2f %13.1f %9.3f\n', ...
            W_list(iw), R(iw,1), R(iw,2), R(iw,3), R(iw,4), R(iw,5), R(iw,6), R(iw,7));
    end
end

%% 5. Figure 5: (a) receiving basin, (b) bloom basin, (c) peak response, (d) transfer efficiency
% dA_i(t) = 100*(A_i(t)-A_i*)/A_i*;   eta = 100*max_t[A_rec(t)-A_rec*] / ((bloomFac-1)*A_bloom*)
W0 = 87.35; D0 = p.alpha*(W0-p.zsill)^p.k;
[~,s] = ode15s(@(t,x) rhs(x,D0,p), [0 5000], [30 20 30 20], opts); xe = s(end,:);
tt = linspace(0,150,1501);
% Relative change dA_i(t) = 100*(A_i(t) - A_i*)/A_i*,  A_i* = equilibrium before the bloom
dA_rec = zeros(numel(tt),2);  dA_bloom = zeros(numel(tt),2);   % column 1: S2N, 2: N2S
for d = 1:2
    if d == 1, src = 3; rcv = 1; else, src = 1; rcv = 3; end
    x0 = xe; x0(src) = bloomFac*xe(src);
    [~,x] = ode15s(@(t,x) rhs(x,D0,p), tt, x0, opts);
    dA_rec(:,d)   = 100*(x(:,rcv)/xe(rcv) - 1);
    dA_bloom(:,d) = 100*(x(:,src)/xe(src) - 1);
end
blk = [0 0 0]; gry = [0.45 0.45 0.45];

fig = figure('Color','w','Position',[100 100 900 730]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; box on;                                     % (a) receiving basin
plot(tt,dA_rec(:,1),'-','Color',blk,'LineWidth',2);
plot(tt,dA_rec(:,2),'--','Color',gry,'LineWidth',2);
xlabel('Time after bloom (d)'); ylabel('\DeltaA_{rec} (%)');
legend('South bloom \rightarrow north (receiving A_1)', ...
       'North bloom \rightarrow south (receiving A_2)','Location','northeast','Box','off','FontSize',8);
title('(a) Receiving basin at \omega = 87.35 m');

nexttile; hold on; box on;                                     % (b) bloom basin
plot(tt,dA_bloom(:,1),'-','Color',blk,'LineWidth',2);
plot(tt,dA_bloom(:,2),'--','Color',gry,'LineWidth',2);
xlabel('Time after bloom (d)'); ylabel('\DeltaA_{bloom} (%)');
legend('South bloom (A_2)','North bloom (A_1)','Location','northeast','Box','off','FontSize',8);
title('(b) Bloom basin at \omega = 87.35 m');

nexttile; hold on; box on;
plot(W_list,res.S2N(:,3),'ko-','LineWidth',1.8,'MarkerSize',4);
plot(W_list,res.N2S(:,3),'s--','Color',[0.45 0.45 0.45],'LineWidth',1.8,'MarkerSize',4);
xlabel('Water-surface elevation (m)'); ylabel('Peak \DeltaA_{rec} (%)');
legend('South bloom \rightarrow north (A_1)','North bloom \rightarrow south (A_2)','Location','northwest');
title('(c) Peak response');
nexttile; hold on; box on;
plot(W_list,res.S2N(:,5),'ko-','LineWidth',1.8,'MarkerSize',4);
plot(W_list,res.N2S(:,5),'s--','Color',[0.45 0.45 0.45],'LineWidth',1.8,'MarkerSize',4);
xlabel('Water-surface elevation (m)'); ylabel('Transfer efficiency, \eta (%)');
legend('South \rightarrow north','North \rightarrow south','Location','northwest');
title('(d) Transfer efficiency');
set(findall(fig,'Type','axes'),'FontName','Arial','FontSize',10);
exportgraphics(fig,'Figure5_bloom_propagation.png','Resolution',300);

%% ---------------- local function ----------------
function dx = rhs(x,D,p)
    A1=x(1); P1=x(2); A2=x(3); P2=x(4);
    G1 = p.b*A1*(P1-p.pa*A1)/(p.ha+(P1-p.pa*A1));
    G2 = p.b*A2*(P2-p.pa*A2)/(p.ha+(P2-p.pa*A2));
    dx = [ G1-(p.f+p.g+p.sv)*A1 + D*(A2-A1);
           p.lp1+p.r*P1^p.q/(P1^p.q+p.n^p.q)+p.e*p.g*A1-G1-p.f*P1 + D*(P2-P1);
           G2-(p.f+p.g+p.sv)*A2 + D*(A1-A2);
           p.lp2+p.r*P2^p.q/(P2^p.q+p.n^p.q)+p.e*p.g*A2-G2-p.f*P2 + D*(P1-P2) ];
end
