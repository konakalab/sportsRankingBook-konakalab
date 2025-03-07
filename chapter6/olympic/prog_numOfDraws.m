clear
clc
close all

plotData=[];

cd('basketball/');
extNumOfDraws;
plotData=[plotData;ans];
cd('../');

cd('handball/');
extNumOfDraws;
plotData=[plotData;ans];
cd('../');

cd('hockey/');
extNumOfDraws;
plotData=[plotData;ans];
cd('../');

cd('volleyball/');
extNumOfDraws;
plotData=[plotData;ans];
cd('../');

cd('waterpolo/');
extNumOfDraws;
plotData=[plotData;ans];
cd('../');

barh(plotData(:,2));hold on;
barh(plotData(:,1));
yticklabels({'バスケットボール', ...
    'ハンドボール', ...
    'ホッケー', ...
    'バレーボール', ...
    '水球', ...
    });
xlabel('');
ylabel('')
exportgraphics(gcf,'fig_numOfDraws.pdf');


function r=extNumOfDraws
r=[];
load('result_M_.mat');
tbl_tmp=tbl_result(tbl_result.Date>=datetime(2022,1,1),:);

load('result_W_.mat');
tbl_result(tbl_result.Date>=datetime(2022,1,1),:);
tbl_tmp=[tbl_tmp;ans];

try
    r(1,1)=sum(tbl_tmp.SetsA==tbl_tmp.SetsB);
catch
    r(1,1)=sum(tbl_tmp.ScoreA==tbl_tmp.ScoreB);
end
r(1,2)=size(tbl_tmp,1);
end
