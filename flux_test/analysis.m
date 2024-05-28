%% Flux Test Data Analysis - 5/21/2024
% This script is for analyzing flux datasets with the CO2 Flux Chamber
% designed by the Wildfire CO2 Flux Team at Fort Lewis College.
%
% This script is desinged to work with a LICOR LI-7810 reference sensor if
% available for validation, if not the dataset is not compared and the
% fluxes returned are just those measured with the device.
%

clc, clear, close all

%% Script Settings

% Chamber Surface Area
As = 0.064844702; % [m^2]
V  = 0.015220183; % [m^3]

% Environment Assumptions
P = 101325; % [Pa]
T = 293.15; % [K]

% Preprocessing
sample_dt = seconds(240);     % retiming applied to entire dataset
smooth_dt = seconds(240);   % retiming applied to per set-point dataset

% Choose Dataset (File Location)
dataset = "5.21";

%% Helper Functions

% Unit Conversion Functions
ppm_to_mol = @(ppm) (ppm*P)/(1e6*8.314*T);  % ppm to mol/m^3
mol_to_ppm = @(mol) (1e6*8.314*mol*T)/P;    % mol/m^3 to ppm
lpm_to_cms = @(lpm) lpm/60000;              % liters per min to m^3 per min
cms_to_lpm = @(cms) cms*60000;              % m^3 per min to liters per min

%% Import Datasets

% import licor dataset
licor = IMPORTLICORFILE('data/'+dataset+'/licor.data');

% import daq dataset
daq = IMPORTDAQFILE('data/'+dataset+'/daq.txt');
daq.Q = daq.Q/1000; % flow-meter from ccm to lpm

% import delivered flux dataset
map = readtable("data/mapping.csv");

% depending on dataset folder selected, map delivered fluxes
dataset_idx = table2array(map(:,1)) == double(dataset);
map = map(dataset_idx,:);
daqoffset = min(table2array(map(:,8)));

%% Correct Timestamps (Only If DAQ Lost RTC Data)

% if daq has timestamp issue, do offset with start of test sequence
daq.T = timeofday(daq.T) + daqoffset;

%% Find Cross-Corelation Lag & Offset Datasets

% synchronize dataset, resample at n-seconds per datapoint
sync_data = synchronize(licor, daq, 'regular', 'mean','TimeStep', sample_dt);
sync_data_c = sync_data.C;
sync_data_cb = sync_data.CB;

<<<<<<< HEAD

clear licor daq
%% Correct Timestamps
=======
% computer lag-based corelation coefficient
opt_lag = 0;
opt_corr = -inf;

max_lag = min(850, floor(height(sync_data) / 8));

for lag = -max_lag:max_lag
    
    % offset dataset
    if lag > 0
        sync_data_cb_shifted = [nan(lag, 1); sync_data_cb(1:end-lag)];
    elseif lag < 0
        sync_data_cb_shifted = [sync_data_cb(-lag+1:end); nan(-lag, 1)];
    else
        sync_data_cb_shifted = sync_data_cb;
    end
    
    % calculation corellation
    non_nan_indices = ~isnan(sync_data_c) & ~isnan(sync_data_cb_shifted);
    current_corr = corr(sync_data_c(non_nan_indices), sync_data_cb_shifted(non_nan_indices));

    % update best corelation
    if current_corr > opt_corr
        opt_corr = current_corr;
        opt_lag = lag;
    end
end


% Shift the data with the best lag
if opt_lag > 0
    shifted_cb = [nan(opt_lag, 1); sync_data.CB(1:end-opt_lag)];
    shifted_ca = [nan(opt_lag, 1); sync_data.CA(1:end-opt_lag)];
    shifted_ta = [nan(opt_lag, 1); sync_data.TA(1:end-opt_lag)];
    shifted_tb = [nan(opt_lag, 1); sync_data.TB(1:end-opt_lag)];
    shifted_ha = [nan(opt_lag, 1); sync_data.HA(1:end-opt_lag)];
    shifted_hb = [nan(opt_lag, 1); sync_data.HB(1:end-opt_lag)];
    shifted_q = [nan(opt_lag, 1); sync_data.Q(1:end-opt_lag)];
