%% Step 4b: Corrected Figure 4 (r-n sensitivity), four panels
% Runs standalone: only needs Wolong_r_n_sensitivity_revised.mat in the
% current folder (no need to rerun step4).
% Fixes: (1) cells with no stable equilibrium are grey, not the lowest colour;
%        (2) axis ticks sit on the tested r and n values;
%        (3) panel (d) uses two discrete colours (0 or 1 stable equilibria);
%        (4) cells with a stable equilibrium at only a few water levels are
%            starred and labelled 'Marginal' (e.g. r = 5, n = 15);
%        (6) a compact legend sits inside every panel;
%        (5) units written as ug/L/d, consistent with the text and Table 1.

clear; 
clc; 
close all;

S = load('Wolong_r_n_sensitivity_revised.mat');
r_values = double(S.r_values(:)');
n_values = double(S.n_values(:)');
W_range  = S.W_range(:)';
NW       = numel(W_range);
iw0      = find(abs(W_range - 87.00) < 1e-9, 1);       % reference elevation

A1b   = squeeze(S.A1_stable(:,:,iw0));                 % panel (a)
P1b   = squeeze(S.P1_stable(:,:,iw0));                 % panel (b)
cnt   = double(squeeze(S.stable_eq(:,:,iw0)));         % panel (d)
Amax  = max(S.A1_stable,[],3,'omitnan');               % panel (c); NaN if none
nW_st = sum(double(S.stable_eq),3);                    % water levels with a stable eq.
marginal = (nW_st > 0) & (nW_st < 0.1*NW);             % stable at < 10% of levels

grey = [0.85 0.85 0.85];
r0 = 10; n0 = 25;                                      % baseline parameters

fig = figure('Color','w','Position',[100 100 1000 820]);
tl = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

heat(nexttile, n_values, r_values, A1b,  '(a) Stable equilibrium A_1 at \omega = 87.00 m', ...
     'A_1 (\mug/L)', grey, n0, r0, []);
heat(nexttile, n_values, r_values, P1b,  '(b) Stable equilibrium P_1 at \omega = 87.00 m', ...
     'P_1 (\mug/L)', grey, n0, r0, []);
heat(nexttile, n_values, r_values, Amax, '(c) Maximum stable A_1 over \omega = 87.00-87.35 m', ...
     'Maximum A_1 (\mug/L)', grey, n0, r0, marginal);

% ---- panel (d): number of stable equilibria, discrete colours ----
ax = nexttile;
h = imagesc(ax, n_values, r_values, cnt, [0 1]);
set(ax,'YDir','normal','Color','w');
colormap(ax,[grey; 0.20 0.45 0.75]);
cb = colorbar(ax,'Ticks',[0.25 0.75],'TickLabels',{'0','1'});
ylabel(cb,'Number of stable equilibria');
style_axes(ax, n_values, r_values, '(d) Number of stable equilibria at \omega = 87.00 m');
hold(ax,'on');
hb = plot(ax,n0,r0,'ko','MarkerSize',9,'LineWidth',2);
h0 = plot(ax,NaN,NaN,'s','MarkerFaceColor',grey,'MarkerEdgeColor','k','MarkerSize',7);
h1 = plot(ax,NaN,NaN,'s','MarkerFaceColor',[0.20 0.45 0.75],'MarkerEdgeColor','k','MarkerSize',7);
hold(ax,'off');
style_legend(legend(ax,[hb h0 h1],{'Baseline','0 stable','1 stable'}));

set(findall(fig,'Type','axes'),'FontName','Arial','FontSize',10);
exportgraphics(fig,'Figure4_rn_sensitivity_fixed.png','Resolution',300);
disp('Saved Figure4_rn_sensitivity_fixed.png');

%% ---------------- local functions ----------------
function heat(ax, nv, rv, Z, ttl, cblabel, grey, n0, r0, marginal)
    h = imagesc(ax, nv, rv, Z);
    set(h,'AlphaData',~isnan(Z));          % NaN (no stable equilibrium) -> transparent
    set(ax,'YDir','normal','Color',grey);  % grey shows through the transparent cells
    cb = colorbar(ax); ylabel(cb,cblabel);
    style_axes(ax, nv, rv, ttl);
    hold(ax,'on');
    hb = plot(ax,n0,r0,'ko','MarkerSize',9,'LineWidth',2);
    hn = plot(ax,NaN,NaN,'s','MarkerFaceColor',grey,'MarkerEdgeColor','k','MarkerSize',7);
    if ~isempty(marginal) && any(marginal(:))
        [ir,in] = find(marginal);
        hm = plot(ax,nv(in),rv(ir),'k*','MarkerSize',10,'LineWidth',1.2);
        lg = legend(ax,[hb hn hm],{'Baseline','No stable eq.','Marginal'});
    else
        lg = legend(ax,[hb hn],{'Baseline','No stable eq.'});
    end
    style_legend(lg);
    hold(ax,'off');
end

function style_legend(lg)
    % compact legend inside the panel, over the (mostly empty) n = 15 column
    set(lg,'Location','northwest','FontSize',7,'Box','on', ...
           'Color','w','EdgeColor',[0.5 0.5 0.5],'ItemTokenSize',[10 6]);
end

function style_axes(ax, nv, rv, ttl)
    xticks(ax,nv); yticks(ax,rv);           % ticks exactly at the tested values
    xlabel(ax,'Recycling half-saturation constant n (\mug/L)');
    ylabel(ax,'Maximum recycling rate r (\mug/L/d)');
    title(ax,ttl,'FontWeight','normal');
    box(ax,'on');
end
