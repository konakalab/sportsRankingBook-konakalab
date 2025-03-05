clear
clc
close all

Opt.nSeasons=20000; %シミュレーション回数
Opt.method='Elo';
Opt.sportName='Basketball'; % 競技名
Opt.min_pWin=0.01;  % 最小勝率

Opt.sexStr='M';
%%

calcRating;
prediction_basketball;
predictionByMatch;

%%

Opt.sexStr='W';

calcRating;
prediction_basketball;
predictionByMatch;


