clearvars -except Opt
clc
close all

load(['rating_' Opt.sexStr '_.mat'])
load('../tbl_IOCCode.mat')

% 開催地
venueName='France';

myColorCode.gold=[255,215,0]/255;
myColorCode.silver=[192,192,192]/255;
myColorCode.bronze=[205, 127, 50]/255;

% オリンピック参加チームの読み込み
tbl_teams=readtable(['teams_Olympic_' Opt.sexStr '_2024.xlsx']);
tbl_teams.Team=categorical(tbl_teams.Team);
tbl_teams.Group=categorical(tbl_teams.Group);

% IOCコードの読み込み
IOCCode=[];
for n1=1:size(tbl_teams.Team,1)
    IOCCode=[IOCCode;
        tbl_IOCCode.IOCCode(tbl_IOCCode.Team==tbl_teams.Team(n1))];
end

tbl_teams=   addvars( tbl_teams, IOCCode);

tbl_teams;

ratingValues=zeros(size(tbl_teams,1),1);
for n1=1:size(ratingValues,1)
    find(teamNames==tbl_teams.Team(n1));
    ratingValues(n1)=r(ans);
end
ratingValues;
tbl_teams=addvars(tbl_teams, ratingValues);
tbl_teams=   sortrows( sortrows(tbl_teams, 'ratingValues','descend'),'Group')


%% 直接対戦の予測勝率を計算

%カラーマップの作成
myCMapTick=20;
tmp1=[ones(myCMapTick,1) linspace(0,1,myCMapTick)'  linspace(0,1,myCMapTick)'];
tmp1(end,:)=[];
tmp2=[linspace(1,0,myCMapTick)'  linspace(1,0,myCMapTick)' ones(myCMapTick,1) ];
tmp2(1,:)=[];

myCMap=[tmp1;
    1 1 1;
    tmp2
    ];

%
plotData=zeros(size(tbl_teams,1));
plotData2=[];
for n1=1:size(plotData,1)
    for n2=1:size(plotData,2)
        taRating=tbl_teams.ratingValues(n1);
        tbRating=tbl_teams.ratingValues(n2);
        if tbl_teams.Team(n1)==venueName
            taRating=taRating+homeAdv;
        end
        if tbl_teams.Team(n2)==venueName
            tbRating=tbRating+homeAdv;
        end
        c=Opt.min_pWin; %最小勝率
        tmp_pWin=glmval(mdl, taRating-tbRating,'logit');

        plotData(n1,n2)=c+(1-2*c)*tmp_pWin;
        plotData2=[plotData2;n2 n1 tmp_pWin];
    end
end
plotData;
imagesc(plotData);
hold on;
set(gca,'FontName','arial','FontSize',10);
axis equal;
colormap(myCMap);
colorbar;
set(gca,'yTick',1:size(tbl_teams,1));
set(gca,'YTickLabel',tbl_teams.Team);
set(gca,'xTick',1:size(tbl_teams,1));
set(gca,'XTickLabel',tbl_teams.IOCCode);
set(gca,'XTickLabelRotation',90);
xlabel('Opponent');
ylabel('Team');
switch Opt.sexStr
    case 'M'
        title({'Predicted win probability',[Opt.sportName ' in Olympic Games 2024, Men']});
    case 'W'
        title({'Predicted win probability', [Opt.sportName ' in Olympic Games 2024, Women']});
end
exportgraphics(gcf,['prediction_h2h_Olympic_2024_' Opt.sportName '_' Opt.sexStr '.png']);
exportgraphics(gcf,['prediction_h2h_Olympic_2024_' Opt.sportName '_' Opt.sexStr '.pdf']);
tmp=(tbl_teams.ratingValues-ans(8))*mdl(2);
sort(tbl_teams.ratingValues,'descend');

