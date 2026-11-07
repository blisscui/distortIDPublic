% Data are loaded relative to this script's location, so it can be run from any folder.
scriptDir = fileparts(mfilename('fullpath'));
uprightDir = fullfile(scriptDir, '..', 'IdDistort', 'Upright_Data');
invertDir  = fullfile(scriptDir, '..', 'IdDistort', 'Invert_Data');

%% Upright ID Data Extraction
sIDUpright = {'P1_UP_'; 'P2_UP_'; 'P3_UP_'; 'P4_UP_'; 'P5_UP_'; 'P6_UP_'; 'P7_UP_'; 'P8_UP_'}; 
sIDInverted = {'P1_INV_'; 'P2_INV_'; 'P3_INV_'; 'P4_INV_'; 'P5_INV_';'P6_INV_';'P7_INV_'; 'P8_INV_'};
nSubjects = length(sIDUpright);
nLambdas = 6;
lambdas = [1 2 4 8 16 32]; % Distortion frequency labels

threshDataUP = zeros(nSubjects, nLambdas);
threshDataINV = zeros(nSubjects, nLambdas);

% Load data for Upright
for sNum = 1:nSubjects
    myfile = fullfile(uprightDir, [sIDUpright{sNum} 'FaceDistort.mat']);
    load(myfile);
    for lambdaNum = 1:nLambdas
        threshDataUP(sNum, lambdaNum) = trialRecord(lambdaNum).fitObj.thresh;
    end
end

% Load data for Inverted
for sNum = 1:nSubjects
    myfile = fullfile(invertDir, [sIDInverted{sNum} 'FaceDistort.mat']);
    load(myfile);
    for lambdaNum = 1:nLambdas
        threshDataINV(sNum, lambdaNum) = trialRecord(lambdaNum).fitObj.thresh;
    end
end

%% ANOVA2 (Same as Original)
[conds, subjs] = meshgrid(1:nLambdas, 1:nSubjects);
faceType = ones(size(conds));

F1 = [faceType(:), 2*faceType(:)]; 
F2 = [conds(:), conds(:)];
S = [subjs(:), subjs(:)];
Y = [threshDataUP(:), threshDataINV(:)];

[p, tbl, stats] = anovan(Y(:), {S(:), F1(:), F2(:)}, 'random', 1, 'model', 'interaction', 'varnames', {'Subjects','Face Ori', 'Lambda'});

c = multcompare(stats, 'Dimension', [2 3]);

%% Transform X-axis for Even Spacing
logLambdas = log(lambdas); % Log-transform to get even spacing
xSmooth = linspace(min(logLambdas), max(logLambdas), 100); % Smooth x-axis

%% Generate Color Map & Subject Labels
colors = lines(nSubjects); % Generate distinct colors for subjects
subjectLabels = arrayfun(@(x) sprintf('P%d', x), 1:nSubjects, 'UniformOutput', false);

%% Upright ID Task Graph
figure;
subplot(1,3,1);
hold on;
for sNum = 1:nSubjects
    p = fit(logLambdas', threshDataUP(sNum, :)', 'smoothingspline'); % Fit spline
    plot(exp(xSmooth), p(xSmooth), '-', 'Color', colors(sNum, :), 'LineWidth', 2);
end
% Average Curve
avgUpright = mean(threshDataUP, 1);
pAvg = fit(logLambdas', avgUpright', 'smoothingspline');
plot(exp(xSmooth), pAvg(xSmooth), 'k--', 'LineWidth', 2);
xlabel('Distortion Frequency (cpi)');
ylabel('Threshold (wavelengths)');
title('Upright ID Task');
set(gca, 'XScale', 'log'); % Ensure original spacing visually
xticks(lambdas);
xticklabels(string(lambdas));
ylim([0 3]);
legend([subjectLabels, {'Average'}], 'Location', 'northeastoutside');
hold off;

%% Inverted ID Task Graph
subplot(1,3,2);
hold on;
for sNum = 1:nSubjects
    p = fit(logLambdas', threshDataINV(sNum, :)', 'smoothingspline'); % Fit spline
    plot(exp(xSmooth), p(xSmooth), '-', 'Color', colors(sNum, :), 'LineWidth', 2);
end
% Average Curve
avgInverted = mean(threshDataINV, 1);
pAvg = fit(logLambdas', avgInverted', 'smoothingspline');
plot(exp(xSmooth), pAvg(xSmooth), 'k--', 'LineWidth', 2);
xlabel('Distortion Frequency (cpi)');
ylabel('Threshold (wavelengths)');
title('Inverted ID Task');
set(gca, 'XScale', 'log');
xticks(lambdas);
xticklabels(string(lambdas));
ylim([0 3]);
legend([subjectLabels, {'Average'}], 'Location', 'northeastoutside');
hold off;

%% Face Inversion Effect (FIE) Graph
subplot(1,3,3);
hold on;
for sNum = 1:nSubjects
    FIE = threshDataUP(sNum, :) - threshDataINV(sNum, :);
    p = fit(logLambdas', FIE', 'smoothingspline'); % Fit spline
    plot(exp(xSmooth), p(xSmooth), '-', 'Color', colors(sNum, :), 'LineWidth', 2);
end
% Average Curve
avgFIE = mean(threshDataUP - threshDataINV, 1);
pAvg = fit(logLambdas', avgFIE', 'smoothingspline');
plot(exp(xSmooth), pAvg(xSmooth), 'k--', 'LineWidth', 2);
xlabel('Distortion Frequency (cpi)');
ylabel('Threshold Difference (wavelengths)');
title('FIE: Upright - Inverted');
set(gca, 'XScale', 'log');
xticks(lambdas);
xticklabels(string(lambdas));
ylim([-1 3]); % Adjusted for better visualization
legend([subjectLabels, {'Average'}], 'Location', 'northeastoutside');
hold off;
