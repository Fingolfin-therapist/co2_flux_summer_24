%% Flux Test Data Analysis - 5/21/2024
%
%

clc, clear, close all

%% Helper Functions

% Chamber Surface Area
As = 0.064844702; % [m^2]

% Environment Assumptions
P = 101325; % [Pa]
T = 293.15; % [K]

% Unit Conversion Functions
ppm_to_mol = @(ppm) (ppm*P)/(1e6*8.314*T);  % ppm to mol/m^3
mol_to_ppm = @(mol) (1e6*8.314*mol*T)/P;    % mol/m^3 to ppm
lpm_to_cms = @(lpm) lpm/60000;              % liters per min to m^3 per min
cms_to_lpm = @(cms) cms*60000;              % m^3 per min to liters per min

%% Choose Dataset

dataset = "5.21";

%% Import Datasets

% import licor dataset
licor = IMPORTLICORFILE('data/'+dataset+'/licor.data');

% import daq dataset
daq = IMPORTDAQFILE('data/'+dataset+'/daq.txt');

% import flux dataset
map = readtable("data/mapping.csv");

% depending on dataset folder selected, map delivered fluxes
dataset_idx = table2array(map(:,1)) == double(dataset);
map = map(dataset_idx,:);
daqoffset = min(table2array(map(:,8)));

%% Correct Timestamps (Only If DAQ Lost RTC Data)

% if daq has timestamp issue, do offset with start of test sequence
daq.T = timeofday(daq.T) + daqoffset;

%% Find Cross-Corelation Lag & Offset Datasets

% synchronize dataset, resample at 5-seconds per datapoint
corr_data = synchronize(licor, daq, 'regular', 'mean','TimeStep', seconds(5));
corr_data_c = corr_data.C;
corr_data_cb = corr_data.CB;

% computer lag-based corelation coefficient
opt_lag = 0;
opt_corr = -inf;

for lag = -850:850
    
    % offset dataset
    if lag > 0
        corr_data_cb_shifted = [nan(lag, 1); corr_data_cb(1:end-lag)];
    elseif lag < 0
        corr_data_cb_shifted = [corr_data_cb(-lag+1:end); nan(-lag, 1)];
    else
        corr_data_cb_shifted = corr_data_cb;
    end
    
    % calculation corellation
    non_nan_indices = ~isnan(corr_data_c) & ~isnan(corr_data_cb_shifted);
    current_corr = corr(corr_data_c(non_nan_indices), corr_data_cb_shifted(non_nan_indices));

    % update best corelation
    if current_corr > opt_corr
        opt_corr = current_corr;
        opt_lag = lag;
    end
end


% Shift the data with the best lag
if opt_lag > 0
    shifted_cb = [nan(opt_lag, 1); corr_data.CB(1:end-opt_lag)];
    shifted_ca = [nan(opt_lag, 1); corr_data.CA(1:end-opt_lag)];
    shifted_ta = [nan(opt_lag, 1); corr_data.TA(1:end-opt_lag)];
    shifted_tb = [nan(opt_lag, 1); corr_data.TB(1:end-opt_lag)];
    shifted_ha = [nan(opt_lag, 1); corr_data.HA(1:end-opt_lag)];
    shifted_hb = [nan(opt_lag, 1); corr_data.HB(1:end-opt_lag)];
    shifted_q = [nan(opt_lag, 1); corr_data.Q(1:end-opt_lag)];
