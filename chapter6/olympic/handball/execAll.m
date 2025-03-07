clear
clc
close all

Opt.nSeasons=20000;
Opt.method='Elo';
Opt.sportName='Handball';
Opt.min_pWin=0.01;
%%

Opt.sexStr='M'

calcRating
prediction_handball
predictionByMatch
%%

Opt.sexStr='W'

calcRating
prediction_handball
predictionByMatch

