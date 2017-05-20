clear;
load('bbgdata.mat');

%% Variables
%
% P Q <- Switching Probability
% uu1 uu2 <- World Excess Return
% th1 th2 <- World Volatility
%

%% Assumptions 
%
% uuz = uRf
Returns = Returns /100;
uuz = mean(Returns(:,1))/12;

wRet = Returns(:,5); % Annualised world return per month
wExRet = wRet - Returns(:,1)/12;

%% Output Here

addpath('MS_Regress-Matlab')
addpath('MS_Regress-Matlab/m_Files'); % add 'm_Files' folder to the search path

constVec=ones(length(wExRet),1); % A constant vector in mean equation (just an example of how to do it)
indep = [constVec];
k=2;                                % Number of States
S=[1 1];                        % Defining which parts of the equation will switch states (column 1 and variance only)
advOpt.distrib='Normal';            % The Distribution assumption ('Normal', 't' or 'GED')
advOpt.std_method=1;                % Defining the method for calculation of standard errors. See pdf file for more details

[Spec_Out]=MS_Regress_Fit(wExRet,indep,k,S,advOpt) % Estimating the model

%% Plot Return & Probabilities
val = [100];
subplot(2,1,2);
plot(Spec_Out.filtProb(:,1));
subplot(2,1,1);
hold on
for i=1:length(wExRet)
    val = [val val(end)*exp(wExRet(i))];
    if(Spec_Out.filtProb(i,1)<.5)
        plot(i,val(i),'r+');
    else
        plot(i,val(i),'g+');
    end
    
end

P = Spec_Out.Coeff.p(1,1);
Q = Spec_Out.Coeff.p(2,2);

%% Mu and Sigma for Each Regimes

uus = Spec_Out.Coeff.S_Param{1};
sis = [sqrt(Spec_Out.Coeff.covMat{1}) sqrt(Spec_Out.Coeff.covMat{2})];

%% Betas of Assets

[betas, ses, vols,covAMs] = getBetas;

%% Resulted Values

condER = [P*uus(1)+(1-P)*uus(2) (1-Q)*uus(1)+Q*uus(2)];
condVar = [P*sis(1)^2+(1-P)*sis(2)^2+P*(1-P)*(uus(1)-uus(2))^2 (1-Q)*sis(1)^2+Q*sis(2)^2+Q*(1-Q)*(uus(1)-uus(2))^2];
condStd = sqrt(condVar);

%% Asset Expected Returns for Next Period given Current State of Regime 

ER = uuz + (condER'-uuz)*betas;

%% Asset Idiosyncratic Risk (StD) by Deducting Market Vol * Indi Beta from Indi Vol
mVol = vols(5);
idioVols = sqrt(var(Returns - wRet*betas));
% Sigs = condStd'*betas+ones(2,1)*idioVols

%% Estimate Covariance Matrix
% Kill 1 2

v = diag(idioVols);
Om1 = (betas*betas')*(condStd(1))^2+v;
Om2 = (betas*betas')*(condStd(2))^2+v;

Sigma1 = P*Om1+(1-P)*Om2+P*(1-P)*(ER(1,:)-ER(2,:))*(ER(1,:)-ER(2,:))'
Sigma2 = (1-Q)*Om1+Q*Om2+Q*(1-Q)*(ER(1,:)-ER(2,:))*(ER(1,:)-ER(2,:))'

w1 = inv(Sigma1)*ER(1,:)'
w2 = inv(Sigma2)*ER(2,:)'

%% ER: Expected Returns, Sigs: Expected Volatilities for Assets (1,2,..., 12) under Regime 1 / 2

