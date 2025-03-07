clearvars -except Opt
clc
close all

load(['result_' Opt.sexStr '_.mat']); %過去の試合データを読み込む

% レーティング算出範囲を決定
ind = tbl_result.Date>datetime(2022,1,1);
tbl_result=tbl_result(ind,:);
data=zeros(size(tbl_result,1),7);

% チーム名一覧
teamNames=unique([tbl_result.TeamA;tbl_result.TeamB]);
currentDate=max(tbl_result.Date)+days(1);

Opt.method='Elo';

%%
for n1=1:size(tbl_result,1)
    taNum=find(tbl_result.TeamA(n1)==teamNames);
    tbNum=find(tbl_result.TeamB(n1)==teamNames);
    venueNum=find(tbl_result.Venue(n1)==teamNames);
    data(n1,1)=taNum;
    data(n1,2)=tbNum;
    data(n1,3)=tbl_result.ScoreA(n1);
    data(n1,4)=tbl_result.ScoreB(n1);
    %% バレーボールではセット数も情報に入れる
    data(n1,6)=tbl_result.SetsA(n1);
    data(n1,7)=tbl_result.SetsB(n1);

    if isempty(venueNum)
        data(n1,5)=0;
    else
        data(n1,5)=venueNum;
    end
end

M=[];p=[];
for n1=1:size(data,1)
    m=zeros(1,size(teamNames,1));
    m(data(n1,1))=1;
    m(data(n1,2))=-1;
    if data(n1,1)==data(n1,5)
        m=[m 1];
    elseif data(n1,2)==data(n1,5)
        m=[m -1];
    else
        m=[m 0];
    end
    M=[M;m];
    switch Opt.method
        case 'Massey'
            p=[p;data(n1,3)-data(n1,4)];
        case 'Elo'
            p=[p; ...
                log((data(n1,3)+1)/(data(n1,4)+1))];
    end
end
M=[M;ones(1,size(M,2))];
p=[p;0];
r=pinv(M)*p;
homeAdv=r(end); % ホームアドバンテージ
r=r(1:end-1);  % 各チームのレーティング値

%% 予測モデルの構築
rDiff=r(data(:,1))-r(data(:,2));   % レーティング差
wl=(data(:,6)>data(:,7))+0; % 勝敗
ind= find(data(:,6)==data(:,7));   % 引き分けの抽出
wl(ind)=0.5;

% 両チームから見たデータに拡張
rDiff=[rDiff;-rDiff];
wl=[wl;1-wl];

mdl=glmfit(rDiff,wl,'binomial');
x=linspace(min(rDiff),max(rDiff),100);
bins=linspace(-1,1,50);
winCounts=hist(rDiff(wl==1),bins);
drawCounts=hist(rDiff(wl==0.5),bins);
loseCounts=hist(rDiff(wl==0),bins);
allCounts=winCounts+drawCounts+loseCounts;
subplot(3,1,[1,2]);
bObj=bar(bins,[winCounts./allCounts; drawCounts./allCounts; loseCounts./allCounts]','stacked', ...
    'BarWidth',1,'EdgeColor','w');
bObj(1).FaceColor='b';
bObj(1).FaceAlpha=0.3;
bObj(2).FaceColor='w';
bObj(3).FaceColor='r';
bObj(3).FaceAlpha=0.3;
hold on;
switch Opt.sexStr
    case 'M'
        title(['Prediction model; ' Opt.sportName ', Olympic Games 2024, Men' ]);
    case 'W'
        title(['Prediction model; ' Opt.sportName ', Olympic Games 2024, Women']);
end
ylabel('Predicted win probability');
plot(x,glmval(mdl,x,'logit'),'b','LineWidth',2);
xlim([min(bins),max(bins)]);
grid on;
set(gca,'FontName','arial','fontsize',12);
xticklabels([]);
subplot(3,1,3);
bObj=bar(bins,[winCounts' drawCounts' loseCounts'],'stacked', ...
    'BarWidth',1,'EdgeColor','w');
bObj(1).FaceColor='b';
bObj(1).FaceAlpha=0.5;
bObj(2).FaceColor='w';
bObj(3).FaceColor='r';
bObj(3).FaceAlpha=0.5;
xlabel(['Rating difference on scoring (' Opt.method ')']);
ylabel('Frequency');
xlim([min(bins),max(bins)]);
grid on;
set(gca,'FontName','arial','fontsize',12);
exportgraphics(gcf,['predictionModel_' Opt.sexStr '_' datestr(currentDate,'yyyymmdd') '.pdf']);
save(['rating_' Opt.sexStr '_.mat'])