clear
clc
close all

figure
set(gca,'XDir','reverse');
set(gca,'FontName','メイリオ');
xlabel('試合開催日');
ylabel('累積試合数(バリ五輪直前からさかのぼって)')
hold on;grid on;

outData=[];

cd('basketball\');
[numMatches, numTeams, draws]=extNumMatches;
outData=[outData;numTeams, numMatches, draws];
plot_local
cd('../');

cd('handball\');
[numMatches, numTeams, draws]=extNumMatches;
outData=[outData;numTeams, numMatches, draws];
plot_local
cd('../');

cd('hockey\');
[numMatches, numTeams, draws]=extNumMatches;
outData=[outData;numTeams, numMatches, draws];
plot_local
cd('../');

cd('volleyball\');
[numMatches, numTeams, draws]=extNumMatches;
outData=[outData;numTeams, numMatches, draws];
plot_local
cd('../');

cd('waterpolo\');
[numMatches, numTeams, draws]=extNumMatches;
outData=[outData;numTeams, numMatches, draws];
plot_local
cd('../');

legend({'バスケットボール男子', ...
    'バスケットボール女子', ...
    'ハンドボール男子', ...
    'ハンドボール女子', ...
    'ホッケー男子', ...
    'ホッケー女子', ...
    'バレーボール男子', ...
    'バレーボール女子', ...
    '水球男子', ...
    '水球女子'},'Location','northoutside','Orientation','horizontal', ...
    'NumColumns',3);

xlim([datetime(2014,1,1),datetime(2024,8,1)]);

exportgraphics(gcf,'fig_numOfMatches_OlympicPrediction.pdf');
function plot_local
load('result_M_.mat');
tbl_tmp=sortrows(tbl_result,'Date','descend');
plot(tbl_tmp.Date, 1:size(tbl_tmp,1),'LineWidth',1.5);
get(gca,'ColorOrderIndex');
set(gca,'ColorOrderIndex',ans-1);
load('result_W_.mat');
tbl_tmp=sortrows(tbl_result,'Date','descend');
plot(tbl_tmp.Date, 1:size(tbl_tmp,1),'LineWidth',1.5,'LineStyle','-.');
end

function [matches, teams, draws]=extNumMatches
load('result_M_.mat');
tbl_tmp=tbl_result(tbl_result.Date>=datetime(2022,1,1),:);
matches=size(tbl_tmp,1);
teams=size(unique([tbl_tmp.TeamA;tbl_tmp.TeamB]),1);
try
    draws=sum(tbl_tmp.SetsA==tbl_tmp.SetsB);
catch
    draws=sum(tbl_tmp.ScoreA==tbl_tmp.ScoreB);
end

load('result_W_.mat');
tbl_tmp=tbl_result(tbl_result.Date>=datetime(2022,1,1),:);
matches(2,1)=size(tbl_tmp,1);
teams(2,1)=size(unique([tbl_tmp.TeamA;tbl_tmp.TeamB]),1);
try
    draws(2,1)=sum(tbl_tmp.SetsA==tbl_tmp.SetsB);
catch
    draws(2,1)=sum(tbl_tmp.ScoreA==tbl_tmp.ScoreB);
end

end
