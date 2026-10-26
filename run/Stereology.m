
close all  
clearvars
rehash toolboxcache

%% Stereology

% measurements to be converted
measureData.inputDir = '../data/Measurements';
%measureData.inputDir = '../output/Measurements';
measureData.inputFile = {'measurementsTable_001.csv','measurementsTable_002.csv'}; 

% output directory
measureData.outputDir = '../output';

%% Call runStereology

% path to src directory
src_path = '../src';

addpath(genpath(src_path));

runStereology(measureData);