elseif opt_lag < 0
    shifted_cb = [sync_data.CB(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_ca = [sync_data.CA(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_ta = [sync_data.TA(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_tb = [sync_data.TB(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_ha = [sync_data.HA(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_hb = [sync_data.HB(-opt_lag+1:end); nan(-opt_lag, 1)];
    shifted_q = [sync_data.Q(-opt_lag+1:end); nan(-opt_lag, 1)];
else
    shifted_cb = sync_data.CB;
    shifted_ca = sync_data.CA;
    shifted_ta = sync_data.TA;
    shifted_tb = sync_data.TB;
    shifted_ha = sync_data.HA;
    shifted_hb = sync_data.HB;
    shifted_q = sync_data.Q;
end


% update data
corrected_corr_data = sync_data;
corrected_corr_data.CB = shifted_cb;
corrected_corr_data.CA = shifted_ca;
corrected_corr_data.TA = shifted_ta;
corrected_corr_data.TB = shifted_tb;
corrected_corr_data.HA = shifted_ha;
corrected_corr_data.HB = shifted_hb;
corrected_corr_data.Q = shifted_q;
corrected_corr_data = rmmissing(corrected_corr_data);
    
% plot time-shifted data
figure();
hold on;
plot(corrected_corr_data.T, corrected_corr_data.C, 'b.-', 'DisplayName', 'Reference LICOR Dataset');
plot(corrected_corr_data.T, corrected_corr_data.CB, 'g.-', 'DisplayName', 'Shifted DAQ Chamber Dataset');
plot(corrected_corr_data.T, corrected_corr_data.CA, 'r.-', 'DisplayName', 'Shifted DAQ Ambient Dataset');
ylabel('CO_2 [ppm]');
legend();
title(["Imported Dataset with Timestamp Auto-Correction Applied" "[DATASET " + dataset + "]"]);
xlabel('Time');
grid on
hold off;
sync_data = corrected_corr_data;
>>>>>>> parent of 75d7116 (Update Flux Script to Include Uncertainty, General Cleanup, and Modularize Code. Add uncertainty to Set-Point Script.)

%% Calibrate Sensors

load('calib.mat')

sync_data.CB_CALIB = predict(lin_rega, sync_data.CB);
sync_data.CA_CALIB = predict(lin_regb, sync_data.CA);
sync_data.C_CALIB = sync_data.C.*0.9996-5.5211;
sync_data.Q_CALIB = sync_data.Q*1.227+0.0143;
%corr_data.CB_CALIB = ann_regb(corr_data.CB')';
%corr_data.CA_CALIB = ann_rega(corr_data.CA')';

figure();
hold on;
plot(sync_data.T, sync_data.CB_CALIB, 'g.-', 'DisplayName', 'Corrected DAQ Chamber');
plot(sync_data.T, sync_data.CA_CALIB, 'r.-', 'DisplayName', 'Corrected DAQ Ambient');
plot(sync_data.T, sync_data.C_CALIB, 'b.-', 'DisplayName', 'Corrected LICOR')
plot(sync_data.T, sync_data.CB, 'c.-', 'DisplayName', 'DAQ Chamber')
plot(sync_data.T, sync_data.CA, 'm.-', 'DisplayName', 'DAQ Ambient')
plot(sync_data.T, sync_data.C, 'k.-', 'DisplayName', 'LICOR')
ylabel('CO_2 [ppm]');
legend();
title(["Calibrations Applied to Flux Dataset" "[DATASET " + dataset + "]"]);
xlabel('Time');
hold off;

%% Governing Equations Anonymous Functions

% Chamber Concentration Non-Steady State
Cchmb = @(Camb, F, As, Q, t, V) Camb + (F.*As./Q).*(1-exp(-Q.*t./V));


%% Seperate Datasets into Set Points
 means = [];
data = [];
for dataset_idx = 1:height(map)
    
    % get timestamps
    tStart = map{dataset_idx, 8};
    tStartLicor = map{dataset_idx, 10};
    tEnd = map{dataset_idx, 9};
    tEndLicor = map{dataset_idx, 11};
    
    % select setpoint
    data_idx = sync_data.T < tEndLicor  & sync_data.T > tStartLicor;
    dataTmp = sync_data(data_idx, :);
    data = dataTmp;
    
    % apply retime average
    data = retime(data, 'regular', 'mean', 'TimeStep', smooth_dt);
    data = rmmissing(data);

    % calculate theoretical steady state
    [tss_data_l, tss_l, Cchmb_l] = CO2CHAMBERTSS(Cchmb, seconds(1), ppm_to_mol(mean(data.CA_CALIB)), map{dataset_idx, 13}*1e-6, As, lpm_to_cms(mean(data.Q_CALIB)), seconds(1), V, ppm_to_mol(5));
    tss_data_l.Time = seconds(tss_data_l.TIME) + data.T(1);
    tss_data_l.CO2 = mol_to_ppm(tss_data_l.CO2);

    % plot raw set-point dataset
    figure();
    hold on
    plot(data.T, data.C, 'b.-', 'DisplayName', 'LICOR Reference')
    plot(data.T, data.CB, 'g.-', 'DisplayName', 'DAQ Chamber')
    plot(data.T, data.CA, 'r.-', 'DisplayName', 'DAQ Ambient')
    ylabel('CO_2 [ppm]');
    legend();
    title(["Raw Data - Delivering " + map{dataset_idx, 13} + " μmol/m^2/s", "[DATASET " + dataset + "]"]);
    xlabel('Time');
    hold off
    
    % plot calibrated set-point dataset
    figure();
    hold on
    plot(data.T, data.C_CALIB, 'b.-', 'DisplayName', 'Corrected LICOR Reference')
    plot(data.T, data.CB_CALIB, 'g.-', 'DisplayName', 'Corrected DAQ Chamber')
    plot(data.T, data.CA_CALIB, 'r.-', 'DisplayName', 'Corrected DAQ Ambient')
    plot(tss_data_l.Time, tss_data_l.CO2, 'k-', 'DisplayName', 'Expected Chamber Concentration', 'LineWidth', 2)
    ylabel('CO_2 [ppm]');
    legend();
    title(["Calibrated Data - Delivering " + map{dataset_idx, 13} + " μmol/m^2/s", "[DATASET " + dataset + "]"]);
    xlabel('Time');
    hold off

    % calculate floor dataset, because we are looking for offsets
    data.C_FLOOR = data.C_CALIB - min(data.C_CALIB);
    data.CB_FLOOR = data.CB_CALIB - min(data.CB_CALIB);
    data.CA_FLOOR = data.CA_CALIB - min(data.CA_CALIB);

    % plot floored dataset
    figure();
    hold on;
    plot(data.T, data.CB_FLOOR, 'g.-', 'DisplayName', 'DAQ CB');
    plot(data.T, data.CA_FLOOR, 'r.-', 'DisplayName', 'DAQ CA');
    plot(data.T, data.C_FLOOR, 'c.-', 'DisplayName', 'LICOR')
    ylabel('CO_2 [ppm]');
    legend();
    title(["Floored Data - Delivering " + map{dataset_idx, 13} + " μmol/m^2/s", "[DATASET " + dataset + "]"]);
    xlabel('Time');
    hold off;
    
    % calculate steady state indices for ELT Chamber
    tSSCb = data.T(1);
    thresh = lin_regb.RMSE;
    for i = 2:length(data.CB_CALIB)
        dCb = abs(data.CB_CALIB(i) - data.CB_CALIB(i-1));
        if(dCb > thresh)
            tSSCb = data.T(i);
        end
    end

    % calculate steady state indices for LICOR
    tSSC = data.T(1);
    for i = 2:length(data.C_CALIB)
        dC = abs(data.C_CALIB(i) - data.C_CALIB(i-1));
        if(dC > 2)
            tSSC = data.T(i);
        end
    end

    % get indices in context of data.T variable
     cb_ss = data.T > tSSCb;
    c_ss = data.T > tSSC;
    
    % plot steady state indices
    figure();
    hold on;
    plot(data.T(c_ss), data.CB_CALIB(c_ss), 'gd', 'DisplayName', 'Steady-State DAQ Chamber');
    plot(data.T(cb_ss), data.CA_CALIB(cb_ss), 'rd', 'DisplayName', 'Steady-State DAQ Ambient');
    plot(data.T(cb_ss), data.C_CALIB(cb_ss), 'cd', 'DisplayName', 'Steady-State LICOR')
    plot(data.T, data.CB_CALIB, 'g.-', 'DisplayName', 'DAQ Chamber');
    plot(data.T, data.CA_CALIB, 'r.-', 'DisplayName', 'DAQ Chamber');
    plot(data.T, data.C_CALIB, 'c.-', 'DisplayName', 'LICOR')
    plot(tss_data_l.Time, tss_data_l.CO2, 'k-', 'DisplayName', 'Expected Chamber Concentration', 'LineWidth', 2)
    ylabel('CO_2 [ppm]');
    legend();
    title(["Steady State Indices - Delivering " + map{dataset_idx, 13} + " μmol/m^2/s", "[DATASET " + dataset + "]"]);
    xlabel('Time');
    hold off;
    
    
    % calculate flux
    data.F = ((lpm_to_cms(data.Q_CALIB).*ppm_to_mol(data.CB_CALIB-data.CA_CALIB))./As).*1e6;
    data.F_FLOOR = ((lpm_to_cms(data.Q_CALIB).*ppm_to_mol(data.CB_FLOOR-data.CA_FLOOR))./As).*1e6;
    data.F_LICOR = ((lpm_to_cms(data.Q_CALIB).*ppm_to_mol(data.C_FLOOR))./As).*1e6;

    f_mean_ss = mean(data.F(cb_ss));
    f_floor_mean_ss = mean(data.F_FLOOR(cb_ss));
    f_licor_mean_ss = mean(data.F_LICOR(cb_ss));
    f_std_ss = std(data.F(cb_ss));
    f_floor_std_ss = std(data.F_FLOOR(cb_ss));
    f_licor_std_ss = std(data.F_LICOR(cb_ss));

    means = [means; f_mean_ss, f_floor_mean_ss, f_licor_mean_ss];
    
    % plot fluxes
    figure();
    hold on;
    plot(data.T(cb_ss), data.F(cb_ss), 'g.-', 'DisplayName', "SS Flux, μ: " + f_mean_ss + " σ: " + f_std_ss + " μmol/m^2/s");
    plot(data.T(c_ss), data.F_LICOR(c_ss), 'r.-', 'DisplayName', "SS Flux FLOOR LICOR, μ: " + f_licor_mean_ss + " σ: " + f_licor_std_ss + " μmol/m^2/s");
    plot(data.T(c_ss), data.F_FLOOR(c_ss), 'c.-', 'DisplayName', "SS Flux FLOOR, μ: " + f_floor_mean_ss + " σ: " + f_floor_std_ss + " μmol/m^2/s");
    yline(map{dataset_idx, 13}, 'k--', 'DisplayName', "Delivered Flux")
    ylabel('CO_2 Flux μmol/m^2/s');
    legend();
    title(["Steady State Flux Results - Delivering " + map{dataset_idx, 13} + " μmol/m^2/s", "[DATASET " + dataset + "]"]);
    xlabel('Time');
    hold off;

    % plot fluxes
    figure();
    hold on;
    plot(data.T, data.F, 'g.-', 'DisplayName', "Flux");
    plot(data.T, data.F_LICOR, 'r.-', 'DisplayName', "Flux FLOOR LICOR");
    plot(data.T, data.F_FLOOR, 'c.-', 'DisplayName', "Flux FLOOR");
    yline(map{dataset_idx, 13}, 'k--', 'DisplayName', "Delivered Flux")
    ylabel('CO_2 Flux μmol/m^2/s');
    legend();
    title(["Flux Results - Delivering " + map{dataset_idx, 13} + " μmol/m^2/s", "[DATASET " + dataset + "]"]);
    xlabel('Time');
    hold off;
    
end
%%
figure()
hold on
plot(map{:, 13}, means(:,1), 'DisplayName', 'ELT Chamber Flux')
plot(map{:, 13}, means(:,3), 'DisplayName', 'LICOR Flux')
plot(map{:, 13}, map{:, 13}, 'r--', 'DisplayName', '1:1 Fit')
ylabel('Measured CO_2 Flux [μmol/m^2/s]');
ylabel('Delivered CO_2 Flux [μmol/m^2/s]');
legend()
title("Comparing Delivered Fluxes vs. Measured Fluxes")


%% Means Addition