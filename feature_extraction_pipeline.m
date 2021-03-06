%% Thesis - Charalampos Lamprou 9114 & Ioannis Ziogas 9132 - AUTh ECE
% Thesis Project: Classification and Characterization of the Effect of Migraine 
% through Functional Connectivity Characteristics: Application to EEG 
% Recordings from a Multimorbid Clinical Sample

function [message,varargout] = feature_extraction_pipeline(feature_name,varargin)
% Receives filepath, feature to calculate and needed input arguments, 
% loads signals, calculates feature and returns output arguments and 
% function used (for cross-checking)

%-----------------------------------------------------------------------------------------------------------------
% Authors: Ioannis Ziogas & Charalampos Lamprou
% Copyright (C) 2022 Ioannis Ziogas and Charalampos Lamprou,SPBTU,ECE,AUTh
%-----------------------------------------------------------------------------------------------------------------


available_functions = ["coherence_swarm","plv_swarm","regional_analysis",...
    "power_spectrum_features","power_spectrum_asymmetry","bspec_swarm","cross_bspec_swarm","pac_swarm"];
check = 0;
for i = 1:length(available_functions)
    func_name = available_functions(i);
    if contains(func_name,feature_name)
        check = 1;
        results{:} = calc_swarm_feature(func_name,varargin);
        func_run = func_name;
    end
end

if check == 0
    message = join(["There is no function available that calculates ",feature_name]);
    error(message)
else
    message = join(["Function ",func_run," was used for calculation of feature ",feature_name]);
    warning(message)
end
varargout = results;
end