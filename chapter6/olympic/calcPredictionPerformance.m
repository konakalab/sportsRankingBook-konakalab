% 予測性能の算出
clear
clc
close all;

load tbl_IOCCode.mat

tbl=table();


%%

% 全10種目の予測と結果を読み込む
for tmpSportName={'basketball','handball','hockey','volleyball','waterpolo'}
    for tmpSexStr={'M','W'}
        tbl_tmp ...
            =readtable([tmpSportName{1} '/matches_Olympic_' tmpSexStr{1} '_2024.xlsx']);

        Sport=cell(size(tbl_tmp,1),1);
        SexStr=cell(size(tbl_tmp,1),1);
        TeamACode=cell(size(tbl_tmp,1),1);
        TeamBCode=cell(size(tbl_tmp,1),1);

        for n1=1:size(Sport,1)
            Sport{n1}=tmpSportName{1};
            SexStr{n1}=tmpSexStr{1};
            ind = find(tbl_IOCCode.Team==tbl_tmp.TeamA{n1});
            TeamACode{n1}=tbl_IOCCode.IOCCode(ind);
            ind = find(tbl_IOCCode.Team==tbl_tmp.TeamB{n1});
            TeamBCode{n1}=tbl_IOCCode.IOCCode(ind);
        end

        tbl_tmp=addvars(tbl_tmp,Sport,'Before','Date');
        tbl_tmp=addvars(tbl_tmp,SexStr,'Before','Date');

        tbl_tmp=addvars(tbl_tmp, TeamBCode, 'After','TeamB');
        tbl_tmp=addvars(tbl_tmp, TeamACode, 'After','TeamB');

        switch tmpSportName{1}
            case 'hockey'
            otherwise
                pDraw=zeros(size(tbl_tmp,1),1);
                pLose=1-tbl_tmp.pWin;

                tbl_tmp=addvars(tbl_tmp,pLose,'After','pWin');
                tbl_tmp=addvars(tbl_tmp,pDraw,'After','pWin');
        end
        tbl=[tbl;tbl_tmp];
    end
end

tbl.Sport=categorical(tbl.Sport);
tbl.SexStr=categorical(tbl.SexStr);
tbl.aWin= 1*(tbl.ScoreA>tbl.ScoreB)+0.5*(tbl.ScoreA==tbl.ScoreB);

% レーティング，ランキングそれぞれでの予測結果を追加する
PredRating=(tbl.pWin>tbl.pLose)*1;
PredRanking=(tbl.RankingA<tbl.RankingB)*1;
tbl=addvars(tbl,    PredRating, PredRanking);
tbl.TeamA=categorical(tbl.TeamA);
tbl.TeamB=categorical(tbl.TeamB);
writetable(tbl,'predictionResult.xlsx');
%%
ind = ~isnan(tbl.ScoreA);
tbl_finished=tbl(ind,:);    % 終了した試合
tbl_upcoming=tbl(~ind,:);   % 開始前の試合

% レーティング，ランキングそれぞれでの予測が合っているかどうか
isCorrectRating = (tbl_finished.pWin>tbl_finished.pLose) == (tbl_finished.aWin==1);
isCorrectRanking=(tbl_finished.RankingA<tbl_finished.RankingB) == (tbl_finished.aWin==1);

% 引き分けの場合は予測不正解
ind = tbl_finished.aWin==0.5;
isCorrectRating(ind)=false;
isCorrectRanking(ind)=false;

w=tbl_finished.aWin;
wHat=tbl_finished.pWin+tbl_finished.pDraw/2;
LogLoss=-(w.*log2(wHat)+(1-w).*log2(1-wHat));   % 対数損失を計算

tbl_finished=addvars(tbl_finished, ...
    isCorrectRating, isCorrectRanking, LogLoss);

disp('予測正解数とその割合 [レーティング 公式ランキング]');
disp([sum(tbl_finished.isCorrectRating) sum(tbl_finished.isCorrectRanking)])
disp([sum(tbl_finished.isCorrectRating) sum(tbl_finished.isCorrectRanking)]/size(tbl_finished,1))

