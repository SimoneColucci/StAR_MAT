
close all  
clearvars
rehash toolboxcache

%% Analyze  

% image files to be analyzed
imgData.inputDir ='../data/CropImages'; 
%imgData.inputDir ='../output/CropImages';
imgData.inputFile ={'cataclasiteA_micro_001.jpg','cataclasiteA_sample_002.jpg'}; 

% output directory
imgData.outputDir =  '../output';

% meters per pixel [m/pixel] 
imgData.px2m = [0.1257e-4, 0.0116e-4];

% segmentation: intensity range values [min; max]
technique.range = [0,0; 100,100];

%% Call AnalyzeBubble

% path to src directory
src_path = '../src';

addpath(genpath(src_path));

runAnalyzeBubble(imgData,technique);


