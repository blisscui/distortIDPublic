% glassCohThreshNAFC
% Program to measure the signal:noise ratio for detection of glass patterns
% N dots randomly positioned on screen
% Target element pairs horizontal or vertical
% Noise element pairs random orienttions
% Staircase adjusts the signal:noise ratio for 79% orientation identification
% 2019  pjb  adapted it from Psych Toolbox demo

clear all;

whichScreen=max(Screen('Screens')); % use highest display # for stimuli
meanLum=127;
%% read in testing parameters:
prompt = {'subject initials:', 'Image Height (deg):','Face Orientation (deg)','# AFC','Inter-Stimulus Gap (deg)','# Trials','Distortion Frequency (c/image)','Threshold Guess (%):','Screen Width (cm)','Viewing Distance (cm)', 'Eye tracking? 0=No, 1=Yes'};
dlg_title = 'Face Distort Threshold'; %AFC: Alternative Forced Choice
num_lines = 1;
def = {'XX', '15', '0', '4','0.5', '40','1 2 4 8 16 32', '0.5 0.5 0.5 0.5 0.5 0.5', '60', '60', '1'};
answer = inputdlg(prompt,dlg_title,num_lines,def); % read in parameters from GUI: Graphical User Interface
sName=char(answer(1,1));
imHeighthDeg=str2num(char(answer(2,1)));
imOri=str2num(char(answer(3,1)));
nAFC=str2num(char(answer(4,1)));
interWinGapDeg=str2num(char(answer(5,1)));
nTrialsPerCond=str2num(char(answer(6,1)));
distortFreq=str2num(char(answer(7,1)));
thresholdGuess=str2num(char(answer(8,1))); %How big must the distortion be for us to see it? Note: 25% correct from randomly pressing
scrnWidthCm=str2num(char(answer(9,1))); % screen width (cm)
viewDistCm=str2num(char(answer(10,1))); % observer's distance from screen
eyeTracking=str2num(char(answer(11,1))); % eye tracking 0=No, 1=Yes

rng('default'); %Random Number Generator: controls the seed/starting point for the value; 'default' resets it to original value MATLAB starts with

gammaVals=[2 2 2];

