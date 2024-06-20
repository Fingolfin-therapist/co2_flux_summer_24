%% This Dataset is For Closed Loop Sensor Calibration
%
% Lincoln Scheer
% 6/16/2024
%

clc, clear, close all
% set(groot,'defaulttextinterpreter','tex');  
% set(groot, 'defaultAxesTickLabelInterpreter','tex');  
% set(groot, 'defaultLegendInterpreter','tex');
set(gca, 'FontSize', 40)

%% Import Datasets

% import
daq = IMPORTDAQFILE("daq.csv");
licor = IMPORTLICORFILE("licor.txt");

% split daq datasets into two seperate datasets, so that if one sensor goes
% offline we can still create a strong calibration with a sensor with more
% data.
daq.Q = [];
daqa = daq;
daqb = daq;
daqa.CB = [];
daqa.TB = [];
daqa.HB = [];
daqb.CA = [];
daqb.TA = [];
daqb.HA = [];



%%
% remove rows that show the ELTs throwing errors
elt_errors = [500, 2815, 64537, 231753, 65535, 2500, 2559];
for elt_error = elt_errors
    daq_idx = daqa.CA ~= elt_error;
    daqa = daqa(daq_idx, :);
    daq_idx = daqb.CB ~= elt_error;
    daqb = daqb(daq_idx, :);
end

%% plot raw sensor data
figure();
hold on;
plot(daqa.T, daqa.CA, 'DisplayName', 'ELT CO_2 A');
plot(daqb.T, daqb.CB, 'DisplayName', 'ELT CO_2 B');
plot(licor.T, licor.C, 'DisplayName', 'LICOR CO_2');
legend();
title("Closed Loop Calibration - Raw Sensor Data");

%% smooth data over 5 mins

smooth_dt = minutes(60);
retime_dt = minutes(1);

% retime datasets
daqa = retime(daqa,"regular", 'mean', 'TimeStep', retime_dt);
daqb = retime(daqb,"regular", 'mean', 'TimeStep', retime_dt);
licor = retime(licor,"regular", 'mean', 'TimeStep', retime_dt);

% apply moving mean
daqa = rmoutliers(daqa, 'percentile', [20 80]);
daqb = rmoutliers(daqb, 'percentile', [20 80]);
licor = rmoutliers(licor, 'percentile', [20 80]);

% apply moving mean
daqa = smoothdata(daqa, 'movmean', smooth_dt);
daqb = smoothdata(daqb, 'movmean', smooth_dt);
licor = smoothdata(licor, 'movmean', smooth_dt);



dataa = synchronize(daqa, licor);
datab = synchronize(daqb, licor);

dataa = rmmissing(dataa);
datab = rmmissing(datab);

% plot smoothed data

figure();
hold on;
plot(dataa.T, dataa.CA, 'DisplayName', 'ELT CO_2 A');
plot(datab.T, datab.CB, 'DisplayName', 'ELT CO_2 B');
plot(licor.T, licor.C, 'DisplayName', 'LICOR CO_2');
legend();
title("Closed Loop Calibration - Hourly Smoothed Sensor Data");

%% generate regressions

CA_Model = fitlm([dataa.CA, dataa.TA, dataa.HA], dataa.C);
%CB_Model = fitlm([datab.CB], datab.C);


% plot regressions

text_size = 48;

fig = figure();
hold on

plot(CA_Model.Variables.y, CA_Model.Variables.y, 'r--', 'LineWidth', 2);
plot(CA_Model.Fitted, CA_Model.Variables.y, 'b.', 'MarkerSize', 20);

txt = "RMSE: " + CA_Model.RMSE + " [ppm CO_2]\newlineR^2: " + CA_Model.Rsquared.Ordinary + "\newline\newliney=[CO_2]_{Measured}*"+table2array(CA_Model.Coefficients(1,2))+ "\newline+[Temp.]_{Measured}*"+table2array(CA_Model.Coefficients(1,3))+ "\newline+[Humid.]_{Measured}*"+table2array(CA_Model.Coefficients(1,4))+ "\newline+"+table2array(CA_Model.Coefficients(1,1));

text(min(xlim)+10, max(ylim)-50,  txt,'Interpreter','tex');
xlabel("ELT A CO_2 [ppm CO_2]",'Interpreter','tex');
ylabel("LICOR CO_2 [ppm CO_2]", 'Interpreter','tex');
title('Linear Regression for Calibrating NDIR CO_2 Sensors','Interpreter','tex');
legend(["Fitted CO_2 Dataset","1:1 Fit"], 'Interpreter', 'tex');
fontsize(fig,50, 'points')


figure();
plot(CB_Model);

txt = "RMSE: " + CB_Model.RMSE + "\newlineR^2: " + CB_Model.Rsquared.Ordinary;

text(min(xlim)+50, max(ylim)-50,  txt);
xlabel("ELT B CO_2 [ppm]");
ylabel("LICOR CO_2 [ppm]");
title("ELT B Regression");
