clearvars -except Opt;
clc;
close all;

load(['result_' Opt.sexStr '_.mat'],'tbl_result');  %過去の試合データを読み込む

% 没収試合の削除
ind = (tbl_result.ScoreA==0 & tbl_result.ScoreB==20) ...
    | (tbl_result.ScoreA==20 & tbl_result.ScoreB==0);
tbl_result(ind,:)=[];

% チーム名一覧
teamNames=unique([tbl_result.TeamA;tbl_result.TeamB]);

% レーティング算出に利用する期間を決定
ind = tbl_result.Date>datetime(2022,1,1);
tbl_result=tbl_result(ind,:);

%
data=zeros(size(tbl_result,1),4);
currentDate=max(tbl_result.Date)+days(1);

%%
for n1=1:size(tbl_result,1)
    taNum=find(tbl_result.TeamA(n1)==teamNames);
    tbNum=find(tbl_result.TeamB(n1)==teamNames);
    venueNum=find(tbl_result.Venue(n1)==teamNames);
    data(n1,1)=taNum;
    data(n1,2)=tbNum;
    data(n1,3)=tbl_result.ScoreA(n1);
    data(n1,4)=tbl_result.ScoreB(n1);
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
            if sum(data(n1,3)+data(n1,4))==20
                p=[p; ...
                    log((data(n1,3)+60)/(data(n1,4)+60))];
            else
                p=[p; ...
                    log((data(n1,3)+1)/(data(n1,4)+1))];
            end
    end
end

M=[M;ones(1,size(M,2))];
p=[p;0];
r=pinv(M)*p;
homeAdv=r(end); % ホームアドバンテージ
r=r(1:end-1);   % 各チームのレーティング値

%% 予測モデルの構築
rDiff=r(data(:,1))-r(data(:,2));    % レーティング差
wl=(data(:,3)>data(:,4))+0; % 勝敗
sij=(data(:,3)+1)./((data(:,3)+data(:,4)+2));   % 得点割合
ind= find(data(:,3)==data(:,4));    % 引き分けの抽出
wl(ind)=0.5;

% 両チームから見たデータに拡張
rDiff=[rDiff;-rDiff];
sij=[sij;1-sij];
wl=[wl;1-wl];

% 
mdl=glmfit(rDiff,wl,'binomial');
x=linspace(min(rDiff),max(rDiff),100);
bins=linspace(-1,1,50);
winCounts=hist(rDiff(wl==1),bins);
drawCounts=hist(rDiff(wl==0.5),bins);
loseCounts=hist(rDiff(wl==0),bins);
allCounts=winCounts+drawCounts+loseCounts;

switch Opt.method
    case 'Elo'
        figure
        scatter(1./(1.+exp(-rDiff)),sij)
        grid on;hold on;
        set(gca,'FontName','arial','fontsize',12)
        xlabel('Estimated score ratio')
        ylabel('Actual score ratio')
        plot([0 1],[0 1],'k:','LineWidth',1)
        axis equal

        figure
        subplot(3,1,[1,2])
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
                title(['Prediction model; ' Opt.sportName ', Olympic Games 2024, Men' ])
            case 'W'
                title(['Prediction model; ' Opt.sportName ', Olympic Games 2024, Women'])
        end
        ylabel('Predicted win probability')
        plot(x,glmval(mdl,x,'logit'),'b','LineWidth',2);
        xlim([min(bins),max(bins)])
        grid on;
        set(gca,'FontName','arial','fontsize',12)
        xticklabels([])
        subplot(3,1,3)
        bObj=bar(bins,[winCounts' drawCounts' loseCounts'],'stacked', ...
            'BarWidth',1,'EdgeColor','w');
        bObj(1).FaceColor='b';
        bObj(1).FaceAlpha=0.5;
        bObj(2).FaceColor='w';
        bObj(3).FaceColor='r';
        bObj(3).FaceAlpha=0.5;
        xlabel(['Rating difference on scoring (' Opt.method ')'])
        ylabel('Frequency')
        xlim([min(bins),max(bins)])
        grid on;
        set(gca,'FontName','arial','fontsize',12)
        exportgraphics(gcf,['predictionModel_' Opt.sportName '_' Opt.sexStr '_' datestr(currentDate,'yyyymmdd') '.png']);
        exportgraphics(gcf,['predictionModel_' Opt.sportName '_' Opt.sexStr '_' datestr(currentDate,'yyyymmdd') '.pdf']);
end

RatingA=r(tbl_result.TeamA);
isHomeA=tbl_result.TeamA==tbl_result.Venue;
RatingB=r(tbl_result.TeamB);
isHomeB=tbl_result.TeamB==tbl_result.Venue;
RatingDiff=RatingA+homeAdv*isHomeA -(RatingB+homeAdv*isHomeB);

tbl_result=addvars(tbl_result,RatingA, RatingB, isHomeA, isHomeB, RatingDiff)

tbl_teams_all=table();
tbl_teams_all=addvars(tbl_teams_all, teamNames, 'NewVariableNames','Team');
tbl_teams_all=addvars(tbl_teams_all, r, 'NewVariableNames','Rating');

NumMatches=zeros(size(tbl_teams_all,1),1);
for n1=1:size(NumMatches,1)
    NumMatches(n1)=sum(data(:,1:2)==n1,'all');
end
tbl_teams_all=addvars(tbl_teams_all, NumMatches);

tbl_teams_all=   sortrows(tbl_teams_all,'Rating','descend');
save(['rating_' Opt.sexStr '_.mat']); %レーティング算出結果の保存