
switch Opt.sexStr
    case 'M'
        load prediction_M_.mat
        inFileName='matches_Olympic_M_2024.xlsx'

    case 'W'
        load prediction_W_.mat
        inFileName='matches_Olympic_W_2024.xlsx'

end

% オリンピックの試合の読み込み
tbl_h2h=readtable(inFileName,'Sheet','matches');
tbl_h2h.TeamA=categorical(tbl_h2h.TeamA);
tbl_h2h.TeamB=categorical(tbl_h2h.TeamB);

head(tbl_h2h)

% ランキングはあらかじめ公式サイトなどで調査しておく
tbl_ranking=readtable(inFileName,'Sheet','ranking');
tbl_ranking.Team=categorical(tbl_ranking.Team);
tbl_ranking.Ranking=cell2mat(tbl_ranking.Ranking);


% 各対戦の予測勝率を計算する
outData=[];outDataRanking=[];
for n1=1:size(tbl_h2h,1)
    taRating=tbl_teams.ratingValues(tbl_teams.Team==tbl_h2h.TeamA(n1));
    if tbl_h2h.TeamA(n1)==venueName
        taRating=taRating+homeAdv;
    end

    tbRating=tbl_teams.ratingValues(tbl_teams.Team==tbl_h2h.TeamB(n1));
    if tbl_h2h.TeamB(n1)==venueName
        tbRating=tbRating+homeAdv;
    end

    taRanking=tbl_ranking.Ranking(tbl_ranking.Team==tbl_h2h.TeamA(n1));
    tbRanking=tbl_ranking.Ranking(tbl_ranking.Team==tbl_h2h.TeamB(n1));

    rDiffVal=taRating-tbRating;

    % ホッケーのみ修正
    pWin=glmval(mdl.win, rDiffVal, 'logit');
    pLose=glmval(mdl.lose, rDiffVal, 'logit');

    if tbl_h2h.Date(n1)<datetime(2024,8,4,0,0,0) ...
            outData=[outData;taRating tbRating pWin 1-pWin-pLose pLose];
    else
        try
            outData=[outData;taRating tbRating pWin/(pWin+pLose) 0 pLose/(pWin+pLose)]
        catch
        end
    end
    outDataRanking=[outDataRanking;taRanking tbRanking];

end

outData
writematrix(outData, inFileName,'Sheet','matches','Range','D2');
writematrix(outDataRanking, inFileName,'Sheet','matches','Range','I2');