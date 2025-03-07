clear
clc
close all

Opt.nSeasons=20000;
Opt.method='Elo';
Opt.sportName='Hockey';
Opt.min_pWin=0.01;
Opt.sexStr='M';


calcRating_hockey
prediction_hockey
predictionByMatch

%%

Opt.sexStr='W'

calcRating_hockey
prediction_hockey
predictionByMatch

