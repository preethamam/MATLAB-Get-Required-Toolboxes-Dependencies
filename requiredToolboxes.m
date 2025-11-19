% requiredToolboxes.m
% List MATLAB products/toolboxes required by all .m files in a folder,
% excluding files listed in ignoreFiles, and report per-file usage.
% All output written to requirements.txt (no console output).

clc; close all; clear;

%% User settings

folderPath = pwd;

ignoreFiles = {
    'scrachPaper.m'
    'requiredToolboxes.m'
};

outputFile = fullfile(folderPath, 'requirements.txt');
fid = fopen(outputFile, 'w');

if fid == -1
    error('Could not open requirements.txt for writing.');
end

%% Collect .m files

fileStruct = dir(fullfile(folderPath, '*.m'));
filesArray = {};

for k = 1:numel(fileStruct)
    fileName = fileStruct(k).name;
    if ~ismember(fileName, ignoreFiles)
        filesArray{end+1,1} = fullfile(folderPath, fileName); %#ok<SAGROW>
    end
end

if isempty(filesArray)
    fprintf(fid, 'No .m files found after applying ignore list.\nFolder: %s\n', folderPath);
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

