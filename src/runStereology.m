function runStereology(measureData)

%% Directory containing runStereology.m
functionDir = fileparts(mfilename('fullpath'));

%% Python virtual environment and module paths
modulePath = fullfile(functionDir, 'Stereology');
pythonExe = fullfile(modulePath, 'venv', 'bin', 'python');
moduleFile = fullfile(modulePath, 'stereology.py');

if ~isfile(pythonExe)
    error('Python executable does not exist: %s', pythonExe);
end

if ~isfile(moduleFile)
    error('Python module does not exist: %s', moduleFile);
end

%% Add MATLAB functions in Stereology directory
addpath(genpath(modulePath));

%% Configure MATLAB to use the virtual environment
pe = pyenv;

if pe.Status == "Loaded"
    if string(pe.Executable) ~= string(pythonExe)
        terminate(pe);
        pyenv(Version=pythonExe);
    end
else
    pyenv(Version=pythonExe);
end

%% Add Python module directory to sys.path
modulePathPy = char(modulePath);

if count(py.sys.path, modulePathPy) == 0
    insert(py.sys.path, int32(0), modulePathPy);
end

%% Import Python module once
stereologyModule = py.importlib.import_module('stereology');

%% Create output directories
RD = measureData.outputDir;

if ~exist(RD, 'dir')
    mkdir(RD);
end

RDMeasure = fullfile(RD, 'Measurements');

if ~exist(RDMeasure, 'dir')
    mkdir(RDMeasure);
end

%% Call stereology
disp(' ')

for i = 1:numel(measureData.inputFile)

    filenamei = fullfile( ...
        measureData.inputDir, ...
        measureData.inputFile{i});

    if isfile(filenamei)
        fprintf('Convert %s\n',measureData.inputFile{i},'...')
        disp(' ')
    else
        error('File %s does not exist.', filenamei);
    end

    %% Call Python function
    resultPy = stereologyModule.stereology(char(filenamei));

    %% Convert Python result to MATLAB
    %result = double(resultPy);

    fprintf('Stereological conversion succesfull!\n');
end

end