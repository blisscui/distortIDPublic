% =========================================================================
% FITPFUNCNAFC_BC
% =========================================================================
% PURPOSE:  Fit a cumulative Gaussian psychometric function to nAFC data with bias correction (BC variant).
% PROJECT:  General utilities
% CREATED:  2021-12-10
% UPDATED:  2021-12-10
% =========================================================================

function [ fitobject, gof, thresholdEst, ci, chiSqFitReject ] = fitPFuncnAFC_BC( level, response, nAFC, graphData, sign )

% Fit data from nAFC using cumulative gaussian psychometric function.
% Function returns fitted parameters, goodness of fit, and 95%
% confidence intervals for the fitted parameters.
% % example data
% level=[0.500000000000000;0.445625469066873;0.397164117362141;0.353972892192069;0.315478672240097;0.281170662595175;0.250593616813636;0.223341796075482;0.199053585276749;0.177406694616788;0.158113883008419;0.140919146563223;0.125594321575479;0.111936056928417;0.0997631157484441;0.125594321575479;0.111936056928417;0.0997631157484441;0.0889139705019463;0.0792446596230558;0.0997631157484441;0.0889139705019463;0.0792446596230558;0.0706268772311378;0.0629462705897085;0.0561009227150983;0.0500000000000001;0.0445625469066874;0.0397164117362142;0.0353972892192070;0.0445625469066874;0.0397164117362142;0.0353972892192070;0.0315478672240097;0.0397164117362142;0.0500000000000001;0.0629462705897085;0.0561009227150983;0.0706268772311379;0.0629462705897085;0.0792446596230559;0.0997631157484443;0.0889139705019464;0.0792446596230559;0.0706268772311380;0.0629462705897086;0.0561009227150984;0.0706268772311380;0.0889139705019465;0.111936056928417];
% response=[1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;1;1;1;1;0;1;1;1;1;1;1;1;1;1;0;1;1;1;0;0;0;1;0;1;0;0;1;1;1;1;1;0;0;0;0];
% nAFC=2;
% graphData=1;

if nAFC>0; pGuess=1/nAFC; % guess rate: .25
else pGuess=0;
end

if nargin==4
    sign=1;
end

arrangedData=arrangeData(double(level), response); %40 trials responses (hover mouse over it)
tLevel=arrangedData(:,1); 
nTests=arrangedData(:,2);
pCorrect=arrangedData(:,4);
dataErrEst=arrangedData(:,8); %Binomial standard deviation: some value between 0 and any number, depends on how many numbers have been done" calculation of the SD of the trials
%   nAFC cumulative gaussian
if any(isnan(dataErrEst)) %if NaN or failed, will assign it to be 1
    dataErrEst=ones(size(dataErrEst));
end

% % ft = fittype( @(thresh, slope,x)(pGuess + (1-pGuess).*(0.5+0.5.*erf((x-thresh)./(sqrt(2).*slope)))));
ft = fittype( @(thresh, slope,x)(pGuess + (1-pGuess).*(0.5+sign*0.5.*erf((x-thresh)./(sqrt(2).*slope))))); % tlevel: threshold level
%[fitobject, gof] = fit(tLevel, pCorrect,ft, 'StartPoint', [mean(tLevel) std(tLevel)], 'Weights', 1./dataErrEst);
%[fitobject, gof] = fit(tLevel, pCorrect,ft, 'StartPoint', [mean(tLevel) std(tLevel)]);%, 'Weights', 1./dataErrEst);
[fitobject, gof] = fit(tLevel, pCorrect,ft, 'StartPoint', [mean(tLevel) std(tLevel)], 'Weights', 1./dataErrEst,  'Upper',[max(tLevel) range(tLevel)],  'Lower',[min(tLevel) min(diff(tLevel))]); %1/weight: set upper and lower bound on the fit, force it to bewithin range. want slope to be the range of the T level
% [fitobject, gof] = fit(tLevel, pCorrect,ft);%, 'StartPoint', [mean(tLevel) std(tLevel)]);
thresholdEst=fitobject.thresh;
ci = confint(fitobject); %ci: confidence interval: 95%

expVals=fitobject(tLevel); % evaluate fit at test levels
chiSqFitReject=chi2gof(sum(((expVals-pCorrect).^2)./expVals), 'Alpha', 0.05, 'NBins',length(tLevel), 'NParams', 2 ); % test hypothesis that fit is significantly different from data (0 means fit is accepted)

if graphData %x: test level, should get graph of the different wavelengths
    ci95 = predint(fitobject,tLevel,0.95,'functional','off') % pull 95% confdence intervals from fitParams at each test level
    %          scatter(tLevel, pCorrect,nTests+20, 'MarkerFaceColor','b','MarkerEdgeColor','b','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2);
    %         hold on
    errorbar(tLevel, pCorrect, dataErrEst, dataErrEst, 'bo');%, 'MarkerSize',nTests+2);
    hold on
    ylim([0,1]);
    plot(fitobject, 'r-');
    if ~any(isnan(ci95(:))) % no NaNs in confidence intervals
        plot(tLevel,ci95,'g--'); % plot 95% confidence interval on fit line
    end
    hold off
    legend HIDE
    box off
%     set(gca, 'XScale', 'log');
    xlabel('Test Level');
    ylabel('Proportion Correct');
    title(sprintf('Threshold=%.2f, 95%% CI (%.2f,%.2f)', thresholdEst, ci(1,1), ci(2,1)));
    
end
end

