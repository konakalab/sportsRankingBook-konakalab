% predictionByMatch

load(['prediction_' Opt.sexStr '_.mat']);

% オリンピックの試合の読み込み
inFileName=['matches_Olympic_' Opt.sexStr '_2024.xlsx'];
outFileName=['matches_Olympic_' Opt.sexStr '_2024.csv'];

[~,~,raw]=xlsread(inFileName,'matches');
tbl_h2h=array2table(raw);
tbl_h2h.Properties.VariableNames=raw(1,:);
tbl_h2h(1,:)=[];
tbl_h2h.Date=datetime(tbl_h2h.Date);
tbl_h2h.TeamA=categorical(tbl_h2h.TeamA);
tbl_h2h.TeamB=categorical(tbl_h2h.TeamB);

% ランキングはあらかじめ公式サイトなどで調査しておく
[~,~,raw]=xlsread(inFileName,'ranking');
tbl_ranking=array2table(raw);
tbl_ranking.Properties.VariableNames=raw(1,:);
tbl_ranking(1,:)=[];
tbl_ranking.Team=categorical(tbl_ranking.Team);
tbl_ranking.Ranking=cell2mat(tbl_ranking.Ranking);

% 各対戦の予測勝率を計算する
outData=[];outDataRanking=[];
for n1=1:size(tbl_h2h,1)
    taRating=tbl_teams.ratingValues(tbl_teams.Team==tbl_h2h.TeamA(n1));
    if  tbl_h2h.TeamA(n1)==venueName
        taRating=taRating+homeAdv;
    end

    tbRating=tbl_teams.ratingValues(tbl_teams.Team==tbl_h2h.TeamB(n1));
    if  tbl_h2h.TeamB(n1)==venueName
        tbRating=tbRating+homeAdv;
    end
    
    taRanking=tbl_ranking.Ranking(tbl_ranking.Team==tbl_h2h.TeamA(n1));
    tbRanking=tbl_ranking.Ranking(tbl_ranking.Team==tbl_h2h.TeamB(n1));
    
    rDiffVal=taRating-tbRating;
    
    pWin=glmval(mdl, rDiffVal, 'logit');
    outData=[outData;taRating tbRating pWin];
    outDataRanking=[outDataRanking;taRanking tbRanking];

end

writematrix(outData, inFileName,'Sheet','matches','Range','D2');
writematrix(outDataRanking, inFileName,'Sheet','matches','Range','G2');
tbl_tmp=readtable(inFileName);
writetable(tbl_tmp, outFileName)
