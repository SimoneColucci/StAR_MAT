function checkInputAnalyze(imgData,technique)

disp('Checking input parameters...')

%% Check required inputs

if ~isfield(imgData,'inputDir') || isempty(imgData.inputDir)
    error("Missing Parameter: imgData.inputDir is required.")
end
if ~isfield(imgData,'outputDir') || isempty(imgData.outputDir)
    error("Missing Parameter: imgData.outputDir is required.")
end
if ~isfield(imgData,'inputFile') || isempty(imgData.inputFile)
    error("Missing Parameter: imgData.inputFile is required.")
end
if ~isfield(imgData,'px2m') || isempty(imgData.px2m)
    error("Missing Parameter: imgData.px2m is required.")
end
if ~isfield(technique,'range')
    error('Missing Parameter: technique.range is required')
end

%% Check type

if ~ischar(imgData.inputDir) || ~ischar(imgData.outputDir)
    error('Type Error: The fields imgData.inputDir and imgData.outputDir must be character vectors representing a valid file path');
end
isAllChar = cellfun(@ischar, imgData.inputFile);
if ~all(isAllChar)
    error('Type Error: The field imgData.inputFile must be a character vector representing a valid file path');
end
if ~isnumeric(imgData.px2m)
    error('Type Error: The field imgData.px2m must be a scalar or an array or numbers');
end

%% Check file existence

for i = 1:numel(imgData.inputFile)
    imgDatai.inputFile = imgData.inputFile{i};
    imagePath = fullfile(imgData.inputDir, imgDatai.inputFile);
    if ~exist(imagePath, 'file'); error('Input image file "%s" not found.', imagePath); end
end

%%

disp('Input parameters ok!')