function [Ps, tau] = sadovskiy(W,scaledDist)
crW = W^(1/3);
kgcmsq2pa = 98066.5;
R = scaledDist*crW;

tau = nthroot(W,6)*sqrt(R)/1000;

Ps = (0.95*(crW/R) + 3.9*((crW/R)^2) + 13*((crW/R)^3))*kgcmsq2pa;
if isnan(Ps)
    1;
end
end