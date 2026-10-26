
close all  
clearvars
rehash toolboxcache 

%% PreProcessing

preProcess.crop = true;
preProcess.calibration = true;
preProcess.intensityRange = true;

% path to folders with image files to be pre-processed
imgData.inputDir ={'../data/Images','../data/Images'}; 
% image file names
imgData.inputFile = {'cataclasiteA_micro.jpg','cataclasiteA_sample.jpg'};
% image file names for calibration
imgData.calibration.inputFile = {'cataclasiteA_micro.jpg','cataclasiteA_sample.jpg'};

% output directory
imgData.outputDir =  '../output';

%% Call Preprocessing

% path to src directory
src_path = '../src';

addpath(genpath(src_path));

[px2m, cropArea,technique.range] = runPreProcessing(preProcess,imgData);
