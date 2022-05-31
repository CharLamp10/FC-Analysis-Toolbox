%% Thesis - Charalampos Lamprou 9114 & Ioannis Ziogas 9132 - AUTh ECE
% Thesis Project: Classification and Characterization of the Effect of Migraine 
% through Functional Connectivity Characteristics: Application to EEG 
% Recordings from a Multimorbid Clinical Sample

function [SwD_all,chanlocs,chan_ind,new_Fs] = prepare_for_SwD(data,SwD_par,chan_names,Fs,flag)
% Application of Swarm Decomposition
%% Inputs:  
% data          -MxN matrix (M channels, N data length)
% SwD_par       -struct. Contains info about the SwD algorithm. Information
%                about these parapeters can be found bellow.    
% chan_names    -list of strings with channel labels
% Fs            -double. Sampling rate
% flag          -1 to return plots, 0 elsewise
% 
%% Outputs:
% SwD_all       -double matrix. Swarm decomposed components of input matrix
% chanlocs      -matrix. indexed channel labels according to number of 
%                components detected in each channel
% chan_ind      -double array.
% new_Fs        -double. New sampling rate 
%-----------------------------------------------------------------------------------------------------------------
% Authors: Ioannis Ziogas & Charalampos Lamprou
% Copyright (C) 2022 Ioannis Ziogas and Charalampos Lamprou,SPBTU,ECE,AUTh
%-----------------------------------------------------------------------------------------------------------------
%% Initialize
data = double(data);
[rows,Nold] = size(data);
chan_ind = [];
chanlocs = [];
SwD_all = [];
old_Fs = Fs;

warning('off','signal:check_order:InvalidOrderRounding')
for k = 1:rows 
    x = data(k,:);
    x = (x - mean(x)) / std(x);

%% Run SWD
    L = length(x);
    min_peak      = SwD_par.min_peak;                  % This parameter determines how many cmps will be
%                                                        extracted, the less min_peak the more components. 
%                                                        It also detemines the execution time.
    component_std = SwD_par.component_std;             % This parameter must be less than 0.2. Values smaller
%                                                        than 0.001 makes no difference in the most cases.
    welch_window  = round(SwD_par.welch_wind*L);       % This parameter determines how fine or coarse will the
%                                                        spectrum be when it is calculated in the algorithm.
%                                                        It determines how coarse the extracted components will be.
    to_fullfillSpectrum = SwD_par.to_fullfillSpectrum; % If the spectrum of the input signal is very narrow.
%                                                        This parameter makes the algorithm more efficient,
%                                                        otherwise it does not make any difference.

    param_struct  = struct('P_th',         min_peak, ...
                           'StD_th',       component_std, ...
                           'Welch_window', welch_window, ...
                           'to_fullfillSpectrum', to_fullfillSpectrum);


    % With this parameter you can control the internal clustering the algorithm does. 
    % If it is very small, no clustering happens. Large values (>0.4) may
    % cluster all components.
    param_struct.clustering_factor = SwD_par.clustering_factor; % 0.1
    % Example - terminate loop after 60 seconds
    [cmps, residal] = SWD_V5(x', param_struct);

    %% Prepare outputs - Return proper chan-locs and chan-indices
    residual  = cmps(:, end);
    cmps = cmps(:,1:end-1)';

    Nnew = length(cmps(1,:));
    new_Fs = old_Fs*Nnew/Nold;
    no_comp_SWD = size(cmps, 1);
    name = convertStringsToChars(chan_names(k));
    for l = 1:no_comp_SWD
        chanlocs = [chanlocs ; convertCharsToStrings([name int2str(l)])];
        chan_ind = [chan_ind k];
    end
    SwD_all = vertcat(SwD_all,cmps);
    fprintf("%d channel(s) complete! \n",k)
    fprintf("%d channel(s) remaining! \n",rows-k)
    fprintf("%d components were found in channel %s \n",no_comp_SWD...
        ,convertCharsToStrings(name))

    %% Plotting results
    if flag
        [Px, w] = pwelch(x);
        Pcmps   = pwelch(cmps);

        figure; 
        subplot(2, 1, 1); plot(x); title('initial signal time-domain');
        subplot(2, 1, 2); plot(w/pi, Px); title('initial signal frequency-domain');
        %plot(w/pi, Px); title('initial signal frequency-domain');

        figure; 
        subplot(2, 1, 1); plot(cmps); title('cmps time-domain');
        subplot(2, 1, 2); plot(w/pi, Pcmps);   title('cmps frequency-domain');

        figure;

        for i = 1:no_comp_SWD

            subplot(no_comp_SWD, 2, 2*(i-1)+1); plot(cmps(:, i));
            subplot(no_comp_SWD, 2, 2*(i-1)+2); plot(w/pi, Pcmps(:, i));

        end
    end
end
%   SwD_all = SwD_all';
end
