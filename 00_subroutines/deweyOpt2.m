function modelV = deweyOpt2(x, xdata, currParams)
% Function to use with lsqcurvefit
%
% Inputs:
%     x = matrix of parameters to be optimized
%       = [Vs, alpha, beta, a]
%     xdata = scaledTime
%     currParams = structure with the following variables
%          - dataV: velocity data at the r associated with this run of parameters
%          - t0: Calculated time when the blast model should "start"
% 
% Outputs
%     error = ||V-dataV||

% Set the mach to m/s conversion
mach2ms = 343;

% Get scaled time values
% scaledTime = currParams.times/currParams.W;

% Calculate heaviside values
hval = ceil(heaviside(currParams.times-currParams.t0));

% Calculate the velocity from the model, based on the parameters, and the current times
modelV = Vmodel(x, xdata, hval)*mach2ms;

% Troubleshooting figure, copy/paste the below into the command window when you pause in this script
% figure();set(gcf,'Color','w');plot(scaledTime,modelV,'k-','DisplayName','Model');hold on;plot(scaledTime,currParams.dataV,'r--','DisplayName','Data');xlabel('Scaled time');ylabel('Umag (m/s)');legend('Location','best')
end