clear
clc
close all

figure;hold on;grid on;
set(gca,'fontname','メイリオ');

cd('basketball/');
plot_local;
cd('../');

cd('handball/');
plot_local;
cd('../');

cd('hockey/');
plot_local;
cd('../');

cd('volleyball/');
plot_local;
cd('../');

cd('waterpolo/');
plot_local;
cd('../');

legend({'バスケットボール', ...
    'ハンドボール', ...
    'ホッケー', ...
    'バレーボール', ...
    '水球', ...
    },'Location','northoutside','Orientation','horizontal', ...
    'NumColumns',3);
xlabel('総得点');
ylabel('試合数')
exportgraphics(gcf,'fig_totalScore.pdf');


function plot_local
load('result_M_.mat');
tbl_tmp=tbl_result(tbl_result.Date>=datetime(2022,1,1),:);

load('result_W_.mat');
tbl_result(tbl_result.Date>=datetime(2022,1,1),:);
tbl_tmp=[tbl_tmp;ans];

histogram([tbl_tmp.ScoreA+tbl_tmp.ScoreB],'EdgeColor','none');
end
