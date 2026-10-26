function runAnalyzeBubble(imgData,technique)

%% Check inputs

checkInputAnalyze(imgData,technique)

%% Create directories

RD = sprintf(imgData.outputDir);
if ~exist(RD,'dir'); mkdir(RD); end
RDgTruth =  fullfile(RD,'gTruth');
if ~exist(RDgTruth,'dir'); mkdir(RDgTruth); end
RDFig = fullfile(RD,'LabeledImages');
if ~exist(RDFig,'dir'); mkdir(RDFig); end
RDMeasure = fullfile(RD,'Measurements');
if ~exist(RDMeasure,'dir'); mkdir(RDMeasure); end
imgDatai.inputDir = imgData.inputDir;

%% Check whetever a single or multiple values are passed

if isscalar(imgData.px2m)
    px2mi = imgData.px2m*ones(1,numel(imgData.inputFile));
else
    px2mi = imgData.px2m;
end
if isscalar(technique.range(1,:)); technique.range = technique.range*ones(1,numel(imgData.inputFile));end

for i = 1:numel(imgData.inputFile)

    %% Call analyzeBubble

    imgDatai.inputFile = imgData.inputFile{i};

    imagePath = fullfile(imgDatai.inputDir, imgDatai.inputFile);
    fprintf('Analyzing image file "%s".\n', imagePath);

    techniquei.range = technique.range(:,i);

    [gTruth,segmentedImage] = analyzeBubble(imagePath,techniquei);

    %% Save gTruth

    baseFileName = sprintf('gTruth_%3.3d.mat', i);
    fullFilename = fullfile(RDgTruth,baseFileName);
    save(fullFilename,'gTruth');

    %% Save bubble measurements

    % calculate labeled image LI from groundTruth object
    im = gTruth.DataSource.Source{1};
    I = imread(im);
    imSize = size(I);
    roiPositions = gTruth.LabelData{1,:}';
    roilabelID = (1:numel(roiPositions))';
    LI = poly2label(roiPositions,roilabelID,imSize');
    % calculate measurements
    bubbleMeasurements = regionprops(LI,...
        {'EquivDiameter','Area','MajorAxisLength',...
        'MinorAxisLength','Perimeter',...
        'MaxFeretProperties','MinFeretProperties',...
        'Eccentricity','Orientation','Circularity','Solidity'});
    % save measurements table
    bubbleTable = struct2table(bubbleMeasurements,'AsArray',true);
    bubbleTable.EquivDiameter = bubbleTable.EquivDiameter*px2mi(i);
    bubbleTable.Area = bubbleTable.Area*(px2mi(i)^2);
    bubbleTable.MajorAxisLength = bubbleTable.MajorAxisLength*px2mi(i);
    bubbleTable.MinorAxisLength = bubbleTable.MinorAxisLength*px2mi(i);
    bubbleTable.Perimeter = bubbleTable.Perimeter*px2mi(i);
    bubbleTable.MaxFeretDiameter = bubbleTable.MaxFeretDiameter*px2mi(i);
    bubbleTable.MinFeretDiameter = bubbleTable.MinFeretDiameter*px2mi(i);
    baseTableName = sprintf('measurementsTable_%3.3d',i);
    fullTablename = fullfile(RDMeasure,baseTableName);
    save(fullTablename, 'bubbleTable');
    fullTablename_csv = fullfile(RDMeasure,[baseTableName,'.csv']);
    writetable(bubbleTable,fullTablename_csv);

    %% Plot figures

    figure(i);
    sgtitle('Segmented image')
    imagesc(segmentedImage.original);colormap(gray(256));
    axis image
    hold on;
    for k = 1 : segmentedImage.nBlobs
        % Plot the outline.
        thisBoundary = segmentedImage.boundaries{k};
        plot(thisBoundary(:,2), thisBoundary(:,1), 'y', 'LineWidth', 1);
    end


    %% Save figures

    baseFigName = sprintf('bubbleLabel_%3.3d.png',i);
    fullFigname = fullfile(RDFig,baseFigName);
    saveas(i,fullFigname)

end


end