elseif opt_lag < 0
    shifted_cb = [corr_data.CB(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_ca = [corr_data.CA(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_ta = [corr_data.TA(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_tb = [corr_data.TB(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_ha = [corr_data.HA(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_hb = [corr_data.HB(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_q = [corr_data.Q(-opt_lag+1:end); nan(-opt_lag, 1)];
else
    shifted_cb = corr_data.CB;
    shifted_ca = corr_data.CA;
    shifted_ta = corr_data.TA;
    shifted_tb = corr_data.TB;
    shifted_ha = corr_data.HA;
    shifted_hb = corr_data.HB;
    shifted_q = corr_data.Q;
end


% update data
corrected_corr_data = corr_data;
corrected_corr_data.CB = shifted_cb;
corrected_corr_data.CA = shifted_ca;
corrected_corr_data.TA = shifted_ta;
corrected_corr_data.TB = shifted_tb;
corrected_corr_data.HA = shifted_ha;
corrected_corr_data.HB = shifted_hb;
corrected_corr_data.Q = shifted_q;
corrected_corr_data = rmmissing(corrected_corr_data);
    
figure();
hold on;
plot(corrected_corr_data.T, corrected_corr_data.C, 'b', 'DisplayName', 'LICOR C');
plot(corrected_corr_data.T, corrected_corr_data.CB, 'g', 'DisplayName', 'Corr. DAQ CB');
plot(corrected_corr_data.T, corrected_corr_data.CA, 'r', 'DisplayName', 'Corr. DAQ CA');
plot(corr_data.T, corr_data.CB, 'c', 'DisplayName', 'DAQ CB')
plot(corr_data.T, corr_data.CA, 'm', 'DisplayName', 'DAQ CA')
ylabel('CO_2 [ppm]');
legend();
title(['Automatic Time-Correction of Flux Test Dataset ' dataset]);
xlabel('Time');

hold off;
corr_data = corrected_corr_data;

%% Calibrate Sensors

load('calib.mat')

corr_data.CB_CALIB = ann_regb([corr_data.CB, corr_data.TB, corr_data.HB]')';
corr_data.CA_CALIB = ann_rega([corr_data.CA, corr_data.TA, corr_data.HA]')';

figure();
hold on;
plot(corr_data.T, corr_data.CB_CALIB, 'g', 'DisplayName', 'Corr. DAQ CB');
plot(corr_data.T, corr_data.CA_CALIB, 'r', 'DisplayName', 'Corr. DAQ CA');
plot(corr_data.T, corr_data.CB, 'c', 'DisplayName', 'DAQ CB')
plot(corr_data.T, corr_data.CA, 'm', 'DisplayName', 'DAQ CA')
ylabel('CO_2 [ppm]');
legend();
title(['Calibrations of ELT Sensors of Flux Test Dataset ' dataset]);
xlabel('Time');

hold off;


%% Seperate Datasets into Set Points

data = [];
for dataset_idx = 1:height(map)
    
    tStart = map{dataset_idx, 8};
    tStartLicor = map{dataset_idx, 10};
    tEnd = map{dataset_idx, 9};
    tEndLicor = map{dataset_idx, 11};
    
    data_idx = corr_data.T < tEndLicor  & corr_data.T > tStartLicor;
    dataTmp = corr_data(data_idx, :);
    data = dataTmp;
    
    
    data.CB = movmean(data.CB, 10);
    data.CA = movmean(data.CA, 10);
    
    
    figure();
    hold on
    plot(data.T, data.C, 'b', 'DisplayName', 'LICOR Reference')
    plot(data.T, data.CB, 'g', 'DisplayName', 'DAQ Chamber')
    plot(data.T, data.CA, 'r-', 'DisplayName', 'DAQ Ambient')
    ylabel('CO_2 [ppm]');
    legend();
    title("Flux Test Dataset " + dataset + " - " + map{dataset_idx, 4} +" umol/m^2/s" );
    xlabel('Time');
    hold off
    
    data.C_FLOOR = data.C - min(data.C);
    data.CB_FLOOR = data.CB - min(data.CB);
    data.CA_FLOOR = data.CA - min(data.CA);

    figure();
    hold on;
    plot(data.T, data.CB_FLOOR, 'g', 'DisplayName', 'DAQ CB');
    plot(data.T, data.CA_FLOOR, 'r', 'DisplayName', 'DAQ CA');
    plot(data.T, data.C_FLOOR, 'c', 'DisplayName', 'LICOR')
    ylabel('CO_2 [ppm]');
    legend();
    title(['Floored ELT Sensors of Flux Test Dataset ' dataset]);
    xlabel('Time');
    hold off;
    
    
    thresh = 0.05;
    cb_ss = find(abs(diff(movmean(data.CB, 100)))<thresh);
    c_ss = find(abs(diff(movmean(data.C, 100)))<thresh);
    
    figure();
    hold on;
    plot(data.T(cb_ss), data.CB_FLOOR(cb_ss), 'g.', 'DisplayName', 'DAQ CB');
    plot(data.T(cb_ss), data.CA_FLOOR(cb_ss), 'r.', 'DisplayName', 'DAQ CA');
    plot(data.T(cb_ss), data.C_FLOOR(cb_ss), 'c.', 'DisplayName', 'LICOR')
    ylabel('CO_2 [ppm]');
    legend();
    title(['Steady State Data-Points of Flux Test Dataset ' dataset]);
    xlabel('Time');
    hold off;
    
    
    data.F = (lpm_to_cms(data.Q./1000).*ppm_to_mol(data.CB-data.CA))./As;
    data.F_FLOOR = (lpm_to_cms(data.Q./1000).*ppm_to_mol(data.CB_FLOOR-data.CA_FLOOR))./As;
    data.F_LICOR = (lpm_to_cms(data.Q./1000).*ppm_to_mol(data.C_FLOOR))./As;
    figure();
    hold on;
    plot(data.T(cb_ss), data.F(cb_ss), 'go', 'DisplayName', 'SS Flux');
    plot(data.T(c_ss), data.F_LICOR(c_ss), 'co', 'DisplayName', 'SS Flux FLOOR LICOR');
    plot(data.T, data.F, 'r.', 'DisplayName', 'Flux');
    plot(data.T, data.F_FLOOR, 'm.', 'DisplayName', 'Flux FLOOR');
    plot(data.T, data.F_LICOR, 'b.', 'DisplayName', 'Flux FLOOR LICOR');
    ylabel('CO_2 Flux μmol/m^2/s');
    legend();
    title(['Flux Data-Points of Flux Test Dataset ' dataset]);
    xlabel('Time');
    hold off;
    
    
end



%% Smooth Data

