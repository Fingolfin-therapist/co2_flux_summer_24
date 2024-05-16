%% Calibration Script for Volumetric Flow to Mass Flow for 2.5 LPM MFC
%
% CO2 Flux Project
%
% This script takes in a calibration dataset for a MFC and returns a linear
% regression model that can be used to correct values for the MFC.

clc, clear, close all

%% Import Data
data = readtable("calibration_slpm.csv");

%% Flow Calibration
X = table2array(data(:, 1));  % LPM
y = table2array(data(:, 2));  % SLPM

% Linear Regression for Flow
Q_actual = fitlm(X, y);

%% Plot Calibrations
save("q_calib","Q_actual")
