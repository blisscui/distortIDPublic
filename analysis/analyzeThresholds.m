% Data are loaded relative to this script's location, so it can be run from any folder.
scriptDir = fileparts(mfilename('fullpath'));
uprightDir = fullfile(scriptDir, '..', 'data', 'upright');
invertDir  = fullfile(scriptDir, '..', 'data', 'inverted');

%% Upright ID
sIDUpright={'P1_UP_'; 'P2_UP_'; 'P3_UP_'; 'P4_UP_'; 'P5_UP_'; 'P6_UP_'; 'P7_UP_'; 'P8_UP_'}; 

nSubjects=length(sIDUpright);
nLambdas=6;

threshDataUP=zeros(nSubjects, nLambdas);

for sNum=1:nSubjects
    myfile = fullfile(uprightDir, [sIDUpright{sNum} 'FaceDistort.mat']);
    load(myfile);
    for lambdaNum=1:nLambdas
        threshDataUP(sNum, lambdaNum)=trialRecord(lambdaNum).fitObj.thresh;
    end
    
end


%% Inverted ID
sIDInverted={'P1_INV_'; 'P2_INV_'; 'P3_INV_'; 'P4_INV_'; 'P5_INV_';'P6_INV_';'P7_INV_'; 'P8_INV_'};

nSubjects=length(sIDInverted);
nLambdas=6;

threshDataINV=zeros(nSubjects, nLambdas);

for sNum=1:nSubjects
    myfile = fullfile(invertDir, [sIDInverted{sNum} 'FaceDistort.mat']);
    load(myfile);
    for lambdaNum=1:nLambdas
        threshDataINV(sNum, lambdaNum)=trialRecord(lambdaNum).fitObj.thresh;
    end
end

%% ANOVA2

[conds, subjs]=meshgrid(1:nLambdas, 1:nSubjects); % subject and condition organisation
faceType=ones(size(conds));

F1=[faceType(:), 2*faceType(:)]; 
F2=[conds(:), conds(:)];
S=[subjs(:), subjs(:)];
Y=[threshDataUP(:), threshDataINV(:)];

[p tbl stats]=anovan(Y(:),{S(:),F1(:),F2(:)},'random', 1,  'model', 'interaction', 'varnames',{'Subjects','Face Ori', 'Lambda'});

c = multcompare(stats, 'Dimension',[2 3]);

%% Box Plot
newthresh=[threshDataUP(:,1),threshDataINV(:,1) threshDataUP(:,2),threshDataINV(:,2) threshDataUP(:,3),threshDataINV(:,3) threshDataUP(:,4),threshDataINV(:,4)...
    threshDataUP(:,5),threshDataINV(:,5) threshDataUP(:,6),threshDataINV(:,6)]

% subplot(1,3,1)
% boxplot(threshDataUP);
% xlabel('Wavelength (cpi)');
% ylabel('Threshold (cpi)');
% title('Upright ID Task');

p1=subplot(1,2,1)
boxplot(threshDataUP);
p=fit([1:6]',median(threshDataUP)','smoothingspline'); hold on
plot(p)
xlabel('Distortion Frequency (cpi)');
ylabel('Threshold (wavelengths)');
title('Upright ID Task');
xticklabels([{'1' '2' '4' '8' '16' '32'}])
ylim([0 3])
legend('off')

% subplot(1,3,2)
% boxplot(threshDataINV);
% xlabel('Wavelength (cpi)');
% ylabel('Threshold (cpi)');
% title('Invert ID Task');

p2=subplot(1,2,2)
boxplot(threshDataINV);
p=fit([1:6]',median(threshDataINV)','smoothingspline'); hold on
plot(p)
xlabel('Distortion Frequency (cpi)');
ylabel('Threshold (wavelengths)');
title('Invert ID Task');
xticklabels([{'1' '2' '4' '8' '16' '32'}])
ylim([0 3])
legend('off')

% subplot(1,3,3)
% boxplot(newthresh);
% xlabel('Wavelength (cpi)');
% ylabel('Threshold (cpi)');
% title('Combined ID Task');
%% ANOVA1
% [~,~,stats]=anova1(threshDataUP)
% figure()
% [~,~,stats]=anova1(threshDataINV)
% c = multcompare(stats);


% figure
% boxplot([threshDataUP; threshDataINV],group)
% set(gca,'XTickLabel',{'threshDataUP','threshDataINV'})


% group = [    ones(size(threshDataUP));
%          2 * ones(size(threshDataINV))];
% figure
% boxplot([threshDataUP; threshDataINV;],group)
% set(gca,'XTickLabel',{'threshDataUP','threshDataINV'})
