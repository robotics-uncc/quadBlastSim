%% Setup the dewey parameter interpolation functions
function [v,alpha,beta,a,tstar] = deweyParams(scaledDist)
%% Function info:
% Inputs:
%      scaledDist = d/S = double
%          d = distance from blast
%          S = (W*P0/P)^(1/3)
%               W = weight of explosive used in blast
%               P0 = standard pressure = 101.325
%               P = ambient pressure
%
% Outputs:
%      v = peak velocity (m/s), converted from mach
%      alpha = unitless fitted parameter
%      beta = unitless fitted parameter
%      a = unitless fitted parameter
%      tstar = unitless fitted parameter

%% Setup the dewey parameter interpolation functions
% Set functions for interpolating the parameters, with their derivatives
function out = vMachFcn(xx,option)
    if option == 1
        % vMach = 3.37 + -1.85*xx + 0.387*xx^2 + -0.0284*xx^3; % 3rd order polynomial
        vMach1 = 6.38*xx^-1.51;
        out = vMach1;
    elseif option == 2
        vMachDer = (-1.51*6.38)*xx^(-1.51-1);
        out = vMachDer;
    else
        error('Choose a valid output option')
    end
end

function out = alphaFcn(xx, option)
    if option == 1
        % alpha = 1.69 + -0.963*xx + 0.22*xx^2 + -0.0174*xx^3; % 3rd order polynomial
        alpha1 = 1.5*xx^-0.926; % power series
        out = alpha1;
    elseif option == 2
        alphaDer = (-0.926*1.5)*xx^(-0.926-1);
        out = alphaDer;
    else
        error('Choose a valid output option')
    end
end

function out = betaFcn(xx,option)
    % beta = 1.63 + -0.28*xx + 0.0434*xx^2 + -2.66E-03*xx^3; % 3rd order polynomial
    % beta = -0.0766*xx + 1.35; % linear
    % out = beta;
    if option == 1
        % beta1 = 1.54-0.262*log(xx); % Log
        beta1 = 1.64*xx^(-0.241); % Power
        out = beta1;
    elseif option == 2
        betaDer = (-0.241*1.64)*xx^(-0.241-1);
        % betaDer = -0.262/xx;
        out = betaDer;
    else
        error('Choose a valid output option')
    end
end

function out = aFcn(xx,option)
    if option == 1
        % a = 1.1 + -0.373*xx + 0.0521*xx^2 + -2.55E-03*xx^3; % 3rd order polynomial
        a1 = 1.95*xx^-1.02; % power series
        out = a1;
    elseif option == 2
        aDer = (-1.02*1.95)*xx^(-1.02-1);
        out = aDer;
    else
        error('Choose a valid output option')
    end
end

function out = tstarFcn(xx,option)
    % tstar = 0.115 + 0.352*xx + 0.0131*xx^2 + -4.3E-03*xx^3; % 3rd order polynomial 
    % tstar = 0.274*xx + 0.335; % linear
    % out = tstar;
    if option == 1
        tstar1 = -0.326+0.93*log(xx); % Log
        out = tstar1;
    elseif option == 2
        tstarDer = 0.93/xx;
        out = tstarDer;
    else
        error('Choose a valid output option')
    end
end

% Set point to swtich from fitted curves to linear extrapolation for power series fits
xpt = 1.983489191;

% Conversions
mach2ms = 343;

% Set scaleDist to x for readability
xx = scaledDist;
% xx = abs(scaledDist);
% ss = sign(scaledDist);

% Peak velocity value - power series/ linear piecewise interpolation
if xx >= xpt
    % Regular interp function
    vMach = vMachFcn(xx,1);
else
    % Linear interp function
    yVal = vMachFcn(xpt,1);
    slope = vMachFcn(xpt,2);
    yIntercept = yVal - slope*xpt;
    vMach = slope*xx + yIntercept;
end
% v = vMach * mach2ms;
v = vMach;

% Alpha - power series/ linear piecewise interpolation
if xx >= xpt
    % Regular interp function
    alpha = alphaFcn(xx,1);
else
    % Linear interp function
    yVal = alphaFcn(xpt,1);
    slope = alphaFcn(xpt,2);
    yIntercept = yVal - slope*xpt;
    alpha = slope*xx + yIntercept;
end

