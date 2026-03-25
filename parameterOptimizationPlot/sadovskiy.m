function [Ps, tau] = sadovskiy(W,scaledDist)
% Set common consts
crW = W^(1/3);
mpa2bar = 10;
mpa2kpa = 1000;
mpa2pa = 1000000;
kgcmsq2pa = 98066.5;
kgcmsq2kpa = 98.0665;
atm2kpa = 101.325;
R = scaledDist*crW;

z = crW/R;

% Calculate values from Sadovisky/ Goel

tau = nthroot(W,6)*sqrt(R)/1000; % converted to seconds
tau2 = (1.2*sqrt(scaledDist))/1000; % converted to seconds


% Ps = ((0.085.*(crW./R)) + (0.3.*(crW./R).^2) + (0.8.*(crW./R).^3))*mpa2pa;
% Ps = ((0.085.*(crW./S)) + (0.3.*(crW./S).^2) + (0.8.*(crW./S).^3))*mpa2kpa;
% Ps = ((0.085.*(W./R)) + (0.3.*(W./R).^2) + (0.8.*(W./R).^3))*mpa2kpa;
% Ps = ((0.085.*(W./S)) + (0.3.*(W./S).^2) + (0.8.*(W./S).^3))*mpa2kpa;
% Ps = ((0.085.*(crW./S)) + (0.3.*(crW./S).^2) + (0.8.*(crW./S).^3))*mpa2kpa;
% Ps = ((0.085.*(crW./S)) + (0.3.*(crW./S).^2) + (0.8.*(crW./S).^3))*kgcmsq2pa;
% Ps = ((0.085.*(W./R)) + (0.3.*(W./R).^2) + (0.8.*(W./R).^3))*mpa2pa;
% Ps = ((10.9/z) + (450/(z^2)) +(15000/(z^3)))*kgcmsq2kpa;
Ps = (0.95*(crW/R) + 3.9*((crW/R)^2) + 13*((crW/R)^3))*kgcmsq2pa;
end