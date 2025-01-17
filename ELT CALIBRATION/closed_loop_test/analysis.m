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

plot(CA_Model.Variables.y, CA_Model.Variables.y, '--', 'LineWidth', 5, 'MarkerSize', 20);
plot(CA_Model.Fitted, CA_Model.Variables.y, '.', 'LineWidth', 5, 'MarkerSize', 20);


xlabel("ELT A CO_2 [ppm]",'Interpreter','tex');
ylabel("LICOR CO_2 [ppm]", 'Interpreter','tex');
title('Chamber Sensor Calibration','Interpreter','tex');
legend(["1:1 Fit","Fitted CO_2 Dataset"], 'Interpreter', 'tex');
fontsize(fig, 50, 'points')
fontname('Times New Roman')

txt = "RMSE: " + round(CA_Model.RMSE,3) + " ppm\newlineR^2: " + round(CA_Model.Rsquared.Ordinary,3) + "\newliney="+round(table2array(CA_Model.Coefficients(1,2)),1)+ "x_1+"+round(table2array(CA_Model.Coefficients(1,3)),1)+ "x_2+"+round(table2array(CA_Model.Coefficients(1,4)),1)+ "x_3+"+round(table2array(CA_Model.Coefficients(1,1)),1);

text(min(xlim)+5, max(ylim)-30,  txt,'Interpreter','tex', 'FontSize', 40, 'FontName', 'Times New Roman');


fig = figure();
plot(CB_Model);


txt = "RMSE: " + CB_Model.RMSE + "\newlineR^2: " + CB_Model.Rsquared.Ordinary;

text(min(xlim)+50, max(ylim)-50,  txt);
xlabel("ELT B CO_2 [ppm]");
ylabel("LICOR CO_2 [ppm]");
title("ELT B Regression");
