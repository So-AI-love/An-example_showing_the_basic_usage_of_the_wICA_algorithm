%% one An example showing the basic usage of the wICA algorithm
% Based of http://www.mat.ucm.es/~vmakarov/Supplementary/wICAexample/TestExample.html
% On Physionet EEG Motor Movement/Imagery Dataset date base(  https://archive.physionet.org/physiobank/database/eegmmidb/)
% showing the basic usage of wICA algorithm
% This code is for illustration of the method described in:  

% http://www.mat.ucm.es/~vmakarov/index.html
%

%% Reset environment
close all
clear all

%% Load test data


downloadurl='https://archive.physionet.org/atm/eegmmidb/S001/S001R01.edf/event/0/10/export/matlab/S001R01_edfm.mat';
[filepath,downloadName,ext] = fileparts(downloadurl)
path=append(pwd,'/',downloadName);

if ~exist(path, 'file')
    
    [filestr,downloadName] =urlFetch(downloadurl,pwd);
    %unzip (append(downloadName,ext));
    %cd (downloadName);
    addpath(pwd);
    savepath;
end

data_eeg=downloadName;

downloadurl='https://archive.physionet.org/atm/eegmmidb/S001/S001R01.edf/event/0/10/rdsamp/csv/pd/samples.csv'
[filepath,downloadName_cvs,ext] = fileparts(downloadurl)
path=append(pwd,'/',downloadName_cvs);

if ~exist(path, 'file')
    
    [filestr,downloadName_cvs] =urlFetch(downloadurl,pwd);
    %unzip (append(downloadName,ext));
    %cd (downloadName);
    addpath(pwd);
    savepath;
end

downloadurl='http://www.mat.ucm.es/~vmakarov/files/wICA_2.zip';
[filepath,downloadName2,ext] = fileparts(downloadurl)
path=append(pwd,'/',downloadName2);

if ~exist(path, 'dir')
    
    [filestr,downloadName3] =urlFetch(downloadurl,pwd);
    unzip (downloadName3);
    cd (downloadName2);
    addpath(pwd);
    savepath;
end


Fs = 256;  % Sampling frequency in Hz
%[Data, ChanTitels, FileName] = ReadTruScan_ascii('./Data/test1.tdt');
 load(data_eeg);
 Data =val';
 Data=Data(:,1:19);
 
t= readtable(downloadName_cvs);
ChanTitels1=t.Properties.VariableNames;

ChanTitels=ChanTitels1(2:19+1);
%%---Conventional notch filter (you may add more)
%This is an optional step (suppress 50Hz noise)

%% Conventional notch filter (you may add more)
% This is an optional step (suppress 50Hz noise) 

Fnyq  = Fs/2;
F_notch = 50; % Notch at 50 Hz
[b,a] = iirnotch(F_notch/Fnyq, F_notch/Fnyq/20); 
Data  = filtfilt(b,a, Data);

%% Conventional High Pass Filter
% This is an optional step (suppress low <4Hz frequency noise) 
F_cut = 4;
[b,a] = ellip(1, 0.5, 20, F_cut/Fnyq, 'high');
Data  = filtfilt(b,a, Data);

%% Drop starting end ending 0.5s (remove edge perturbations)

Data = Data(129:end-128,:); 

%% Remove mean values from the channels and plot raw data

Data  = detrend(Data,'constant');
% Transpose the data matrix to get (channel x time) orientation
Data = Data';                     
figure('color','w');
PlotEEG(Data, Fs, ChanTitels, 200, 'Raw data (19 channels 10-20 system)');

%% Find independent components
% Here for ICA I use fastICA algorithm (package included, for details see 
% the corresponding functions). Note: in the original paper runica from EEGLAB
% was used. You can also test other ICA algorithms at this step.
%
% Note, the use of long (in time) data sets REDUCES the quality of artifact
% suppression (for details see the abovementioned paper).
% Split long files into segments and clean them separately.

[icaEEG, A, W] = fastica(Data,'stabilization','off','verbose','off'); 

figure('color','w');
PlotEEG(icaEEG, Fs, [], [], 'Independent Components');
xlabel('Time (s)')

%% Common ICA artifact suppression method 
% Remove artifact components and rebuild signals 
%
% An input dialog will be open, where you should enter 
% the ICs (separated by coma) to be removed
% (those with artifacts)

answer  = inputdlg({'Artifact ICs'},'Components to remove',1);
ArtICs = str2num(answer{1});
disp(['Suppressed components: ' answer{1}]); 
icaEEG1 = icaEEG;
icaEEG1(ArtICs, :) = 0;          % suppress artifacts 
Data_ICA = A*icaEEG1;            % rebuild data
figure('color','w');
PlotEEG(Data_ICA, Fs, ChanTitels, 100, 'ICA cleanned EEG (Note: the graph scale is different)');

%% wICA artifact rejection 
% NOTE: For better artifact suppression, provide manually the numbers 
% of components to be processed. You can also tune the other arguments
% for your data set.
%

nICs = 1:size(icaEEG,1); % Components to be processed, e.g. [1, 4:7]
Kthr = 1.25;             % Tolerance for cleaning artifacts, try: 1, 1.15,...
ArtefThreshold = 4;      % Threshold for detection of ICs with artefacts
                         % Set lower values if you manually select ICs with 
                         % artifacts. Otherwise increase
verbose = 'on';          % print some intermediate results                         
                         
icaEEG2 = RemoveStrongArtifacts(icaEEG, nICs, Kthr, ArtefThreshold, Fs, verbose); 

figure('color','w');
PlotEEG(icaEEG2, Fs, [], [], 'wavelet filtered ICs');

Data_wICA = A*icaEEG2;
figure('color','w');
PlotEEG(Data_wICA, Fs, ChanTitels, 100, 'wICA cleanned EEG');

%% Make comparative plots
% In the first 2 subplots I plot a segment with (ocular) artifacts 
% and an artifact-free segment. 
% Note that in the artifact-free segment, good artifact suppression method 
% should conserve (not perturb) the original EEG signal.
% 3rd subplot shows another example of artifact suppression.

TimeInterval1 = [2, 6];
TimeInterval2 = [2, 2.25];
TimeInterval3 = [7.7, 8.7];

figure('color','w','position',[100 100 700 800])
subplot(3,1,1);
nT1 = round(TimeInterval1(1)*Fs); nT2 = round(TimeInterval1(2)*Fs);
plot((nT1:nT2)/Fs, Data(1,nT1:nT2),'k',(nT1:nT2)/Fs, Data_ICA(1,nT1:nT2),'b',...
    (nT1:nT2)/Fs, Data_wICA(1,nT1:nT2),'r');
xlim(TimeInterval1)
xlabel('Time (s)')
legend({'Raw EEG','ICA cleaned EEG','wICA cleaned EEG'},'Location','NorthWest');
title('Segment with artifacts (FP1)')

subplot(3,1,2);
nT1 = round(TimeInterval2(1)*Fs); nT2 = round(TimeInterval2(2)*Fs);
plot((nT1:nT2)/Fs, Data(1,nT1:nT2),'k',(nT1:nT2)/Fs, Data_ICA(1,nT1:nT2),'b',...
    (nT1:nT2)/Fs, Data_wICA(1,nT1:nT2),'r');
xlim(TimeInterval2)
title('Amplified, outside of artifacts')
xlabel('Time (s)')

subplot(3,1,3);
nT1 = round(TimeInterval3(1)*Fs); nT2 = round(TimeInterval3(2)*Fs);
plot((nT1:nT2)/Fs, Data(1,nT1:nT2),'k',(nT1:nT2)/Fs, Data_ICA(1,nT1:nT2),'b',...
    (nT1:nT2)/Fs, Data_wICA(1,nT1:nT2),'r');
xlim(TimeInterval3)
title('Segment with another artifact')
xlabel('Time (s)')
