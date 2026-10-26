function [px2m,cropArea,Irange] = preProcessing(preProcess,imgData)  % [px2m, cropArea, Irange]
% preProcessing - Processes images for spatial calibration, cropping, and intensity extraction.
%
% Parameters:
%   imgData (struct): Contains directories and image filenames
%   preProcess (struct): Flags for different preprocessing steps
%
% Outputs:
%   px2m (double array, optional): Pixels-to-meters conversion factor
%   cropArea (double array, optional): Area of the cropped regions in pixels²
%   Irange (double array, optional): Intensity range [min, max] for each image
%
%% Calibration (Convert pixels to real-world units)

px2m = [];
if preProcess.calibration

    px2m = zeros(1, numel(imgData.calibration.inputFile));

    for i = 1:numel(imgData.calibration.inputFile)
        calibrationImagePath = fullfile(imgData.inputDir{i}, imgData.calibration.inputFile{i});
        fprintf('Calibrating image %d/%d: %s\n', i, numel(imgData.calibration.inputFile), imgData.calibration.inputFile{i});

        % Perform calibration
        temp_px2m = spatialCalibration(calibrationImagePath);

        % Check if calibration was successful
        if isempty(temp_px2m) || isnan(temp_px2m)
            warning('Calibration failed for %s. Skipping...', imgData.calibration.inputFile{i});
        else
            px2m(i) = temp_px2m;
            fprintf('Calibration successful: px2m = %.6f m/pixel\n', px2m(i));
        end
    end

end

%% Cropping (Manual or Rectangle)

cropArea = [];
if preProcess.crop

    prevMask = [];
    prevRect = [];
    cropArea = zeros(1, numel(imgData.inputFile));

    for i = 1:numel(imgData.inputFile)
        cropImagePath = fullfile(imgData.inputDir{i}, imgData.inputFile{i});
        [~, name, ext] = fileparts(imgData.inputFile{i});
        cropImageFilename = sprintf('%s_%03d%s', name, i, ext);
        cropImageSavePath = fullfile(imgData.cropDir, cropImageFilename);

        fprintf('Processing: %s -> %s\n', imgData.inputFile{i}, cropImageFilename);
        [~, cropArea(i), prevMask, prevRect] = freehandOrRectCrop(cropImagePath, cropImageSavePath, prevMask, prevRect);
        fprintf('Cropped area: %d pixels²\n', cropArea(i));
    end

end

%% Intensity Range Extraction

Irange = [];
if preProcess.intensityRange && ~isempty(imgData.inputFile)
    Irange = zeros(2, numel(imgData.inputFile));
    for i = 1:numel(imgData.inputFile)
        % Generate the path to the intensityRange image
        intensityImagePath = fullfile(imgData.inputDir{i}, imgData.inputFile{i});

        % Print the image being processed for debugging
        fprintf('Processing intensity range for image: %s\n', intensityImagePath);

        % Extract intensity range for the current image
        Irange(:, i) = extract_intensity(intensityImagePath);

        % Print the extracted intensity range for debugging
        fprintf('Extracted intensity range: Min = %.2f, Max = %.2f\n', Irange(1, i), Irange(2, i));
    end
end

end