writetable(tbl_finished,'predictionResult_finished.xlsx');
%% 見解の一致/不一致
disp('[一致 不一致] の予測数');

ind = tbl.PredRating~=tbl.PredRanking;

tbl_diffPred= tbl(ind,:);

% 仮説検定
% 帰無仮説：レーティングとランキングの予測正解率は等しい
% 対立仮説：レーティングとランキングの予測正解率は等しくない
[h,p,e1,e2]=testcholdout(tbl_finished.PredRating, tbl_finished.PredRanking, tbl_finished.aWin);

% レーティング，ランキングの予測を逆にしてももちろん同じ結果になります．
% [h,p,e1,e2]=testcholdout(tbl_finished.PredRanking, tbl_finished.PredRating, tbl_finished.aWin);

disp('マクネマー検定. [h p e1 e2]');
disp([h p e1 e2])

[sum(tbl_finished.isCorrectRating & tbl_finished.isCorrectRanking) ...
    sum(tbl_finished.isCorrectRating & ~tbl_finished.isCorrectRanking); 
    sum(~tbl_finished.isCorrectRating & tbl_finished.isCorrectRanking) ...
    sum(~tbl_finished.isCorrectRating & ~tbl_finished.isCorrectRanking);]
%%
ind = tbl_finished.pWin>tbl_finished.pLose;

%予測勝率/引き分け率/敗北率の合計(強いと評価したチームから見た値)
pMat=[ tbl_finished.pWin.*ind + tbl_finished.pLose.*(1-ind) ...
    tbl_finished.pDraw ...
    tbl_finished.pWin.*(1-ind) + tbl_finished.pLose.*(ind)
    ];

%実際の勝ち/引き分け/負けの合計(強いと評価したチームから見た値)
rMat=[tbl_finished.aWin.*ind+(1-tbl_finished.aWin).*(1-ind)-0.5*(tbl_finished.aWin==0.5),...
    tbl_finished.aWin==0.5 ...
    tbl_finished.aWin.*(1-ind)+(1-tbl_finished.aWin).*(ind)-0.5*(tbl_finished.aWin==0.5)
    ];

disp('勝ち/引き分け/負けの合計(強いと評価したチームから見た値) [予測;結果]');
disp([sum(pMat); sum(rMat)]);
caibVal=sum(pMat(:,1)+pMat(:,2)/2) / sum(rMat(:,1)+rMat(:,2)/2)

%%
edges=0.5:0.1/2:1.0;
histAll=histcounts(pMat(:,1)+pMat(:,2)/2,edges);
histWin=histcounts(pMat(rMat(:,1)==1,1)+pMat(rMat(:,1)==1,2)/2,edges);
histDraw=histcounts(pMat(rMat(:,2)==1,1)+pMat(rMat(:,2)==1,2)/2,edges);
histLose=histcounts(pMat(rMat(:,3)==1,1)+pMat(rMat(:,3)==1,2)/2,edges);

figure
tiledlayout(2,1);
nexttile;
bObj=bar(movmean(edges,2,"Endpoints","discard"), ...
    [histWin;histDraw;histLose]'./histAll','stacked','BarWidth',1,'EdgeColor','w');
grid on;hold on;
title(['オリンピック2024 予測性能 (' ...
    datestr(max(tbl_finished.Date), 'yyyy/mm/dd') 'まで)'])
plot([0.5 1],[0.5 1],'w--');
plot(movmean(edges,2,"Endpoints","discard"), ...
    [histWin+histDraw/2]'./histAll', 'yo-','LineWidth',1.5);
bObj(1).FaceColor='b';bObj(1).FaceAlpha=0.5;
bObj(2).FaceColor=0.5*[1 1 1];bObj(2).FaceAlpha=0.5;
bObj(3).FaceColor='r';bObj(3).FaceAlpha=0.5;
set(gca,'FontName','メイリオ','FontSize',11);
xlim([0.5 1]);
ylabel('Ratio');xticklabels([]);

