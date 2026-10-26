%% 

close all  
clearvars
rehash toolboxcache 

%% Properties  

% measurements of which you want to calculate properties
measureData.inputDir = '../data/Measurements';
%measureData.inputDir = '../output/Measurements';
measureData.inputFile = { {'measurementsTable_001.mat','measurementsTable_002.mat'},{'measurementsTable_001.mat'}}; 
measureData.type = { {'2D','2D'},{'2D'}}; 

% output directory
measureData.outputDir = '../output';

% meters per pixel [m/pixel]
sample.px2m = {{0.1257e-4, 0.0116e-4},{0.1257e-4}}; 

% cropArea  [pixel^2]
sample.cropArea = { {2531833,8681988}, {2531833}}; 

method.minsearch = 'fmincon'; 

%% Call BubbleProperties

% path to src directory
src_path = '../src';

addpath(genpath(src_path));

runBubbleProperties(measureData,sample,method);
