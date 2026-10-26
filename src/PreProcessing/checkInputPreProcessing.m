function checkInputPreProcessing(preProcess,imgData)

disp('Checking input parameters...')
%% Check required inputs

if ~isfield(imgData,'inputDir') || isempty(imgData.inputDir)
    error("Missing Parameter: imgData.inputDir is required.")
end
if ~isfield(imgData,'outputDir') || isempty(imgData.outputDir)
    error("Missing Parameter: imgData.outputDir is required.")
end
if ~isfield(preProcess, 'crop') || isempty(preProcess.crop)
    error("Missing Parameter: preProcess.crop is required.")
end
if ~isfield(preProcess, 'calibration') || isempty(preProcess.calibration)
    error("Missing Parameter: preProcess.calibration is required.")
end
if ~isfield(preProcess, 'intensityRange') || isempty(preProcess.intensityRange)
    error("Missing Parameter: preProcess.intensityRange is required.")
end
if preProcess.calibration && ...
        ( ~isfield(imgData,'calibration') || ...
          ~isfield(imgData.calibration,'inputFile') || ...
          isempty((imgData.calibration.inputFile)) )
    error('Missing Parameter: imgData.calibration.inputFile is required when preProcess.calibration is true.')
end
if preProcess.crop && ...
        ( ~isfield(imgData,'inputFile') || ...
          isempty((imgData.inputFile)) )
    error('Missing Parameter: imgData.inputFile is required when preProcess.crop is true.')
end
if preProcess.intensityRange && ...
        ( ~isfield(imgData,'inputFile') || ...
          isempty((imgData.inputFile)) )
    error('Missing Parameter: imgData.inputFile is required when preProcess.intensityRange is true.')
end

%% Check type

isAllChar = cellfun(@ischar, imgData.inputDir);
if ~all(isAllChar) || ~ischar(imgData.outputDir)
    error('Type Error: The fields imgData.inputDir and imgData.outputDir must be character vectors representing a valid file path');
end
if ~islogical(preProcess.crop) || ~islogical(preProcess.calibration) || ~islogical(preProcess.intensityRange) 
    error('Type Error: The fields preProcess.crop, preProcess.calibration, and preProcess.intensityRange must be of logical type (true/false).');
end
if preProcess.calibration
    isAllChar = cellfun(@ischar, imgData.calibration.inputFile);
    if ~all(isAllChar)
        error('Type Error: The fields imgData.calibration.inputFile must be a character vector representing a valid file path');
    end
end
if preProcess.crop 
    isAllChar = cellfun(@ischar, imgData.inputFile);
    if ~all(isAllChar)
        error('Type Error: The fields imgData.inputFile must be a character vector representing a valid file path');
    end
end
if preProcess.intensityRange 
    isAllChar = cellfun(@ischar, imgData.inputFile);
    if ~all(isAllChar)
        error('Type Error: The fields imgData.inputFile must be a character vector representing a valid file path');
    end
end

%% Check dimension

if preProcess.calibration
    if numel(imgData.inputDir) ~= numel(imgData.calibration.inputFile)
        error('Dimension Error: The number of input directories in imgData.inputDir must match the number of calibration input files in imgData.calibration.inputFile.');
    end
end
if preProcess.intensityRange
    if numel(imgData.inputDir) ~= numel(imgData.inputFile)
        error('Dimension Error: The number of input directories in imgData.inputDir must match the number of crop input files in  imgData.inputFile.');
    end
end
if preProcess.crop
    if numel(imgData.inputDir) ~= numel(imgData.inputFile)
        error('Dimension Error: The number of input directories in imgData.inputDir must match the number of crop input files in imgData.inputFile.');
    end
end

%% Check file existence

if preProcess.crop
    for i = 1:numel(imgData.inputFile)
        imgDatai.inputFile = imgData.inputFile{i};
        imgDatai.inputDir = imgData.inputDir{i};
        imagePath = fullfile(imgDatai.inputDir, imgDatai.inputFile);
        if ~exist(imagePath, 'file'); error('Input image file "%s" not found.', imagePath); end
    end
end
if preProcess.calibration
    for i = 1:numel(imgData.calibration.inputFile)
        imgDatai.inputFile = imgData.calibration.inputFile{i};
        imgDatai.inputDir = imgData.inputDir{i};
        imagePath = fullfile(imgDatai.inputDir, imgDatai.inputFile);
        if ~exist(imagePath, 'file'); error('Input image file "%s" not found.', imagePath); end
    end
end
if preProcess.intensityRange
    for i = 1:numel(imgData.inputFile)
        imgDatai.inputFile = imgData.inputFile{i};
        imgDatai.inputDir = imgData.inputDir{i};
        imagePath = fullfile(imgDatai.inputDir, imgDatai.inputFile);
        if ~exist(imagePath, 'file'); error('Input image file "%s" not found.', imagePath); end
    end
end

%%

disp('Input parameters ok!')
