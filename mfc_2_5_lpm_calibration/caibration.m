%% Calibration Script for Volumetric Flow to Mass Flow for 2.5 LPM MFC
%
% CO2 Flux Project

clc, clear, close all
%% import data

data = readtable("dataset.csv");



%% Flow Calibration
X = table2array(data(:, 1));  % Q_set P_psi T_tmp
y = table2array(data(:, 7));    % Q_measure

% linear regression for flow

Q_actual = fitlm(y, X, "PredictorVars",{'Q Meas.'}, 'ResponseVar', 'Q Set.');

X = table2array(data(:, 1));  % Q_set
y = table2array(data(:, 2));  % P_psi

% linear regression for pressure

Q_set = fitlm(X, y, "PredictorVars",{'Q Set'}, 'ResponseVar', 'P Meas.');

y = table2array(data(:, 3));  % T_tmp

Q_temp = fitlm(X, y, "PredictorVars",{'Q Set'}, 'ResponseVar', 'T Meas.');

%% Plot Calibrations

save("q_calib","Q_actual")
