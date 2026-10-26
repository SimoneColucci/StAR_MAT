function [gTruth, segmentedImage] = analyzeBubble(imagePath, tec)

%% Convert image to gray scale if necessary
originalImage = imread(imagePath);
[~, ~, numberOfColorChannels] = size(originalImage);
if numberOfColorChannels > 1
    fprintf('Original image file has %d color channels\nConversion to grayscale...\n',numberOfColorChannels);
    originalImage = rgb2gray(originalImage);
end

%% Analyze image

lowThreshold = min(tec.range);
highThreshold = max(tec.range);
binaryImage = (originalImage >= lowThreshold) & (originalImage <= highThreshold);

% Initialize data structure
segmentedImage = struct();
segmentedImage.original = originalImage;

% Standard processing without advanced segmentation
[segmentedImage.label, segmentedImage.nBlobs] = bwlabel(binaryImage, 8);
segmentedImage.boundaries = bwboundaries(binaryImage);

%% Handle cases with no valid bubbles
if isempty(segmentedImage.boundaries)
    warning('No valid bubbles found in the image: %s', imagePath);
    gTruth = [];
    return;
end

%% Create groundTruth object
dataSource = groundTruthDataSource(imagePath);

ldc = labelDefinitionCreator;
labelNames = cell(numel(segmentedImage.boundaries), 1);

for k = 1 : numel(segmentedImage.boundaries)
    labelNames{k} = append('Bubble', num2str(k));
    addLabel(ldc, labelNames{k}, labelType.Polygon);
end
labelDefs = create(ldc);

% Flip coordinates (from MATLAB [row, col] to [x, y] for Ground Truth)
flipBoundaries = cell(1, numel(segmentedImage.boundaries));
for i = 1 : numel(segmentedImage.boundaries)
    flipBoundaries{i} = fliplr(segmentedImage.boundaries{i});
end

% Create table for gTruth object
labelData = cell2table(flipBoundaries, 'VariableNames', labelNames);
gTruth = groundTruth(dataSource, labelDefs, labelData);

if isempty(gTruth)
    warning('No ground truth object was created.');
    return;
end

disp("Created groundTruth object successfully.")

end