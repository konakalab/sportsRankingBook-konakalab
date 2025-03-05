clear
clc
close all

figure
set(gcf,'PaperPosition',[3.0917 9.2937 14.8167 6]);
set(gcf,'Position',[320 1298 400 200]);
bins=-3:0.1:3;
plot(bins, 1./(1+exp(-bins)),'LineWidth',2);
hold on;
grid on;
xticklabels([]);
yticklabels([]);
set(gca,'FontName','メイリオ','FontSize',14);
xlim([min(bins) max(bins)]);
xlabel('Masseyレーティング差');
ylabel('予測勝率');
xVal=1.5;
yVal=1./(1+exp(-xVal));
plot(xVal,0,'ro');
plot(3,yVal,'ro');
quiver(xVal,0,0,yVal,"off",'r-','LineWidth',2);
quiver(xVal,yVal,3-xVal,0,"off",'r-','LineWidth',2);

exportgraphics(gcf,'fig_sigmoidSample.pdf')

%%
a0=[0;6;-2];
a1=[1;5;1];

figure
hold on;grid on;
for n1=1:size(a0,1)
    plot(bins, 1./(1+exp(-a1(n1)*bins-a0(n1))),'LineWidth',2);
end
set(gca,'FontName','メイリオ','FontSize',12);
xlabel('$x$','Interpreter','latex');
ylabel('$f(x| a_0, a_1)$','Interpreter','latex');
yline(0.5,'b:');

text(-0.8,0.8,['$(a_0,a_1)=(' num2str(a0(1)) ',' num2str(a1(1)) ')$'], ...
    'interpreter','latex','FontSize',14);
quiver(1,0.8,0.2,0,'off','LineWidth',1,'Color','k', ...
    'MaxHeadSize',10)

text(-3,0.6,['$(a_0,a_1)=(' num2str(a0(2)) ',' num2str(a1(2)) ')$'], ...
    'interpreter','latex','FontSize',14,'VerticalAlignment','bottom');
quiver(-1.5,0.6,0.3,-0.05,'off','LineWidth',1,'Color','k', ...
    'MaxHeadSize',10)


text(1,0.2,['$(a_0,a_1)=(' num2str(a0(3)) ',' num2str(a1(3)) ')$'], ...
    'interpreter','latex','FontSize',14);
quiver(1,0.2,-0.2,0,'off','LineWidth',1,'Color','k', ...
    'MaxHeadSize',10);
title('2パラメータロジスティックモデル');
exportgraphics(gcf,'fig_sigmoidParamSample.pdf')
