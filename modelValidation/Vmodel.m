function modelV = Vmodel(params, scaledTime, hval)

% Unpack parameters
Vs_i = params(1);
alpha_i = params(2);
beta_i = params(3);
a_i = params(4);

% Set the mach to m/s conversion
mach2ms = 1/343;

% Calculate the velocity from the model, based on the parameters, and the current times
modelV = (((Vs_i*(1-beta_i*scaledTime) .* exp(-alpha_i*scaledTime) + a_i*log(1 + beta_i*scaledTime)) .* exp(-scaledTime).*hval)*mach2ms)';
1;
end