% Beta - linear interpolation
% beta = betaFcn(xx);
if xx >= xpt
    % Regular interp function
    beta = betaFcn(xx,1);
else
    % Linear interp function
    yVal = betaFcn(xpt,1);
    slope = betaFcn(xpt,2);
    yIntercept = yVal - slope*xpt;
    beta = slope*xx + yIntercept;
end

% a - power series/ linear piecewise interpolation
if xx >= xpt
    % Regular interp function
    a = aFcn(xx,1);
else
    % Linear interp function
    yVal = aFcn(xpt,1);
    slope = aFcn(xpt,2);
    yIntercept = yVal - slope*xpt;
    a = slope*xx + yIntercept;
end

% tstar - linear interpolation
% tstar = tstarFcn(xx);
if xx >= xpt
    % Regular interp function
    tstar = tstarFcn(xx,1);
else
    % Linear interp function
    yVal = tstarFcn(xpt,1);
    slope = tstarFcn(xpt,2);
    yIntercept = yVal - slope*xpt;
    tstar = slope*xx + yIntercept;
end

end



%% Archive
% function [v,alpha,beta,a,tstar] = deweyParams(scaledDist)
% %% Function info:
% % Inputs:
% %      scaledDist = d/S = double
% %          d = distance from blast
% %          S = (W*P0/P)^(1/3)
% %               W = weight of explosive used in blast
% %               P0 = standard pressure = 101.325
% %               P = ambient pressure
% %
% % Outputs:
% %      v = peak velocity (m/s), converted from mach
% %      alpha = unitless fitted parameter
% %      beta = unitless fitted parameter
% %      a = unitless fitted parameter
% %      tstar = unitless fitted parameter
% 
% %% Setup the dewey parameter interpolation functions
% % Set functions for interpolating the parameters, with their derivatives
% function out = vMachFcn(xx,option)
%     if option == 1
%         % vMach = 3.37 + -1.85*xx + 0.387*xx^2 + -0.0284*xx^3; % 3rd order polynomial
%         vMach1 = 6.38*xx^-1.51;
%         out = vMach1;
%     elseif option == 2
%         vMachDer = (-1.51*6.38)*xx^(-1.51-1);
%         out = vMachDer;
%     else
%         error('Choose a valid output option')
%     end
% end
% 
% function out = alphaFcn(xx, option)
%     if option == 1
%         % alpha = 1.69 + -0.963*xx + 0.22*xx^2 + -0.0174*xx^3; % 3rd order polynomial
%         alpha1 = 1.5*xx^-0.926; % power series
%         out = alpha1;
%     elseif option == 2
%         alphaDer = (-0.926*1.5)*xx^(-0.926-1);
%         out = alphaDer;
%     else
%         error('Choose a valid output option')
%     end
% end
% 
% function out = betaFcn(xx,option)
%     % beta = 1.63 + -0.28*xx + 0.0434*xx^2 + -2.66E-03*xx^3; % 3rd order polynomial
%     % beta = -0.0766*xx + 1.35; % linear
%     % out = beta;
%     if option == 1
%         beta1 = 1.54-0.262*log(xx); % Log
%         out = beta1;
%     elseif option == 2
%         betaDer = -0.262/xx;
%         out = betaDer;
%     else
%         error('Choose a valid output option')
%     end
% end
% 
% function out = aFcn(xx,option)
%     if option == 1
%         % a = 1.1 + -0.373*xx + 0.0521*xx^2 + -2.55E-03*xx^3; % 3rd order polynomial
%         a1 = 1.95*xx^-1.02; % power series
%         out = a1;
%     elseif option == 2
%         aDer = (-1.02*1.95)*xx^(-1.02-1);
%         out = aDer;
%     else
%         error('Choose a valid output option')
%     end
% end
% 
% function out = tstarFcn(xx,option)
%     % tstar = 0.115 + 0.352*xx + 0.0131*xx^2 + -4.3E-03*xx^3; % 3rd order polynomial 
%     % tstar = 0.274*xx + 0.335; % linear
%     % out = tstar;
%     if option == 1
%         tstar1 = -0.326+0.93*log(xx); % Log
%         out = tstar1;
%     elseif option == 2
%         tstarDer = 0.93/xx;
%         out = tstarDer;
%     else
%         error('Choose a valid output option')
%     end
% end
% 
% % Set point to swtich from fitted curves to linear extrapolation for power series fits
% xpt = 1.983489191;
% 
% % Conversions
% mach2ms = 343;
% 
% % Set scaleDist to x for readability
% xx = scaledDist;
% % xx = abs(scaledDist);
% % ss = sign(scaledDist);
% 
% % Peak velocity value - power series/ linear piecewise interpolation
% if xx >= xpt
%     % Regular interp function
%     vMach = vMachFcn(xx,1);
% else
%     % Linear interp function
%     yVal = vMachFcn(xpt,1);
%     slope = vMachFcn(xpt,2);
%     yIntercept = yVal - slope*xpt;
%     vMach = slope*xx + yIntercept;
% end
% % v = vMach * mach2ms;
% v = vMach;
% 
% % Alpha - power series/ linear piecewise interpolation
% if xx >= xpt
%     % Regular interp function
%     alpha = alphaFcn(xx,1);
% else
%     % Linear interp function
%     yVal = alphaFcn(xpt,1);
%     slope = alphaFcn(xpt,2);
%     yIntercept = yVal - slope*xpt;
%     alpha = slope*xx + yIntercept;
% end
% 
% % Beta - linear interpolation
% % beta = betaFcn(xx);
% if xx >= xpt
%     % Regular interp function
%     beta = betaFcn(xx,1);
% else
%     % Linear interp function
%     yVal = betaFcn(xpt,1);
%     slope = betaFcn(xpt,2);
%     yIntercept = yVal - slope*xpt;
%     beta = slope*xx + yIntercept;
% end
% 
% % a - power series/ linear piecewise interpolation
% if xx >= xpt
%     % Regular interp function
%     a = aFcn(xx,1);
% else
%     % Linear interp function
%     yVal = aFcn(xpt,1);
%     slope = aFcn(xpt,2);
%     yIntercept = yVal - slope*xpt;
%     a = slope*xx + yIntercept;
% end
% 
% % tstar - linear interpolation
% % tstar = tstarFcn(xx);
% if xx >= xpt
%     % Regular interp function
%     tstar = tstarFcn(xx,1);
% else
%     % Linear interp function
%     yVal = tstarFcn(xpt,1);
%     slope = tstarFcn(xpt,2);
%     yIntercept = yVal - slope*xpt;
%     tstar = slope*xx + yIntercept;
% end
% 
% end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Archive
% function [v,alpha,beta,a,tstar] = deweyParams(scaledDist)
% %% Function info:
% % Inputs:
% %      scaledDist = d/S = double
% %          d = distance from blast
% %          S = (W*P0/P)^(1/3)
% %               W = weight of explosive used in blast
% %               P0 = standard pressure = 101.325
% %               P = ambient pressure
% %
% % Outputs:
% %      v = peak velocity (m/s), converted from mach
% %      alpha = unitless fitted parameter
% %      beta = unitless fitted parameter
% %      a = unitless fitted parameter
% %      tstar = unitless fitted parameter
% 
% % Conversions
% mach2ms = 343;
% 
% % Set scaleDist to x for readability
% xx = abs(scaledDist);
% ss = sign(scaledDist);
% 
% % Peak velocity value
% % vMach = 3.37 + -1.85*xx + 0.387*xx^2 + -0.0284*xx^3; % 3rd order polynomial
% vMach = 2.87*xx^-1.51;
% v = ss * vMach * mach2ms;
% 
% % Alpha
% % alpha = 1.69 + -0.963*xx + 0.22*xx^2 + -0.0174*xx^3; % 3rd order polynomial
% alpha = ss * (0.918*xx^-0.926); % power series
% 
% % Beta
% % beta = 1.63 + -0.28*xx + 0.0434*xx^2 + -2.66E-03*xx^3; % 3rd order polynomial
% beta = ss * (-0.0766*xx + 1.35); % linear
% 
% % a
% % a = 1.1 + -0.373*xx + 0.0521*xx^2 + -2.55E-03*xx^3; % 3rd order polynomial
% a = ss * (1.13*xx^-1.02); % power series
% 
% % tstar
% % tstar = 0.115 + 0.352*xx + 0.0131*xx^2 + -4.3E-03*xx^3; % 3rd order polynomial 
% tstar = ss * (0.274*xx + 0.335); % linear
% 
% end