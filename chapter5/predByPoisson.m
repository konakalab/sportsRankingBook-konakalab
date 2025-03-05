function [pMatOut] = predByPoisson(GF, GA)
bins=0:12;

pMatOut=[];
for n1=1:size(GA,1)
    muGA=GA(n1);
    muGF=GF(n1);
    pGF=poisspdf(bins,muGF);
    pGA=poisspdf(bins,muGA);
    pMat=pGA'*pGF;
    pWin=sum(triu(pMat,1),'all');    %1行上にずらした上三角部分を取り出し，すべて足す
    pDraw=sum(diag(pMat));   %対角要素を取り出し，すべて足す
    pLose=sum(tril(pMat,-1),'all');  %1行下にずらした下三角部分を取り出し，すべて足す
    pMatOut=[pMatOut;pWin pDraw pLose];
end
end