% =========================================================================
% GAZEPOINTINIT
% =========================================================================
% PURPOSE:  Initialize and configure GazePoint eye tracker via TCP/IP connection with data stream parameters.
% PROJECT:  GazePoint demos
% CREATED:  2021-11-03
% UPDATED:  2021-11-03
% =========================================================================

function gpAPIClient = GazePointInit()
% set up parameters for GazePoint Eye tracker
    gpAPIClient = tcpip('127.0.0.1', 4242); % open new TCPIP client for this eye tracker
    set(gpAPIClient, 'InputBufferSize', 100000); % from toolbox master% set(gpAPIClient, 'InputBufferSize', 4096); % from 1
    set(gpAPIClient,'Terminator', 'CR/LF'); % character return and line feed terminator for data record
    fopen(gpAPIClient); % open client
    % specify data structures required from server each call
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_TIME" STATE="1" />'); % receive time stamp
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_COUNTER" STATE="1" />'); % receive data record timer
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_USER_DATA" STATE="1" />');  % receive custom messages input by user
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_PUPIL_LEFT" STATE="1" />'); % receive diameter of left eye pupil
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_PUPIL_RIGHT" STATE="1" />'); % receive diameter of right eye pupil
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_POG_LEFT" STATE="1" />'); % receive x y positon of left eye
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_POG_RIGHT" STATE="1" />'); % receive x y positon of right eye
    fprintf(gpAPIClient, '<SET ID="ENABLE_SEND_POG_BEST" STATE="1" />'); % receive x y positon of right eye
end

