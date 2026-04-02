function modelP = Pmodel(params, time)

% Unpack parameters
Ps = params(1);
t0 = params(2);
tau = params(3);

% Calculate common values
Dt = time-t0;
eps = Dt/tau;
% sympref('HeavisideAtOrigin', 1);
% hval = ceil(heaviside(Dt));

hval = custHeaviside(Dt);

% Calculate the velocity from the model, based on the parameters, and the current times
modelP = Ps*exp(-eps).*(1-eps).*hval;
if isnan(modelP)
    1;
end
end