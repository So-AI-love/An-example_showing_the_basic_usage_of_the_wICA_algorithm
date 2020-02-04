function [filestr,downloadName] = urlFetch( downloadurl,file_path,name)
% GITHUBFETCH  Download file from GitHub.
%   
%   Inputs:
%       downloadurl: url of the target file

%   Output:
%       filestr: path to the downloaded file
%
%   The downloaded file type is .zip.
%
%   Examples:
%       1)urlFetch( 'https://physionet.org/static/published-projects/slpdb/mit-bih-polysomnographic-database-1.0.0.zip')
%       % same as githubFetch('GLVis', 'glvis', 'branch', 'master')
%       2) githubFetch('matlab2tikz', 'matlab2tikz', 'branch', 'develop')
%       3) githubFetch('matlab2tikz', 'matlab2tikz', 'release', '1.1.0')
%       4) githubFetch('matlab2tikz', 'matlab2tikz', 'release')
%       % same as githubFetch('matlab2tikz', 'matlab2tikz', 'release', 'latest')

%   soheil sabzevari
%   04/03/2020



narginchk(1, 3);
website = 'https://github.com';

if nargin<2    
    [filepath,downloadName0,ext] = fileparts(downloadurl)
    downloadName=append(downloadName0,ext);
    directory_content = dir; % contains everything of the current directory
    file_path = directory_content(1).folder; % returns the path that is currently open
    

end
if nargin<3    
    [filepath,downloadName0,ext] = fileparts(downloadurl)
    downloadName=append(downloadName0,ext);


end
    cd (file_path);
    
    %{
% Check for download type
branchRequested = strcmpi(ext, 'zip');
releaseRequested = strcmpi(downloadName0, 'release');
assert(branchRequested | releaseRequested, ...
    'Type must be either ''branch'' or ''release''.');
%}
% Check if the user exists
try
    urlread(downloadurl);
catch ME
    if strcmp(ME.identifier, 'MATLAB:urlread:FileNotFound')
        error('User does not exist.');
    end
end

% Check if the repository exists for the given user
try
    urlread(downloadurl);
catch ME
    if strcmp(ME.identifier, 'MATLAB:urlread:FileNotFound')
        error('Repository does not exist.');
    end
end

% Process branch or release versions

% Download the requested branch or release

%[filepath,downloadName,ext] = fileparts(downloadurl)
%downloadName=downloadName+ext;
try
    fprintf('Download started ...\n');
    filestr = urlwrite(downloadurl,downloadName);
    fprintf('Traget %s successfully downloaded.\n', downloadName);
catch ME
    
        rethrow(ME);

end
