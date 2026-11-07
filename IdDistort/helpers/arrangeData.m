% =========================================================================
% ARRANGEDATA
% =========================================================================
% PURPOSE:  Sort stimulus levels and responses into psychometric function format with proportion correct and confidence bounds.
% PROJECT:  General utilities
% CREATED:  2021-11-03
% UPDATED:  2021-11-03
% =========================================================================

%respIn = [0 0 1 0 1 1 1 0 1 0 1 1 0 1 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 0];
%dataIn =[0.0417 0.0525 0.0661 0.0590 0.0661 0.0624 0.0590 0.0557 0.0624 0.0607 0.0643 0.0624 0.0607 0.0643 0.0624 0.0607 0.0590 0.0573 0.0607 0.0590 0.0573 0.0557 0.0541 0.0573 0.0557 0.0541 0.0525 0.0557 0.0590 0.0624 0.0607];

function arrangedData=arrangeData(dataIn, respIn) %(dataIn: test levels, respIn: whether you were correct)
% arrangeData
% sort a stream of test levels and responses into psychometric functions
% arrangedData(:,1)= unique testing level
% arrangedData(:,2)= # trials at this level level
% arrangedData(:,3)= # correct/Yes responses at this level
% arrangedData(:,4)= proportion correct/Yes at this level
% arrangedData(:,5)= expected value after rule of succession correction (i.e. add pseudosamples).
% arrangedData(:,6)= beta distribution lower bound (based on Expected value after Rule of Succession correction)
% arrangedData(:,7)= beta distribution upper bound (based on Expected value after Rule of Succession correction)
% testing level

uniqLevels=unique(dataIn);
arrangedData=zeros(length(uniqLevels), 8); %Finds all the data that's unique
arrangedData(:,1)=uniqLevels'; %come unique, some tested more than once -- will always be dif between participants

for index=1:length(uniqLevels)
    trialsThisLevel=(dataIn==uniqLevels(index));            % trials at this level
    arrangedData(index,2)=sum(trialsThisLevel);             % total # trials at this level 
    arrangedData(index,3)=sum(trialsThisLevel.*respIn);     % total # correct at this level 
end

arrangedData(:,4)=arrangedData(:,3)./arrangedData(:,2);     % proportion correct at each level

% Beta distribution confidence limits:
% expected values:
arrangedData(:,5) = (arrangedData(:,3)+1) ./ (arrangedData(:,2)+2); %Corrects for the small sample effect: adds one to correct options, adds 2 to trials
nSuccessesE = arrangedData(:,5).*(arrangedData(:,2)+2);
nFailsE = (arrangedData(:,2)+2)-nSuccessesE;
arrangedData(:,6) = betainv(.025,nSuccessesE,nFailsE);
arrangedData(:,7) = betainv(.975,nSuccessesE,nFailsE);

arrangedData(:,8)=((arrangedData(:,4).*(1-arrangedData(:,4))./arrangedData(:,2)).^0.5)+(1./((2*arrangedData(:,2)))); % binomial standard deviation for each lest level, with correction for small sample size
% arrangedData(:,8)=(arrangedData(:,4).*(1-arrangedData(:,4)).*arrangedData(:,2)).^0.5; % binomial standard deviation for each lest level
