%% This Dataset is For Closed Loop Sensor Calibration
%
% Lincoln Scheer
% 6/16/2024
%

clc, clear, close all
set(groot,'defaulttextinterpreter','tex');  
set(groot, 'defaultAxesTickLabelInterpreter','tex');  
set(groot, 'defaultLegendInterpreter','tex');

%% Import Datasets

% import
daq = IMPORTDAQFILE("daq.csv");
licor = IMPORTLICORFILE("licor.txt");

% remove rows that show the ELTs throwing errors
elt_errors = [500, 2815, 64537, 231753, 65535];
for elt_error = elt_errors
    daq_idx = daq.CA ~= elt_error;
    daq = daq(daq_idx, :);
    daq_idx = daq.CB ~= elt_error;
    daq = daq(daq_idx, :);
end

%% plot raw sensor data
figure();
hold on;
plot(daq.T, daq.CA, 'DisplayName', 'ELT CO_2 A');
plot(daq.T, daq.CB, 'DisplayName', 'ELT CO_2 B');
plot(licor.T, licor.C, 'DisplayName', 'LICOR CO_2');
legend();
title("Closed Loop Calibration - Raw Sensor Data");

%% smooth data over 5 mins

smooth_dt = minutes(5);

% retime datasets
daq = retime(daq,"regular", 'mean', 'TimeStep', seconds(30));
licor = retime(licor,"regular", 'mean', 'TimeStep', seconds(30));

% apply moving mean
daq = rmoutliers(daq, 'percentile', [20 80]);
licor = rmoutliers(licor, 'percentile', [20 80]);

% apply moving mean
daq = smoothdata(daq, 'movmean', minutes(5));
licor = smoothdata(licor, 'movmean', minutes(5));



data = synchronize(daq, licor);

% plot smoothed data

figure();
hold on;
plot(daq.T, daq.CA, 'DisplayName', 'ELT CO_2 A');
plot(daq.T, daq.CB, 'DisplayName', 'ELT CO_2 B');
plot(licor.T, licor.C, 'DisplayName', 'LICOR CO_2');
legend();
title("Closed Loop Calibration - Hourly Smoothed Sensor Data");

%% generate regressions

CA_Model = fitlm(data.CA, data.C);
CB_Model = fitlm(data.CB, data.C);


% plot regressions

figure();
subplot(1, 2, 1);
plot(CA_Model);

txt = "RMSE: " + CA_Model.RMSE + "\newlineR^2: " + CA_Model.Rsquared.Ordinary

text(min(xlim)+50, max(ylim)-50,  txt);
xlabel("ELT A CO_2 [ppm]");
ylabel("LICOR CO_2 [ppm]");
title("ELT A Regression");


subplot(1, 2, 2);
plot(CB_Model);

txt = "RMSE: " + CB_Model.RMSE + "\newlineR^2: " + CB_Model.Rsquared.Ordinary

text(min(xlim)+50, max(ylim)-50,  txt);
xlabel("ELT B CO_2 [ppm]");
ylabel("LICOR CO_2 [ppm]");
title("ELT B Regression");
