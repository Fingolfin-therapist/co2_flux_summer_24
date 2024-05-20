%% Analysing LICOR Flux Test Dataset
%
%
clear, clc, close all

%% Import LICOR Dataset

licor = IMPORTLICOR("licor_lab_flux_test_data.data");
licor.T = datetime( licor.DATE + timeofday(licor.TIME) , 'Format', 'default');
licor.DATE = [];
licor.TIME = [];
licor = rmmissing(licor);
licor = table2timetable(licor);

%% Import DAQ Dataset

daq = importdaqfile('daq_lab_flux_test_data.txt');

%% First Test

%% Define Date Range - Test 1
tStart1 = datetime("5/20/2024  10:08:00 AM", "InputFormat","MM/dd/uuuu hh:mm:ss aa");
tEnd1 = datetime("5/20/2024  10:24:00 AM", "InputFormat","MM/dd/uuuu hh:mm:ss aa");
F = 0.5e-6;    % umol/m^2/s
As = 

%% Define Date Range - Test 2
tStart2 = datetime("5/20/2024  10:42:00 AM", "InputFormat","MM/dd/uuuu hh:mm:ss aa");
tEnd2 = datetime("5/20/2024  11:01:00 AM", "InputFormat","MM/dd/uuuu hh:mm:ss aa");

tStart = tStart2;
tEnd = tEnd2;


% licor was observed to have a 3 minute offset from current time while
% sampling.
licorTimeOffset = -minutes(3);

% shrink both datasets to range
licor_idx = licor.T < tEnd + licorTimeOffset & licor.T > tStart + licorTimeOffset;
licor = licor(licor_idx, :);
daq_idx = daq.T < tEnd & daq.T > tStart;
daq = daq(daq_idx, :);

clear licor_idx daq_idx

%% Plot Data
fig2 = figure();
hold on
plot(licor.T, movmean(licor.C, 10));
title("Failed - Lab Flux Test Results")
xlabel("Time")
ylabel("CO_2 [ppm]")
grid on