nexttile;
bObj=bar(movmean(edges,2,"Endpoints","discard"), ...
    [histWin;histDraw;histLose]','stacked','BarWidth',1,'EdgeColor','w');
grid on;hold on;
set(gca,'FontName','メイリオ','FontSize',11);
bObj(1).FaceColor='b';bObj(1).FaceAlpha=0.5;
bObj(2).FaceColor=0.5*[1 1 1];bObj(2).FaceAlpha=0.5;
bObj(3).FaceColor='r';bObj(3).FaceAlpha=0.5;
set(gca,'FontName','メイリオ');
xlim([0.5 1]);
xlabel('予測勝率+予測引き分け率/2');
ylabel('Frequency')
legend({'予測正解','引き分け','予測不正解'},'Location','northoutside','Orientation','horizontal');
exportgraphics(gcf,'predictionPerformance_Olympic2024_PredAndActualWins.png')
exportgraphics(gcf,'predictionPerformance_Olympic2024_PredAndActualWins.pdf')

%% 競技・種目ごとの集計


Sport=[];Sex=[];
Matches=[];CorrectsRating=[];CorrectsRanking=[];
LogLoss=[];DiffPreds=[];Draws=[];Calibration=[];
for tmpSportName={'basketball','handball','hockey','volleyball','waterpolo'}
    for tmpSexStr={'M','W'}
        disp([tmpSportName{1} ' ' tmpSexStr{1}]);
        Sport=[Sport;tmpSportName];
        Sex=[Sex;tmpSexStr];
        ind = tbl_finished.Sport==tmpSportName{1} & tbl_finished.SexStr==tmpSexStr{1};
        tbl_tmp=tbl_finished(ind,:);
        Matches=[Matches;size(tbl_tmp,1)];
        CorrectsRating=[CorrectsRating;sum(tbl_tmp.isCorrectRating==true)];
        CorrectsRanking=[CorrectsRanking;sum(tbl_tmp.isCorrectRanking)];
        LogLoss=[LogLoss;mean(tbl_tmp.LogLoss)];
        Calibration=[Calibration;
            sum(pMat(ind,1)+pMat(ind,2)/2) / sum(rMat(ind,1)+rMat(ind,2)/2)];
        DiffPreds=[DiffPreds;...
            sum(tbl_tmp.PredRating~=tbl_tmp.PredRanking) ];
        Draws=[Draws; ...
            sum(tbl_tmp.aWin==0.5)];
        w=tbl_tmp.aWin;
        wHat=tbl_tmp.pWin+tbl_tmp.pDraw/2;

    end
end

tbl_performanceBySport=table();
tbl_performanceBySport=addvars(tbl_performanceBySport, ...
    Sport,Sex,Matches, DiffPreds,...
    CorrectsRating, CorrectsRanking, Draws,LogLoss, Calibration);
tbl_performanceBySport.Sport=categorical(tbl_performanceBySport.Sport);
tbl_performanceBySport.Sex=categorical(tbl_performanceBySport.Sex);

tbl_performanceBySport

figure;
scatter(tbl_performanceBySport.LogLoss, tbl_performanceBySport.Calibration);
grid on;hold on;
set(gca,'FontName','メイリオ');
xlabel('対数損失');ylabel('較正値');
for n1=1:size(tbl_performanceBySport,1)
    tmpStr=char(tbl_performanceBySport.Sport(n1));
    tmpStr=[tmpStr(1:2) '[' char(tbl_performanceBySport.Sex(n1)) ']'];
    tmpStr=upper(tmpStr);
    text(tbl_performanceBySport.LogLoss(n1), ...
        tbl_performanceBySport.Calibration(n1), ...
        ['  ' tmpStr],'fontname','Arial','Rotation',10)
end
yline(1);xlim([0.5 1]);
%全体
scatter(mean(tbl_finished.LogLoss), caibVal,'rs');
text(mean(tbl_finished.LogLoss), caibVal, ...
    ['  Overall' ],'fontname','Arial');

title('パリ五輪5競技10種目予測性能')
exportgraphics(gcf,'predictionPerformance_Olympic2024_bySport.pdf')

%
figure;
plotX=tbl_performanceBySport.CorrectsRating./tbl_performanceBySport.Matches;
plotY=tbl_performanceBySport.CorrectsRanking./tbl_performanceBySport.Matches;
scatter(plotX,plotY);
grid on;hold on;axis equal;
set(gca,'FontName','メイリオ');
xlabel('予測正解率(レーティング)');ylabel('予測正解率(ランキング)');

for n1=1:size(tbl_performanceBySport,1)
    tmpStr=char(tbl_performanceBySport.Sport(n1));
    tmpStr=[tmpStr(1:2) '[' char(tbl_performanceBySport.Sex(n1)) ']'];
    tmpStr=upper(tmpStr);
    text(plotX(n1),plotY(n1), ...
        ['  ' tmpStr],'fontname','Arial','Rotation',10)
end

plotX=sum(tbl_performanceBySport.CorrectsRating)./sum(tbl_performanceBySport.Matches);
plotY=sum(tbl_performanceBySport.CorrectsRanking)./sum(tbl_performanceBySport.Matches);
scatter(plotX,plotY,'rs');
text(plotX, plotY, ...
    ['  Overall' ],'fontname','Arial');



axis([0.6 0.9 0.6 0.9]);
plot([0.6 0.9],[0.6 0.9],'r:');
title('パリ五輪5競技10種目予測正解率')
exportgraphics(gcf,'predictionAccuracy_Olympic2024_bySport.pdf')
%% メダル予測性能

tbl_medalPred=readtable('olympic2024MedalPrediction.xlsx', ...
    'VariableNamingRule','preserve');
tbl_medalPred.Sport=categorical(tbl_medalPred.Sport);
tbl_medalPred.Sex=categorical(tbl_medalPred.Sex);
tbl_medalPred.Medal=categorical(tbl_medalPred.Medal);
varNames=tbl_medalPred.Properties.VariableNames;
for n1=4:size(tbl_medalPred,2)
    tbl_medalPred=addvars(tbl_medalPred, categorical(tbl_medalPred(:,n1).Variables));
end
tbl_medalPred(:,4:size(varNames,2))=[];
tbl_medalPred.Properties.VariableNames(4:end)=varNames(4:end);

tbl_medalPred
varNames=varNames(5:end)'
tbl_performanceByPredictor=table();
tbl_performanceByPredictor=addvars(tbl_performanceByPredictor,varNames,'NewVariableNames','Predictor');

Predictions=[];Medals=[];Podiums=[];
for n1=1:size(tbl_performanceByPredictor,1)
    predictorName=tbl_performanceByPredictor.Predictor(n1);
    size(rmmissing(tbl_medalPred(:,predictorName).Variables),1);
    Predictions=[Predictions;ans];

    sum(tbl_medalPred.Result==tbl_medalPred(:,predictorName{1}).Variables);
    Medals=[Medals;ans];

    tmp=0;
    % 3行ずつであることを前提とした処理
    for n2=1:3:30
        [tbl_medalPred.Result(n2:n2+2), tbl_medalPred(n2:n2+2,predictorName{1}).Variables];
        tmp=tmp ...
            +sum(ismember(tbl_medalPred.Result(n2:n2+2), tbl_medalPred(n2:n2+2,predictorName{1}).Variables));
    end
    Podiums=[Podiums;tmp];
end

tbl_performanceByPredictor=addvars(tbl_performanceByPredictor,Predictions, Medals, Podiums);
tbl_performanceByPredictor

writetable(tbl_performanceByPredictor,'olympic2024MedalPrediction.xlsx','Sheet','Result');
