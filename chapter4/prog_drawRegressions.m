clear
clc
close all
N=100;

rng(2);

x=randn(N,1);
y=2*x+1+randn(N,1);

figure
set(gcf,"Position",[20 298 560*2 420]);

tiledlayout(1,2);
nexttile;
scatter(x,y);
grid on;hold on;
set(gca,'FontName','メイリオ','fontsize',12);
xticklabels([]);
yticklabels([]);
xlabel('$x$','Interpreter','latex');
ylabel('$y$','Interpreter','latex');
a=([x ones(size(x))]\y)
xVal=[min(x);max(x)];
plot(xVal, [xVal ones(size(xVal))]*a,'LineWidth',1.5)
legend({'観測値','回帰直線'},'Location','best');
title('線形回帰');
nexttile;

y2=(x+0.75*randn(N,1))>0;
scatter(x,y2);
grid on;hold on;
set(gca,'FontName','メイリオ','fontsize',12);
xticklabels([]);
yticklabels([]);
xlabel('$x$','Interpreter','latex');
ylabel('$y$','Interpreter','latex');
a=([x ones(size(x))]\y2)
xVal=[min(x);max(x)];
plot(xVal, [xVal ones(size(xVal))]*a,'--');
mdl=glmfit(x,y2,'binomial','logit');
yHat=glmval(mdl, linspace(xVal(1),xVal(2),100),"logit");
plot(linspace(xVal(1),xVal(2),100), yHat,'LineWidth',1.5)
legend({'観測値','回帰直線','ロジスティック回帰'},'Location','southeast');
title('ロジスティック回帰');
ylim((0.5+[-1 0.5])*2)


exportgraphics(gcf,'fig_defferentRegressions.pdf')