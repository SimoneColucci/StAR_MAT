function [X2d,X2e,Alphad,Mud,Mue,Sigmad,Sigmae] = bubbleProperties(bubbleDim,sampleNew,method,RD,Idx,num,Mtype)
% Statistical formulation:
%   Alexander A. Proussevitch, Dork L. Sahagian, Evgeni P. Tsentalovich,
%   Statistical analysis of bubble and crystal size distributions: Formulations and procedures,
%   Journal of Volcanology and Geothermal Research,
%   Volume 164, Issue 3, 2007, Pages 95-111,
%   https://doi.org/10.1016/j.jvolgeores.2007.04.007.

%% statistics

% distribution density-based analysis
[X2d,Alphad,Mud,Sigmad] = densityBasedAnalysis(bubbleDim,sampleNew,method,RD,Idx,num,Mtype);

% exceedance-based analysis
[X2e,Mue,Sigmae] = exceedanceBasedAnalysis(bubbleDim,sampleNew,method,RD,Idx,num,Mtype);


end
