%% Thesis - Charalampos Lamprou 9114 & Ioannis Ziogas 9132 - AUTh ECE
% Thesis Project: Classification and Characterization of the Effect of Migraine 
% through Functional Connectivity Characteristics: Application to EEG 
% Recordings from a Multimorbid Clinical Sample

function [mean_coher, names] = coher_swarm_calc(param_struct)

% Calculates the coherence between SwDs of different electrodes when
% both of them belong to the same band.
%
%% Inputs: 
% param_struct  -struct containing  parameters for the calculation:
%                method and surrogate parameters
% For more details, see ConnectivityAnalysis.m


%% Outputs: 
% mean_feat     -double array. The mean value of each calculated feature
%                across the given regions 
% names         -string array. Contains the name of each feature in
%                mean_feat  
%-----------------------------------------------------------------------------------------------------------------
% Authors: Ioannis Ziogas & Charalampos Lamprou
% Copyright (C) 2022 Ioannis Ziogas and Charalampos Lamprou,SPBTU,ECE,AUTh
%-----------------------------------------------------------------------------------------------------------------


%Collect signals from input struct and sum all components of each electrode
x = param_struct.a;
y = param_struct.b;
x = gather_sigs(x);
y = gather_sigs(y);

%------------------- Check if input is in correct form --------------------
if isstruct(x)
    x = struct2cell(x);
    x = unwrap_SwDs(x); %if there are two SwDs in a band then separate them
elseif ismatrix(x)
    [l,h] = size(x);
    if l < h
        x = transpose(x);
    end
    for i= 1:length(x(1,:))
        new_x{i,1} = x(:,i);
    end
    x = new_x;
end
if isstruct(y)
    y = struct2cell(y);
    y = unwrap_SwDs(y); %if there are two SwDs in a band then separate them
elseif ismatrix(y)
    [l,h] = size(y);
    if l < h
        y = transpose(y);
    end
    for i= 1:length(y(1,:))
        new_y{i,1} = y(:,i);
    end
    y = new_y;
end

elec_case = param_struct.regional;

bands = param_struct.bands;
band_method = param_struct.band_method;
if band_method == "conventional"
    conv_bands = param_struct.conv_bands;
end
Fs = param_struct.Fs;

%--------------------------------------------------------------------------

mean_coher = zeros(1,length(bands)/2);

for i = 1:length(x)
    for j = 1:length(y)
        if elec_case == "single" || elec_case == "intra-regional" || elec_case == "anti-symmetric"
            ifcond = (j > i);
        elseif elec_case == "inter-regional"  || elec_case == "left-right"
            ifcond = 1;
        end
        if ifcond && ~isempty(x{i}) && ~isempty(y{j}) && ~(all(isnan(x{i})) || all(isnan(y{j})))% j > i to discard duplicates
            param_struct.f = bands(1):0.01:bands(end);
            cohertemp = COH_calc(x{i},y{j},Fs,param_struct);                
            for b = 1:2:length(bands) - 1
                ind = (b+1)/2;
                if band_method == "conventional"
                    indn = conv_bands(ind);
                else
                    indn = string(ind);
                end
                l = find(param_struct.f == bands(b));
                u = find(param_struct.f == bands(b+1));  
                coher = cohertemp(l:u);
                coher(end+1:end+2) = 0;
                coher = circshift(coher,1);
                peaks = findpeaks(coher);
                if isempty(peaks)
                    peaks = 0;
                end
                mean_coh = mean(peaks);
                if ~exist('mCoh','var')
                    mCoh.(join(["mCoh_band_",indn],'')) = mean_coh;
                elseif exist('mCoh','var') && isfield(mCoh,join(["mCoh_band_",indn],''))
                    mCoh.(join(["mCoh_band_",indn],''))(end+1) = mean_coh;
                else
                    mCoh.(join(["mCoh_band_",indn],'')) = mean_coh;
                end
            end
        end
    end
end
            

if exist('mCoh','var')
    names = fieldnames(mCoh);
    for i = 1:length(names)
        name = names{i};
        if sum(isnan(mean(mCoh.(name)))) >= 1
            error("mCoh contains NaN")
        else
            mCoh.(name) = mean(mCoh.(name));
        end
        ind = str2num(name(11:end));
        mean_coher(ind) = mCoh.(name);
    end
elseif ~exist('mCoh','var')
    mean_coher = NaN(1,length(bands)/2);
    names = [];
end



function [reg_table] = gather_sigs(x)
    chans = fieldnames(x);
    count = 1;
    for k = 1:length(chans)    
        sig = unwrap_SwDs(x.(chans{k}));
        sig = cell2table(sig);
        idx = all(cellfun(@isempty,sig{:,:}),2);
        sig(idx,:)=[];
        sig = table2array(sig);
        sig = horzcat(sig{:});
        if ~isempty(sig)
            [lx,hx] = size(sig);
            if hx > lx
                sig = transpose(sig);
                warning("Rhythms should be in shape [samples,realizations]")
            end                              
            reg_table(:,count) = sum(sig,2);  
%             reg_chan_names(count) = chans{k};    
            count = count + 1;                       
        end
    end
end

end
