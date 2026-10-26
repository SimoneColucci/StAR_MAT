function [px2m, cropArea, Irange] = runPreProcessing(preProcess,imgData)

%% Check inputs

checkInputPreProcessing(preProcess, imgData)

%% Create Directories

RD = imgData.outputDir;
if ~exist(RD, 'dir'), mkdir(RD); end
imgData.cropDir = fullfile(RD, 'CropImages');
if ~exist(imgData.cropDir, 'dir'), mkdir(imgData.cropDir); end

%% Call preProcessing

[px2m, cropArea, Irange] = preProcessing(preProcess,imgData);

%% Save Only Enabled Variables

outputFile = fullfile(RD, 'preProcessingResults.mat');
saveVars = {};
if preProcess.calibration && ~isempty(px2m)
    saveVars = [saveVars, {'px2m'}];
end
if preProcess.crop && ~isempty(cropArea)
    saveVars = [saveVars, {'cropArea'}];
end
if preProcess.intensityRange && ~isempty(Irange)
    saveVars = [saveVars, {'Irange'}];
end

% Save only if there are variables to store
if ~isempty(saveVars)
    save(outputFile, saveVars{:});
    fprintf('Results saved to %s\n', outputFile);
else
    warning('No data to save for .mat file.');
end

%% Save CSV File (Only With Active Data)

csvFile = fullfile(RD, 'preProcessingResults.csv');
data = [];
variableNames = {};  % Initialize variableNames array

if preProcess.calibration && ~isempty(px2m)
    px2m = px2m(:)';  % Ensure px2m is horizontal
    data = [data, px2m];
    % Create variable names like 'px2m_1', 'px2m_2', ...
    px2mNames = arrayfun(@(i) sprintf('px2m_%d', i), 1:numel(px2m), 'UniformOutput', false);
    variableNames = [variableNames, px2mNames];  % Add to variableNames
end

if preProcess.crop && ~isempty(cropArea)
    cropArea = cropArea(:)';  
    data = [data, cropArea];
    cropAreaNames = arrayfun(@(i) sprintf('cropArea_%d', i), 1:numel(cropArea), 'UniformOutput', false);
    variableNames = [variableNames, cropAreaNames]; 
end

if preProcess.intensityRange && ~isempty(Irange)
    Irangemin = Irange(1,:);
    Irangemax = Irange(2,:) ;
    data = [data, Irangemin, Irangemax];
    IrangeminNames = arrayfun(@(i) sprintf('IrangeMin_%d', i), 1:numel(Irangemin), 'UniformOutput', false);
    IrangemaxNames = arrayfun(@(i) sprintf('IrangeMax_%d', i), 1:numel(Irangemax), 'UniformOutput', false);
    variableNames = [variableNames, IrangeminNames, IrangemaxNames]; 
end

% If data contains any valid columns, save it to CSV
if ~isempty(data)
    dataTable = array2table(data, 'VariableNames', variableNames);
    writetable(dataTable, csvFile);
    fprintf('Results saved to %s\n', csvFile);
else
    warning('No data to save for CSV file.');
end

end
