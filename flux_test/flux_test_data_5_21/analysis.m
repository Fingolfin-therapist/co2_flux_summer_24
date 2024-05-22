%% Flux Test Data Analysis - 5/21/2024
%
%

clc, clear, close all

%% Import Datasets

% import licor dataset
licor = IMPORTLICORFILE("licor.data");

% import daq dataset
daq = IMPORTDAQFILE('daq.txt');



%% Manualy Define Test Time Ranges

% Test Number
test_no = 3;


tests = ["5/21/2024  11:47:00 AM", "5/21/2024  12:11:00 PM", 0.6418e-6, 536;...
         "5/21/2024  12:28:00 PM", "5/21/2024  12:53:00 PM", 3.2088e-6, 545;...
         "5/21/2024  01:16:00 PM", "5/21/2024  01:41:00 PM", 5.7759e-6, 548];


tStart = datetime(tests(test_no,1), "InputFormat","MM/dd/uuuu hh:mm:ss aa");
tEnd = datetime(tests(test_no,2), "InputFormat","MM/dd/uuuu hh:mm:ss aa");

%% Import DAQ Dataset
daqTimeOffset = -minutes(70);


daq.T = datetime( timeofday(daq.T) + datetime(tests(1,1), "InputFormat","MM/dd/uuuu hh:mm:ss aa") + daqTimeOffset, 'Format', 'default');
 %%


% licor was observed to have a 3 minute offset from current time while
% sampling.
licorTimeOffset = -minutes(3);


%shrink both datasets to range
licor_idx = licor.T < tEnd + licorTimeOffset & licor.T > tStart + licorTimeOffset;
licor = licor(licor_idx, :);
%daq_idx = daq.T < tEnd & daq.T > tStart;
%daq = daq(daq_idx, :);

data = synchronize(daq, licor);
data = rmmissing(data);

%% Plot


windowSize = 10;
num_trans = (1/windowSize)*ones(1,windowSize);
den_trans = 1;
data.CB = filter(num_trans, den_trans, data.CB);

fig1 = figure();
hold on
plot(data.T, data.CB)
plot(data.T, data.C - double(tests(test_no, 4)))

%% X-Corr

data = timetable2table(data);


corrcoef(data.CB, data.C)

