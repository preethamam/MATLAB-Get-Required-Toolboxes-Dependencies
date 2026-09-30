% requiredToolboxes.m
% List MATLAB products/toolboxes required by all .m files in a folder and
% its sub-folders, excluding files listed in ignoreFiles and folders listed
% in ignoreFolders, and report per-file usage.
% All output written to requirements.txt (no console output).

clc; close all; clear;

%% User settings

folderPath = 'D:\OneDrive\Education Materials\Team Work\Team SyntheticCRACK\Codebase\2022-01-22 - A graph-based (non-force)';

ignoreFiles = {
    'scrachPaper.m'
    'requiredToolboxes.m'
};

% Folders to skip (the folder, its files, and all of its sub-folders).
%   - A bare name (e.g. 'tests') skips every folder with that name at any depth.
%   - A path (e.g. 'external/old') skips that folder relative to folderPath.
%   - An absolute path skips that exact folder.
ignoreFolders = {
    '.git'
    'Archive'
    'assets'
    'MAT Files'
    'MATLAB - Crackmasks'
    'Others'
    'Python - DL Image Segmentor'
    'Results'
};

outputFile = fullfile(folderPath, 'requirements.txt');
fid = fopen(outputFile, 'w');

if fid == -1
    error('Could not open requirements.txt for writing.');
end

%% Collect .m files

fileStruct = dir(fullfile(folderPath, '**', '*.m'));
filesArray = {};

rootNorm   = normalizePath(folderPath);
ignoreNorm = cellfun(@normalizePath, ignoreFolders, 'UniformOutput', false);

for k = 1:numel(fileStruct)
    fileName = fileStruct(k).name;
    if fileStruct(k).isdir || ismember(fileName, ignoreFiles)
        continue;
    end
    if isInIgnoredFolder(fileStruct(k).folder, rootNorm, ignoreNorm)
        continue;
    end
    filesArray{end+1,1} = fullfile(fileStruct(k).folder, fileName); %#ok<SAGROW>
end

if isempty(filesArray)
    fprintf(fid, 'No .m files found after applying ignore lists.\nFolder: %s\n', folderPath);
    fclose(fid);
    return;
end

%% Analyze toolbox usage (per file + global)

toolboxMap = containers.Map('KeyType','char','ValueType','any');

perFileToolboxes = struct( ...
    'fileName',   {}, ...
    'toolboxes',  {} );

for f = 1:numel(filesArray)

    thisFileFull = filesArray{f};
    [~, fileNameOnly, fileExt] = fileparts(thisFileFull);
    fileLabel = [fileNameOnly fileExt];

    try
        [~, pListFile] = matlab.codetools.requiredFilesAndProducts({thisFileFull});
    catch
        pListFile = [];
    end

    perFileToolboxes(f).fileName  = fileLabel;
    perFileToolboxes(f).toolboxes = pListFile;

    for i = 1:numel(pListFile)
        productName    = pListFile(i).Name;
        productVersion = pListFile(i).Version;
        productNumber  = pListFile(i).ProductNumber;

        if ~isKey(toolboxMap, productName)
            info.Name          = productName;
            info.Version       = productVersion;
            info.ProductNumber = productNumber;
            info.Files         = {fileLabel};
            toolboxMap(productName) = info;
        else
            info = toolboxMap(productName);
            if ~ismember(fileLabel, info.Files)
                info.Files{end+1} = fileLabel;
            end
            toolboxMap(productName) = info;
        end
    end
end

%% Global toolbox list

toolboxNames = keys(toolboxMap);
[~, sortIdx] = sort(lower(toolboxNames));
toolboxNames = toolboxNames(sortIdx);

fprintf(fid, 'Overall/global required MATLAB products/toolboxes:\n');

if isempty(toolboxNames)
    fprintf(fid, '  (Base MATLAB only.)\n');
else
    for k = 1:numel(toolboxNames)
        info = toolboxMap(toolboxNames{k});
        fprintf(fid, '  %2d) %s\n', k, info.Name);
        fprintf(fid, '      Version       : %s\n', info.Version);
        fprintf(fid, '      ProductNumber : %s\n', info.ProductNumber);
    end
end

%% Toolbox usage summary

fprintf(fid, '\nToolbox usage summary:\n');
for k = 1:numel(toolboxNames)
    info = toolboxMap(toolboxNames{k});
    fprintf(fid, '  - %s : used in %d file(s)\n', info.Name, numel(info.Files));

    % --- Added lines: list filenames ---
    for ff = 1:numel(info.Files)
        fprintf(fid, '        • %s\n', info.Files{ff});
    end
    % -----------------------------------
end


%% Per-file toolbox list

fprintf(fid, '\nPer-file required MATLAB products/toolboxes:\n');

for f = 1:numel(perFileToolboxes)
    fileLabel = perFileToolboxes(f).fileName;
    pListFile = perFileToolboxes(f).toolboxes;

    fprintf(fid, '\n  %s\n', fileLabel);

    if isempty(pListFile)
        fprintf(fid, '    (Base MATLAB only)\n');
    else
        for i = 1:numel(pListFile)
            fprintf(fid, '    %2d) %s\n', i, pListFile(i).Name);
            fprintf(fid, '        Version       : %s\n', pListFile(i).Version);
            fprintf(fid, '        ProductNumber : %s\n', pListFile(i).ProductNumber);
        end
    end
end

%% Files analyzed

fprintf(fid, '\nFiles analyzed:\n');
for i = 1:numel(filesArray)
    [~, fileNameOnly, fileExt] = fileparts(filesArray{i});
    fprintf(fid, '  - %s%s\n', fileNameOnly, fileExt);
end
fclose(fid);


%% Final console output
disp('Requirements file is created.');

%% Local functions

function p = normalizePath(p)
% Use '/' separators, drop trailing separators, and fold case on Windows.
p = strrep(char(p), '\', '/');
while numel(p) > 1 && p(end) == '/'
    p(end) = [];
end
if ispc
    p = lower(p);
end
end

function tf = isInIgnoredFolder(folder, rootNorm, ignoreNorm)
% True if folder is, or lies inside, any folder listed in ignoreFolders.
folderNorm = normalizePath(folder);
if strncmp(folderNorm, [rootNorm '/'], numel(rootNorm) + 1)
    relPath = folderNorm(numel(rootNorm) + 2:end);
else
    relPath = '';   % file sits directly in folderPath
end
segments = strsplit(relPath, '/');

tf = false;
for i = 1:numel(ignoreNorm)
    entry = ignoreNorm{i};
    if isempty(entry)
        continue;
    end
    if contains(entry, '/')
        % Relative (to folderPath) or absolute folder path
        tf = pathStartsWith(relPath, entry) || pathStartsWith(folderNorm, entry);
    else
        % Bare folder name: match at any depth
        tf = any(strcmp(segments, entry));
    end
    if tf
        return;
    end
end
end

function tf = pathStartsWith(p, prefix)
tf = strcmp(p, prefix) || strncmp(p, [prefix '/'], numel(prefix) + 1);
end

