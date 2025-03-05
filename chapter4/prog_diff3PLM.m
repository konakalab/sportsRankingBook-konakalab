clear
clc
close all

syms a0 a1 c x w

J=(w- (c+(1-2*c)/(1+exp(-(a0+a1*x)))))^2
diff(J,c)
diff(J,a0)
diff(J,a1)

clear
%%

rho=1e-4;
c=0;a0=0;a1=0.1;

load sample_ratingConv.mat
RateDiff_org=RateDiff;
RateDiff=[RateDiff_org;-RateDiff_org];

ActualWin_org=ActualWin;
ActualWin=[ActualWin_org;1-ActualWin_org];

figure;hold on;
bins=-30:30;
for k=1:10
    ind = randperm(size(ActualWin,1));
    for n1=1:size(ActualWin,1)
        x=RateDiff(ind(n1));
        w=ActualWin(ind(n1));

        c=c ...
            -rho*(2*(2/(exp(- a1*x - a0) + 1) - 1)*(w - c + (2*c - 1)/(exp(- a1*x - a0) + 1)));
        % 
        % a0=a0 ...
        %     +rho*((2*exp(- a1*x - a0)*(2*c - 1)*(c - w + (2*c - 1)/(exp(- a1*x - a0) + 1)))/(exp(- a0 - a1*x) + 1)^2);
        %
        a1=a1 ...
            -rho*((2*x*exp(- a1*x - a0)*(2*c - 1)*(w - c + (2*c - 1)/(exp(- a1*x - a0) + 1)))/(exp(- a0 - a1*x) + 1)^2);


        % [x w a1]
    end
    [k a0 a1 c]
    plot(bins, c+(1-2*c)./(1+exp(-a0-a1*bins)), '-');

    x=RateDiff;
    w=ActualWin;
    wHat=c+(1-2*c)./(1+exp(-a0-a1*x));
    mean((wHat-w).^2)
end