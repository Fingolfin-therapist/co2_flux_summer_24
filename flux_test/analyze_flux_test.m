%% Analysing LICOR Flux Test Dataset
%
%
clear, clc, close all

%% Import

data = IMPORTLICOR("5_17_2024_LICOR.data");
data.T = datetime( data.DATE + timeofday(data.TIME) , 'Format', 'default');
data.DATE = [];
data.TIME = [];
data = rmmissing(data);


%% Plot Data

plot(data.T, movmean(data.C, 100))

%% Load Dataset

table = importdaqfile("initial_daq_data.txt");

figure()
plot(table.T, table.CA)
hold on
plot(table.T, table.CB)
legend("Ambient", "Chamber")