try
    Screen('Preference','SkipSyncTests', 1);  % hack for PC timing
    PsychImaging('PrepareConfiguration');
    [windowPtr, winRect]=PsychImaging('OpenWindow', whichScreen, meanLum);% , [0 0 2800 1800]); %meanLum is gray; 2000x2000 pixels screen, if left empty will be full screen
    Screen('BlendFunction', windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % GL_SRC_ALPHA + GL_ONE_MINUS_SRC_ALPHA
    
    frameRate=Screen('FrameRate', windowPtr);          % screen timing parameters
    
    scrnWidthDeg=2*atand((0.5*scrnWidthCm)/viewDistCm); % convert screen width to degrees visual angle
    scrnWidthPix=winRect(3)-winRect(1); % width of screen in pixels
    scrnHeightPix=winRect(4)-winRect(2); % width of screen in pixels
    screenCenter(1)=winRect(1)+scrnWidthPix/2;
    screenCenter(2)=winRect(2)+scrnHeightPix/2;
    pixPerDeg=scrnWidthPix/scrnWidthDeg; % # pixels per degree
    imHeightPix=ceil(imHeighthDeg*pixPerDeg);
    interWinGapPix=ceil(interWinGapDeg*pixPerDeg);
    
    %     pathToImageFolders='C:\Users\pbex\Google Drive\IASLab Set_FOR DISTRIBUTION\IASLab Face Set 400X600 by identity\';
    %C:\Users\bexlab\Dropbox\Bliss Cui\myExperiments\faceDistortion
    % pathToImageFolders='C:\Users\bliss\Documents\myExperiments\\IASLab Set_FOR DISTRIBUTION\IASLab Face Set 400X600 by identity\';
   pathToImageFolders='C:\Users\bexlab\Dropbox\Bliss Cui\myExperiments\IASLab Set_FOR DISTRIBUTION\IASLab Face Set 400X600 by identity\';
        
    sIDList = dir(pathToImageFolders); % list of folders for each subject
    sIDList = sIDList([sIDList.isdir]);  % select only the directories
    sIDList = sIDList(~ismember({sIDList.name}, {'.', '..'}));  %remove directories . and ..
    nUniqueIds=length(sIDList); % how many unique identities in the folder
    srcImSize=[600 400 3];
    imWidthPix=imHeightPix*(srcImSize(2)/srcImSize(1));
    
    [srcX,srcY]=meshgrid(1:srcImSize(2),1:srcImSize(1)); % pixel co-ordinates of source image
    filtImSize=max(srcImSize);
    
    maskWin=meanLum*ones([srcImSize(1) srcImSize(2) 2]);
    alphaLayer=Gaussian2D([0.65*srcImSize(1)/2 0.65*srcImSize(2)/2], [srcImSize(1)/2-20 srcImSize(2)/2], [srcImSize(1) srcImSize(2)]);
    alphaLayer=double(alphaLayer<0.61); % clip at 1 stdev
    alphaLayer=imgaussfilt(alphaLayer,4); % blur target image by staircase selected level
    maskWin(:,:,2)=round(255*alphaLayer);
    masktex=Screen('MakeTexture', windowPtr, uint8(maskWin));
    alphaLayer=uint8((1-alphaLayer)>0); % change to 0 or 1 %Only measures colors from within the hole
    
    nConds=length(distortFreq); % # interleaved distortion frequencies      %6 conditions, 6 filters to make 6 mirrors
    mySFFilter=zeros(nConds,filtImSize,filtImSize);
    
    for trialno=1:nTrialsPerCond
        eyeTrackRecord(trialno)= struct('tStamp',[],'osXPos',[], 'osYPos',[], 'odXPos',[], 'odYPos',[],'ouXPos',[], 'ouYPos',[],'osPD',[], 'odPD',[],  'isBlink',[]);
    end
    
    for condNo=1:nConds
        trialRecord(condNo) = struct('distortFreq',distortFreq(condNo),'distortAmp',nan(1,nTrialsPerCond),'distortLambda',imHeightPix/distortFreq(condNo),'trialSeed',nan(1,nTrialsPerCond),'trialCorrect',nan(1,nTrialsPerCond), 'obsResponse',nan(1,nTrialsPerCond), 'targLoc',nan(1,nTrialsPerCond), 'responseLatency', nan(1,nTrialsPerCond),'trialNo',1, 'etData', eyeTrackRecord); % start empty array
        mySFFilter(condNo,:,:)=makeFilter(4, distortFreq(condNo), 0.5, 1, filtImSize); % create band-pass filter for distortion noise
    end
    stepSize=0.1; %Changing the staircassing
    
    if eyeTracking % if eye tracking, set up gazePoint
        gpAPIClient=GazePointInit(); % set up gazePoint
    end
    
    Screen('TextSize',windowPtr,16);                               % put some instructions on screen
    Screen('TextFont',windowPtr,'Arial');
    textToObserver=sprintf('Screen Parameters %d by %d pixels at %3.2f Hz. Click on the pattern. Hit any mouse button to start', winRect(3)-winRect(1),winRect(4)-winRect(2), frameRate); %EDIT THIS MESSAGE
    Screen('DrawText', windowPtr, textToObserver, 100, 100, 0, meanLum);
    Screen(windowPtr, 'Flip');
    
    nTargs=zeros(1, nAFC); % nAFC, first is # signal face
    nCols=ceil(sqrt(nAFC)); % # stimulus columns
    nRows=ceil(nAFC/nCols); % # stimulus rows
    [xFactor, yFactor]=meshgrid((1:nCols)-nCols/2-0.5,(1:nRows)-nRows/2-0.5); % relative distance from center of screen in multiples of stim size %Calculates factor by which you move the pic to the left or right
    onScreenRectBase=[0 0 imHeightPix*(srcImSize(2)/srcImSize(1)) imHeightPix];
    xStimCenter=screenCenter(1)+xFactor*(imWidthPix+interWinGapPix); %Pixel center
    yStimCenter=screenCenter(2)+yFactor*(imHeightPix+interWinGapPix); %Gap between pictures
    onScreenRect=zeros(nAFC, 4);
    for imNum=1:nAFC
        onScreenRect(imNum,:)=CenterRectOnPoint(onScreenRectBase, xStimCenter(imNum), yStimCenter(imNum)); %Create Coordinate
    end
    targRect=CenterRectOnPoint(onScreenRectBase, winRect(1)+imWidthPix, screenCenter(2));
    
    ShowCursor('Arrow');
    [mx,my,buttons] = GetMouse; % wait for mouse button release before starting trial [left, middle, right]
    while any(buttons) % if already down, wait for release
        [mx,my,buttons] = GetMouse(windowPtr);
    end
    while ~any(buttons) % wait for new press
        [mx,my,buttons] = GetMouse(windowPtr);
    end
    
    
    %% run experiment: 40 trials for each condition (6)=240 trials
    for trialCount=1:nTrialsPerCond*nConds % work through all trials for all conditions
        
        condNo=Randi(nConds); % pick a condition at random
        while trialRecord(condNo).trialNo>nTrialsPerCond % if required # trials completed for this this level and condition, keep picking %Pick one at random, some will be finished before others: keeps track of distortion freq and how many trials you've done
            condNo=Randi(nConds); % pick another condition at random
        end
        
        if trialRecord(condNo).trialNo==1 % 1st trial - use threshold guess %Staircassing
            trialRecord(condNo).distortAmp(trialRecord(condNo).trialNo)=thresholdGuess(condNo); %keeps increasing, and function helps keep control of everything. First trial is experimenter's guess
        else % change distortion depending on whether lat trial was correct or incorrect
            if trialRecord(condNo).trialCorrect(trialRecord(condNo).trialNo-1)==0 % last trial was incorrect
                trialRecord(condNo).distortAmp(trialRecord(condNo).trialNo)=min([2 trialRecord(condNo).distortAmp(trialRecord(condNo).trialNo-1)/10.^stepSize]); % decrease distortion amplitude by log step
            else
                trialRecord(condNo).distortAmp(trialRecord(condNo).trialNo)=max([0 trialRecord(condNo).distortAmp(trialRecord(condNo).trialNo-1)*10.^(stepSize/3)]); % increase distortion amplitude by 1/3 log step
            end
        end
        
        trialSeed=round(sum(100*clock)); % use current time to generate new seed number for random number generation so that all trial parameters can be reproduced if necessary
        rng(trialSeed); % seed the random number generator
        trialRecord(condNo).trialSeed(trialRecord(condNo).trialNo)=trialSeed; % save seed
        
        distortAmpPix=trialRecord(condNo).distortLambda*trialRecord(condNo).distortAmp(trialRecord(condNo).trialNo); %Converts proportions into wavelengths
        
        %% create faces: 50 unique faces, each has 20 dif poses/emotions
        idList=Shuffle(1:nUniqueIds); % random sequence of identities, first is target ID, next 3 are distracter IDs
        averageIm=zeros(srcImSize); % clear average image
        
        for faceNum=1:nAFC % grab 4 different faces
            myFaceFolder=[pathToImageFolders sIDList(idList(faceNum)).name '\']; % folder for each face
            faceImListCalm = dir(fullfile(myFaceFolder,'*calm*st.jpg')); % pull out all calm images with straight ahead gaze
            faceImListNeut = dir(fullfile(myFaceFolder,'*neut*st.jpg')); % pull out all neutral images with straight ahead gaze
            calmTable = struct2table(faceImListCalm); % convert eligible faces to table
            neutTable = struct2table(faceImListNeut);
            faceImList=table2struct([calmTable; neutTable]); % concatenate tables and convert back to struct
            
            nUniqueIms=length(faceImList); % how many unique calm and neutral faces in the folder
            imList=Shuffle(1:nUniqueIms); % random sequence of faces
            
            myFace(faceNum).imName=[myFaceFolder faceImList(imList(1)).name]; % name of first image file
            myFace(faceNum).im=imread(myFace(faceNum).imName); % read this image file
            
            if ~isequal(size(myFace(faceNum).im), srcImSize)
                faceIm2=zeros(srcImSize);
                for rgbIndex=1:3
                    faceIm2(:,:,rgbIndex)=imresize(targFaceIm(:,:,rgbIndex), [srcImSize(1) srcImSize(2)]);
                end
                myFace(faceNum).im=uint8(faceIm2);
            end
            
            averageIm=averageIm+double(myFace(faceNum).im); % add each image to average
            if faceNum==1 % target face
                if length(faceImList)<2 % not enough images for this face
                    targFaceImName=[myFaceFolder faceImList(imList(1)).name]; % use same image of target face twice
                else
                    targFaceImName=[myFaceFolder faceImList(imList(2)).name]; % pick a different image of the same person fromt this folder
                end
                targFaceIm=imread(targFaceImName); % read this image file
                if ~isequal(size(targFaceIm), srcImSize)
                    faceIm2=zeros(srcImSize);
                    for rgbIndex=1:3
                        faceIm2=imresize(targFaceIm(:,:,rgbIndex), [srcImSize(1) srcImSize(2)]); %Force images to all be the same size
                    end
                    targFaceIm=faceIm2;
                end
            end
        end
        
        averageIm=uint8(averageIm/nAFC); % compute average image for non target faces
        averageIm=rgb2ycbcr(averageIm); % compute average yuv image of non target faces
        %         aveLumIm=averageIm(:,:,1); % luminance of average face
        aveLumIm=averageIm(:,:,1).*alphaLayer; % luminance of average face within window
        [~, aveLumOrder]=sort(aveLumIm(:)); % ascending ordered list of all pixels in each image
        
        targFaceIm=rgb2ycbcr(targFaceIm); % convert target face to yuv
        %         yuvLumIm=targFaceIm(:,:,1); % luminance of targert face %Can comment these steps out of I want to keep target image pixels the same luminance chrominance
        yuvLumIm=targFaceIm(:,:,1).*alphaLayer; % luminance of targert face
        [~, yuvLumOrder]=sort(yuvLumIm(:)); % ascending ordered list of all pixels in target image within window
        yuvLumIm(yuvLumOrder)=aveLumIm(aveLumOrder); % reassign the ascending ordered pixels from target face with the ascending ordered pixels from image 1
        targFaceIm(:,:,1)=reshape(yuvLumIm,[srcImSize(1) srcImSize(2)]); % convert back to original dimensions
        targFaceIm(:,:,2:3)=averageIm(:,:,2:3); % insert average color into target face
        targFaceIm=ycbcr2rgb(targFaceIm); % convert back to RGB
        imTex=Screen('MakeTexture', windowPtr,targFaceIm); % convert yuv image into texture
        Screen('DrawTexture', windowPtr, imTex, [], targRect, imOri); % put target faces on screen %ADDED THIS TO MAKE TARGET FACE INVERTED
        Screen('DrawTexture', windowPtr, masktex, [], targRect, imOri); % put response faces on screen
        Screen('Close', imTex);
        targPos=Shuffle(1:nAFC); % target ori random sample from list provided (degrees) %Positions 1,2,3,4 but want to randomize where the target face is
        trialRecord(condNo).targLoc(trialRecord(condNo).trialNo)=targPos(1); % note location of target
        
        for faceNum=1:nAFC % work through N different faces
            yuvIm=rgb2ycbcr(myFace(faceNum).im); % compute yuv of face image
            %             yuvLumIm=yuvIm(:,:,1); % luminance of this image
            yuvLumIm=yuvIm(:,:,1).*alphaLayer; % luminance of this image within window
            [~, yuvLumOrder]=sort(yuvLumIm(:)); % ascending  ordered list of all pixels in each image
            yuvLumIm(yuvLumOrder)=aveLumIm(aveLumOrder); % reassign the ascending ordered pixels from image 2 with the ascending ordered pixels from image 1
            yuvIm(:,:,1)=reshape(yuvLumIm,[srcImSize(1) srcImSize(2)]); % convert back to original dimensions
            yuvIm(:,:,2:3)=averageIm(:,:,2:3); % insert average color into color planes
            yuvIm=ycbcr2rgb(yuvIm); % convert back to RGB
            % add distortion
            xShift=real(ifft2(fft2(rand(filtImSize)).*squeeze(mySFFilter(condNo,:,:)))); % create random horizontal shifts at distortion frequency
            xShift=xShift(:,1:400); %We must work in square images, we make a 600x600 but only use the first 400
            xShift=xShift-mean(xShift(:)); % zero mean
            xShift=xShift/max(abs(xShift(:))); %scale noise to be from -1 to +1
            
            yShift=real(ifft2(fft2(rand(filtImSize)).*squeeze(mySFFilter(condNo,:,:)))); % create random vertical shifts at distortion frequency
            yShift=yShift(:,1:400);
            yShift=yShift-mean(yShift(:)); % zero mean
            yShift=yShift/max(abs(yShift(:))); % -1 to +1
            
            destX=1+(mod(srcX+xShift*distortAmpPix/2,srcImSize(2))); % new wrapped X positions %Mod shifts pixel at the edge of a picture to the other side
            destY=1+(mod(srcY+yShift*distortAmpPix/2,srcImSize(1))); % new wrapped Y positions
            
            distortIm=double(myFace(targPos(faceNum)).im);
            for rgbIndex=1:3
                distortIm(:,:,rgbIndex)=interp2(srcX, srcY, double(yuvIm(:,:,rgbIndex)), destX, destY, 'nearest'); % remap the source image onto detination pixels
            end
            imTex=Screen('MakeTexture', windowPtr,distortIm); % convert yuv image into texture
            Screen('DrawTexture', windowPtr, imTex, [], onScreenRect(targPos(faceNum),:),imOri); % put response faces on screen %4Images and a mask
            Screen('DrawTexture', windowPtr, masktex, [], onScreenRect(targPos(faceNum),:),imOri); % put mask on top of faces on screen
            Screen('Close', imTex);
        end
        
        SetMouse(screenCenter(1),screenCenter(2),windowPtr ); % move cursor to screen center to reduce response bias %NEW ADDITION
        
        if eyeTracking % if eye tracking, set up gazePoint
            flushinput(gpAPIClient); % flush eye tracker buffer
            fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_DATA" STATE="1" />'); % start streaming GazePoint data
        end
        
        Screen('Flip', windowPtr);
        onsetTime = GetSecs; % note time at start of trial
        ShowCursor('Arrow');
        [mx,my,buttons] = GetMouse(windowPtr); % wait for mouse button release before processing response
        while any(buttons) % if already down, wait for release
            [mx,my,buttons] = GetMouse(windowPtr);
        end
        while ~any(buttons) % wait for new press
            [mx,my,buttons] = GetMouse(windowPtr);
        end
        
        if eyeTracking % if eye tracking, set up gazePoint
            fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_DATA" STATE="0" />'); % stop streaming GazePoint data
            while  gpAPIClient.BytesAvailable > 0  % Scan data from buffer until all data removed
                dataReceived = fscanf(gpAPIClient); % read data from buffer
                split = strsplit(dataReceived,'"');% parse xml data format
                if regexp(split{1},'<REC','once') % if there is a new data record
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).tStamp=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).tStamp str2double(split{4})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).osXPos=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).osXPos str2double(split{6})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).osYPos=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).osYPos str2double(split{8})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).odXPos=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).odXPos str2double(split{12})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).odYPos=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).odYPos str2double(split{14})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).ouXPos=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).ouXPos str2double(split{18})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).ouYPos=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).ouYPos str2double(split{20})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).osPD=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).osPD str2double(split{30})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).odPD=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).odPD str2double(split{40})];
                    trialRecord(condNo).etData(trialRecord(condNo).trialNo).isBlink=[trialRecord(condNo).etData(trialRecord(condNo).trialNo).isBlink str2double(split{44})];
                end
            end
        end
        
        trialRecord(condNo).responseLatency(trialRecord(condNo).trialNo)= GetSecs-onsetTime; % note time at end of trial minus time at start of trial
        
        mouseDistFromEachBox=sqrt((mx-xStimCenter).^2+(my-yStimCenter).^2); %Records click closest to one of the 4 boxes
        [~,respNum]=min(mouseDistFromEachBox(:));
        trialRecord(condNo).obsResponse(trialRecord(condNo).trialNo)=respNum;
        
        if buttons(2); break                                                 % save data and quit
        elseif respNum== targPos(1) %1=correct, 0=incorrect
            trialRecord(condNo).trialCorrect(trialRecord(condNo).trialNo)=1;
            fixCol=[0 255 0];                                                   % green box feedback
            Beeper('high');
        else
            trialRecord(condNo).trialCorrect(trialRecord(condNo).trialNo)=0;
            fixCol=[255 0 0];                                                   % red box feedback
            Beeper('low');
        end
        trialRecord(condNo).trialNo=trialRecord(condNo).trialNo+1;
        
    end % end while trials loop
    
    if eyeTracking % if eye tracking, set up gazePoint
        fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_DATA" STATE="0" />'); % stop streaming GazePoint data
        fclose(gpAPIClient); % close client
        delete(gpAPIClient); % delete client
        clear gpAPIClient % clear
    end
    
    Screen('CloseAll');
    ShowCursor;
    n=1;
    if imOri==0 %name the result file with either Upright or Inverted condition
        facecondition='_UP_';
    elseif imOri==180
        facecondition='_INV_';
    end
    testSName=[sName facecondition];    % modify sName if subject already exists %Increases file number to avoid overwriting
    while exist([testSName,'FaceDistort.mat'],'file') ~= 0
        n=n+1;
        testSName=[sName,num2str(n)];
    end
    dataFile=sprintf('%sFaceDistort.mat', testSName);       % file path to Mat files
    save(dataFile,'trialRecord','imHeighthDeg','imOri','nAFC','interWinGapDeg','nTrialsPerCond','distortFreq','thresholdGuess','gammaVals','frameRate','winRect','scrnWidthCm','viewDistCm'); %Saves all data if fit fails, trial record has all the data, add the fit
    
    threshVal=zeros(1,nConds);
    for condNo=1:nConds %will send me function for this
        subplot(1, nConds,condNo ); %1x1 in position 1
        trialRecord(condNo).fitObj=fitPFuncnAFC_BC(trialRecord(condNo).distortAmp, trialRecord(condNo).trialCorrect, nAFC, 1 , -1); %Steps into the fitPFuNCAFC: reads in raw data
        threshVal(condNo)=trialRecord(condNo).fitObj.thresh;
    end
    figure();
    semilogx(distortFreq,threshVal);
    xlabel('Distortion Frequency (c/image');
    ylabel('Threshold Amplitude (nLambda)');
    
    save(dataFile,'trialRecord','imHeighthDeg','imOri','nAFC','interWinGapDeg','nTrialsPerCond','distortFreq','thresholdGuess','gammaVals','frameRate','winRect','scrnWidthCm','viewDistCm');
    
catch ME
    Screen('CloseAll');
    ShowCursor;
    testSName=sName;    % modify sName if subject already exists
    n=1;
    while exist([testSName,'FaceDistortFailedRun.mat'],'file') ~= 0
        n=n+1;
        testSName=[sName,num2str(n)];
    end
    dataFile=sprintf('%sFaceDistortFailedRun.mat', testSName);       % file path to Mat files
    save(dataFile,'trialRecord','imHeighthDeg','imOri','nAFC','interWinGapDeg','nTrialsPerCond','distortFreq','thresholdGuess','gammaVals','frameRate','winRect','scrnWidthCm','viewDistCm');
    rethrow(ME);
end

