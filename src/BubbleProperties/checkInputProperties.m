function checkInputProperties(measureData,sample,method)

disp('Checking input parameters...')

%% Check required inputs

if ~isfield(measureData,'inputDir') || isempty(measureData.inputDir)
    error("Missing Parameter: measureData.inputDir is required.")
end
if ~isfield(measureData,'outputDir') || isempty(measureData.outputDir)
    error("Missing Parameter: measureData.outputDir is required.")
end
if ~isfield(measureData,'inputFile') || isempty(measureData.inputFile)
    error("Missing Parameter: measureData.inputFile is required.")
end
if ~isfield(measureData,'type') || isempty(measureData.type)
    error("Missing Parameter: measureData.type is required ('2D', '3D','3Dstereo').")
end
if ~isfield(sample,'px2m') || isempty(sample.px2m)
    error('Missing Parameter: sample.px2m is required.')
end
if ~isfield(sample,'cropArea') || isempty(sample.cropArea)
    error('Missing Parameter: sample.cropArea is required.')
end
if ~isfield(method,'minsearch') || isempty(method.minsearch)
    error("Missing Parameter: method.minsearch is required ('fmincon, 'simplex).")
end

%% Check type

if ~ischar(measureData.inputDir) || ~ischar(measureData.outputDir) 
    error('Type Error: The fields measureData.inputDir, measureData.outputDir must be character vectors representing a valid file path');
end
flatFiles = [measureData.inputFile{:}];
isAllChar = cellfun(@ischar, flatFiles);
if ~all(isAllChar) 
    error('Type Error: All entries in measureData.inputFile must be character vectors.');
end
flatFiles = [sample.px2m{:}];
isAllNum = cellfun(@isnumeric, flatFiles);
if ~all(isAllNum) 
    error('Type Error: The field sample.px2m must be a number');
end
flatFiles = [sample.cropArea{:}];
isAllNum = cellfun(@isnumeric, flatFiles);
if ~all(isAllNum) 
    error('Type Error: The field sample.cropArea must be a number');
end
if ~strcmp(method.minsearch,'fmincon') && ~strcmp(method.minsearch,'simplex')
    error(sprintf('Invalid method.minsearch provided.\nAvailable options:\n - fmincon\n - simplex'));
end
checkArray = [measureData.type{:}];
if ~all(strcmp(checkArray, '2D') | strcmp(checkArray, '3D') | strcmp(checkArray, '3Dstereo'))
     error("Invalid measureData.type provided. Available options:\n - 2D\n - 3D\n - 3Dstereo'");
end
for i = 1:numel(measureData.inputFile)
    for j = 1:numel(measureData.inputFile{i})
        filenameij = fullfile(measureData.inputDir,measureData.inputFile{i}{j});
        if strcmp(measureData.type{i}{j},'3D') && (~isfield(sample,'D') || isempty(sample.D))
            error('sample.D not provided for sample %s', filenameij);
        end
    end
end

%% Check dimension

% 1. Define the variables and their display names for error reporting
varsToCheck = {measureData.type, sample.px2m, sample.cropArea};
varNames = {'measureData.type', 'sample.px2m', 'sample.cropArea'};

% 2. Establish the reference structure from inputFile
% baseStructure will be a vector containing the number of elements per group
% e.g., if inputFile is {{'A','B'}, {'C'}}, baseStructure becomes [2, 1]
baseStructure = cellfun(@numel, measureData.inputFile);
numGroups = numel(baseStructure);

% 3. Iterate through each variable to validate
for v = 1:numel(varsToCheck)
    currentVar = varsToCheck{v};
    currentName = varNames{v};
    
    % Check Level 1: Number of main groups
    if numel(currentVar) ~= numGroups
        error('Dimension Mismatch: Variable "%s" has %d groups, but "inputFile" has %d.', ...
            currentName, numel(currentVar), numGroups);
    end
    
    % Check Level 2: Number of elements within each specific group (i)
    for i = 1:numGroups
        expectedLen = baseStructure(i);
        actualLen = numel(currentVar{i});
        
        if actualLen ~= expectedLen
            error(['Consistency Error in "%s":\n' ...
                   'At Group Index {%d}, %d elements were found,\n' ...
                   'but "measureData.inputFile" expects %d elements.'], ...
                   currentName, i, actualLen, expectedLen);
        end
    end
end

%% Check file existence

for i = 1:numel(measureData.inputFile)
    for j = 1:numel(measureData.inputFile{i})
        filei = measureData.inputFile{i}{j};
        imagePath = fullfile(measureData.inputDir, filei);
        if ~exist(imagePath, 'file'); error('Input measurements file "%s" not found.', imagePath); end
    end
end


%%

disp('Input parameters ok!')