% outFileName=['prediction-H2H_' Opt.sexStr '_.xlsx'];
% xlswrite(outFileName,string(tbl_teams.Team), 'h2h');
% xlswrite(outFileName,string(tbl_teams.Group), 'h2h','B1');
% xlswrite(outFileName,plotData, 'h2h','C1')
% xlswrite(outFileName,string(tbl_teams.IOCCode)', 'h2h','C13')

outFileName=['prediction-H2H_' Opt.sexStr '_.csv'];
tmp=[string(tbl_teams.Team) string(tbl_teams.Group) plotData;
    "" "" string(tbl_teams.IOCCode)']
writematrix(tmp, outFileName)

%% トーナメント予測

tic;    %   経過時刻の表示

stInGS=zeros(size(tbl_teams,1), Opt.nSeasons); % グループステージでの順位
pointsInGS=zeros(size(tbl_teams,1), Opt.nSeasons);  %   グループステージでの勝点
finalStandings=zeros(size(tbl_teams,1), Opt.nSeasons);  % 最終順位
medalPrediction=zeros(3,Opt.nSeasons);  % メダル予測
for k=1:Opt.nSeasons
    if mod(k,500)==0
        [toc (toc)/k*Opt.nSeasons]
    end

    % GS
    for groupName=unique(tbl_teams.Group)'
        groupName;
        groupTeamNames=tbl_teams.Team(tbl_teams.Group==groupName);

        matchTable=[];
        for n1=1:size(groupTeamNames,1)
            for n2=n1+1:size(groupTeamNames,1)
                matchTable=[matchTable;n1 n2];
            end
        end
        for n1=1:size(matchTable,1)
            taName=groupTeamNames(matchTable(n1,1));
            tbName=groupTeamNames(matchTable(n1,2));
            isTaHome=taName==venueName;
            isTbHome=tbName==venueName;

            if isTaHome
                taRating=tbl_teams.ratingValues(tbl_teams.Team==taName)+homeAdv;
                tbRating=tbl_teams.ratingValues(tbl_teams.Team==tbName);
            elseif isTbHome
                taRating=tbl_teams.ratingValues(tbl_teams.Team==taName);
                tbRating=tbl_teams.ratingValues(tbl_teams.Team==tbName)+homeAdv;
            else
                taRating=tbl_teams.ratingValues(tbl_teams.Team==taName);
                tbRating=tbl_teams.ratingValues(tbl_teams.Team==tbName);
            end

            rDiff=taRating-tbRating;
            tmp_pWin=glmval(mdl, taRating-tbRating,'logit');
            pWin=Opt.min_pWin+(1-2*Opt.min_pWin)*tmp_pWin;

            pLose=1-pWin;
            pDraw=1-pWin-pLose;
            [rDiff pWin pDraw pLose];

            tmpRnd=rand();
            taNum=find(tbl_teams.Team==taName);
            tbNum=find(tbl_teams.Team==tbName);

            if tmpRnd<pWin
                % チームAが勝利の場合
                % 得失点差など，勝点で並んだ場合の順位決定方法を乱数で近似しています．
                pointsInGS(taNum,k)=pointsInGS(taNum,k)+3+0.001*taRating*rand();

            elseif tmpRnd<pWin+pDraw
                pointsInGS(taNum,k)=pointsInGS(taNum,k)+1;
                pointsInGS(tbNum,k)=pointsInGS(tbNum,k)+1;
            else
                % チームBが勝利の場合
                pointsInGS(tbNum,k)=pointsInGS(tbNum,k)+3+0.001*tbRating*rand();
            end
        end
    end

    % グループステージ順位および決勝トーナメント進出チームの決定
    for n1=1:size(groupTeamNames,1):size(pointsInGS,1)
        tmp=pointsInGS(n1:(n1+size(groupTeamNames,1)-1),k);
        [val,ind]=sort(tmp,'descend');
        [~,ind]=sort(ind,'ascend');
        stInGS(n1:(n1+size(groupTeamNames,1)-1),k)=ind;
    end
    tmpStTable=zeros( size(groupTeamNames,1),  size(unique(tbl_teams.Group),1));
    for n1=1:size(unique(tbl_teams.Group),1)
        tmp=pointsInGS((n1-1)*size(groupTeamNames,1)+1:n1*size(groupTeamNames,1),k);
        [val,ind]=sort(tmp,'descend');
        tmpStTable(:,n1)=ind+(n1-1)*size(groupTeamNames,1);
    end
    tmpStTable;

    combRanking=[];
    pointsOf1St=pointsInGS(tmpStTable(1,:),k);
    [~,ind]=sort(pointsOf1St,'descend');
    combRanking=[combRanking; tmpStTable(1,ind)'];

    pointsOf2nd=pointsInGS(tmpStTable(2,:),k);
    [~,ind]=sort(pointsOf2nd,'descend');
    combRanking=[combRanking; tmpStTable(2,ind)'];

    pointsOf3rd=pointsInGS(tmpStTable(3,:),k);
    [~,ind]=sort(pointsOf3rd,'descend');
    tmpStTable(3,ind);
    combRanking=[combRanking; tmpStTable(3,ind)'];
    tbl_teams(combRanking,:);

    tournament.QF=combRanking([1,8,4,5,2,7,3,6])';

    finalStandings(setdiff(1:12, combRanking(1:8)),k)=9;

    % QF(ベスト8)
    tournament.SF=[];
    D=mdl(2);
    for n1=1:4
        taNum=tournament.QF(n1*2-1);
        tbNum=tournament.QF(n1*2);
        taRating=tbl_teams.ratingValues( taNum);
        tbRating=tbl_teams.ratingValues( tbNum);

        if tbl_teams.Team(taNum) == venueName
            taRating=taRating+homeAdv;
        end
        if tbl_teams.Team(tbNum) == venueName
            tbRating=tbRating+homeAdv;
        end

        [taRating tbRating];
        if  rand()<1/(1+exp(-D*(taRating-tbRating)))
            tournament.SF=[tournament.SF taNum];
            finalStandings(tbNum,k)=5;
        else
            tournament.SF=[tournament.SF tbNum];
            finalStandings(taNum,k)=5;
        end
    end

    % SF(準決勝)
    tournament.F=[];
    tournament.Bronze=[];
    for n1=1:2
        taNum=tournament.SF(n1*2-1);
        tbNum=tournament.SF(n1*2);
        taRating=tbl_teams.ratingValues( taNum);
        tbRating=tbl_teams.ratingValues( tbNum);

        if tbl_teams.Team(taNum) == venueName
            taRating=taRating+homeAdv;
        end
        if tbl_teams.Team(tbNum) == venueName
            tbRating=tbRating+homeAdv;
        end

        [taRating tbRating];
        if  rand()<1/(1+exp(-D*(taRating-tbRating)))
            tournament.F=[tournament.F taNum];
            tournament.Bronze=[tournament.Bronze tbNum];
        else
            tournament.F=[tournament.F tbNum];
            tournament.Bronze=[tournament.Bronze taNum];
        end
    end

    % Bronze(3位決定戦)
    for n1=1
        taNum=tournament.Bronze(1);
        tbNum=tournament.Bronze(2);
        taRating=tbl_teams.ratingValues( taNum);
        tbRating=tbl_teams.ratingValues( tbNum);

        if tbl_teams.Team(taNum) ==  venueName
            taRating=taRating+homeAdv;
        end
        if tbl_teams.Team(tbNum) ==  venueName
            tbRating=tbRating+homeAdv;
        end

        [taRating tbRating];
        if  rand()<1/(1+exp(-D*(taRating-tbRating)))
            finalStandings(taNum,k)=3;
            medalPrediction(3,k)=taNum;
            finalStandings(tbNum,k)=4;
        else
            finalStandings(tbNum,k)=4;
            finalStandings(taNum,k)=3;
            medalPrediction(3,k)=tbNum;
        end
    end

    % F(決勝戦)
    for n1=1
        taNum=tournament.F(1);
        tbNum=tournament.F(2);
        taRating=tbl_teams.ratingValues( taNum);
        tbRating=tbl_teams.ratingValues( tbNum);

        if tbl_teams.Team(taNum) ==  venueName
            taRating=taRating+homeAdv;
        end
        if tbl_teams.Team(tbNum) ==  venueName
            tbRating=tbRating+homeAdv;
        end

        [taRating tbRating];
        if  rand()<1/(1+exp(-D*(taRating-tbRating)))
            finalStandings(taNum,k)=1;
            finalStandings(tbNum,k)=2;
            medalPrediction(1,k)=taNum;
            medalPrediction(2,k)=tbNum;
        else
            finalStandings(tbNum,k)=1;
            finalStandings(taNum,k)=2;
            medalPrediction(1,k)=tbNum;
            medalPrediction(2,k)=taNum;
        end
    end

    finalStandings(:,k);
end

%メダル予測
[C,ia,ic] = unique(medalPrediction','rows');
a_counts = accumarray(ic,1);
value_counts = [C, a_counts];
[~,ind]=sort(a_counts,'descend');
value_counts(ind(1:20),:);
% xlswrite(['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.xlsx' ],...
%     string(tbl_teams.Team(value_counts(ind(1:20),1:3))),'medal','B2');
% xlswrite(['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.xlsx' ],...
%     ((value_counts(ind(1:20),4)))/Opt.nSeasons,'medal','E2');
% xlswrite(['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.xlsx' ], ...
%     {'Num','Gold','Silver','Bronze','Probability'},'medal','A1');
% xlswrite(['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.xlsx' ], ...
%     (1:20)','medal','A2');
% tbl_tmp=readtable(['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.xlsx' ], ...
%     'Sheet','medal');

tmp=["Num","Gold","Silver","Bronze","Probability";
    (1:20)' ...
    string(tbl_teams.Team(value_counts(ind(1:20),1:3))) ...
    ((value_counts(ind(1:20),4)))/Opt.nSeasons
    ]
writematrix(tmp, ['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.csv' ])
tbl_tmp=readtable(['prediction_medal_' Opt.sportName '_' Opt.sexStr '_.csv' ])

%% 順位予測の図示
figure;
stCounts=hist(finalStandings',[1,2,3,4,5,9])'/Opt.nSeasons;
bhObj=barh(stCounts,'stacked' ,'EdgeColor','w','BarWidth',0.8);
set(gca,'YDir','reverse', 'FontName','メイリオ', 'FontSize',10, ...
    'YTick', 1:size(tbl_teams,1), ...
    'YTickLabel', [char(tbl_teams.Team) ...
    '['.*ones(size(tbl_teams.Team,1),1)...
    char(tbl_teams.Group) ...
    ']'.*ones(size(tbl_teams.Team,1),1)]);
grid on;

switch Opt.sexStr
    case 'M'
        title({'Predicted final standings',[Opt.sportName ' in Olympic Games 2024, Men']})
    case 'W'
        title({'Predicted final standings',[Opt.sportName ' in Olympic Games 2024, Women']})
end

xlabel('Probability')
xlim([0 1])
for n1=1:4
    bhObj(n1).EdgeAlpha=0.75;
end
bhObj(1).FaceColor=myColorCode.gold;
bhObj(2).FaceColor=myColorCode.silver;
bhObj(3).FaceColor=myColorCode.bronze;
% bhObj(4).FaceColor=0.9*[1 1 1];
bhObj(5).FaceColor=0.5*[0 1 1];
bhObj(6).FaceColor=0.9*[0 1 1];
legend({'Gold','Silver','Bronze','SF','QF','GS'},'Location','northoutside','Orientation','horizontal')

set(gcf,'PaperPosition', [3.0917 9.2937 14.8167 14.8167*4/3])
exportgraphics(gcf,['prediction_final_' Opt.sportName '_' Opt.sexStr '_' '.png']);
exportgraphics(gcf,['prediction_final_' Opt.sportName '_' Opt.sexStr '_' '.pdf']);
%%

% xlswrite(['prediction_final_' Opt.sportName '_' Opt.sexStr '_.xlsx' ],stCounts,'prediction','B2');
% xlswrite(['prediction_final_' Opt.sportName '_' Opt.sexStr '_.xlsx' ],string(tbl_teams.Team),'prediction','A2');
% xlswrite(['prediction_final_' Opt.sportName '_' Opt.sexStr '_.xlsx' ], ...
%     {'Gold','Silver','Bronze','SF','QF','GS'},'prediction','B1');

tmp=["","Gold","Silver","Bronze","SF","QF","GS";
    string(tbl_teams.Team) ...
    stCounts
    ];
writematrix(tmp,['prediction_final_' Opt.sportName '_' Opt.sexStr '_.csv' ]);

save(['prediction_' Opt.sexStr '_.mat']);

