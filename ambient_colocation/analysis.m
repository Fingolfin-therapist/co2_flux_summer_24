%% analysis.m
%
% A tool for analysing PICARRO and DAQ colocations.
%
% May 2024
%

clc, clear, close all
%% Import DAQ Dataset

daq = importdaqfile("daq.txt");


%% Import PICARRO Datasets from subfolder

picarro = importpicarrosubfolders("picarro/2024");

%% Clean Datasets
daq = rmmissing(daq);
picarro = rmmissing(picarro);


%% Time Overlap and Shift

% Shift Picarro Dataset By 6 Hours
% Corresponds to GMT (-7) and Daylight Savings (+1) Time Shifts
picarro.T = picarro.T - hours(6);


%% Find Overlapping Times
daq_max_t = max(daq.T);
daq_min_t = min(daq.T);
picarro_max_t = max(picarro.T);
picarro_min_t = min(picarro.T);

% confine picarro dataset to daq range
picarro_idx = picarro.T < daq_max_t & picarro.T > daq_min_t;
picarro = picarro(picarro_idx, :);

%% Plot RAW Data
fig1  = figure();
hold on
plot(picarro.T, picarro.CO2_sync)
plot(daq.T, daq.CA)
plot(daq.T, daq.CB)
legend(["Picarro CO2 (Sync)", "DAQ ELT A", "DAQ ELT B"])
xlabel("Datetime")
ylabel("CO_2 [ppm]")
title("Ambient Colocation Raw Data")
grid on

%% Apply Windowing Filter and Syncronize Dataset
windowSize = 1000;
num_trans = (1/windowSize)*ones(1,windowSize);
den_trans = 1;
picarro.CO2_sync = filter(num_trans, den_trans, picarro.CO2_sync);
daq.CA = filter(num_trans, den_trans, daq.CA);
daq.CB = filter(num_trans, den_trans, daq.CB);
picarro(1:windowSize*2, :) = [];
daq(1:windowSize*2, :) = [];

data = synchronize(daq, picarro);
data = rmmissing(data);

%% Plot Smooth Data
fig2  = figure();
hold on
plot(data.T, data.CO2_sync)
plot(data.T, data.CA)
plot(data.T, data.CB)
legend(["Picarro CO2 (Sync)", "DAQ ELT A", "DAQ ELT B"])
xlabel("Datetime")
ylabel("CO_2 [ppm]")
title("Ambient Colocation Smoothed Data")
grid on


%% Split Data for Regressions
cv = cvpartition(size(data,1), 'HoldOut', 0.3);

data = [data.CA, data.TA, data.HA, data.CB, data.TB, data.HB, data.CO2_sync];
testd = data(cv.test, :);
traind = data(~cv.test, :);

train_ca = traind(:, 1:3);
train_cb = traind(:, 4:6);
train_ct = traind(:, 7);
test_ca = testd(:, 1:3);
test_cb = testd(:, 4:6);
test_ct = testd(:, 7);

%% Linear Regression
lin_rega = fitlm(train_ca, train_ct);
lin_regb = fitlm(train_cb, train_ct);

%% ANN Regression
ann_rega = feedforwardnet([16, 16]);
ann_regb = feedforwardnet([16, 16]);
ann_rega = train(ann_rega, train_ca', train_ct');
ann_regb = train(ann_regb, train_cb', train_ct');

%% Score Regressions
ann_rega_pred = ann_rega(test_ca')';
ann_regb_pred = ann_regb(test_cb')';
lin_rega_pred = predict(lin_rega, test_ca);
lin_regb_pred = predict(lin_regb, test_cb);

ann_rega_r2 = 1 - ((sum((ann_rega_pred - test_ct).^2))/(sum(((test_ct - mean(test_ct)).^2))));
ann_regb_r2 = 1 - ((sum((ann_regb_pred - test_ct).^2))/(sum(((test_ct - mean(test_ct)).^2))));
lin_rega_r2 = 1 - ((sum((lin_rega_pred - test_ct).^2))/(sum(((test_ct - mean(test_ct)).^2))));
lin_regb_r2 = 1 - ((sum((lin_regb_pred - test_ct).^2))/(sum(((test_ct - mean(test_ct)).^2))));

lin_rega_rmse = lin_rega.RMSE;
lin_regb_rmse = lin_regb.RMSE;
ann_rega_rmse = sqrt(mean((ann_rega_pred - test_ct).^2));
ann_regb_rmse = sqrt(mean((ann_regb_pred - test_ct).^2));
%% Examine Regression Residuals
ann_rega_resid = ann_rega_pred - test_ct;
ann_regb_resid = ann_regb_pred - test_ct;
lin_rega_resid = lin_rega_pred - test_ct;
lin_regb_resid = lin_regb_pred - test_ct;

fig4 = figure();
hold on
subplot(2, 2, 1)
plot(test_ct, ann_rega_resid, 'o')
title("ANN ELT A")
ylabel("CO_2 Residuals [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend("RMSE:    "+ann_rega_rmse+"\newlineR^2:    "+ann_rega_r2)
grid on
subplot(2, 2, 2)
plot(test_ct, ann_regb_resid, 'o')
title("ANN ELT B")
ylabel("CO_2 Residuals [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend("RMSE:    "+ann_regb_rmse+"\newlineR^2:    "+ann_regb_r2)
grid on
subplot(2, 2, 3)
plot(test_ct, lin_rega_resid, 'o')
title("Linear ELT A")
ylabel("CO_2 Residuals [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend("RMSE:    "+lin_rega_rmse+"\newlineR^2:    "+lin_rega_r2)
grid on
subplot(2, 2, 4)
plot(test_ct, lin_regb_resid, 'o')
title("Linear ELT B")
ylabel("CO_2 Residuals [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend("RMSE:    "+lin_regb_rmse+"\newlineR^2:    "+lin_regb_r2)
grid on
sgtitle("Comparison of Linear and ANN Regression Residuals")

%% Examine Regression Performance

fig5 = figure();
subplot(2, 2, 1)
hold on
plot(test_ct, ann_rega_pred, 'o')
plot(test_ct, test_ct, '-')
title("ANN ELT A")
ylabel("ANN Response CO_2 [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend(["RMSE:    "+ann_rega_rmse+"\newlineR^2:    "+ann_rega_r2,'1:1 Fit'])
grid on
subplot(2, 2, 2)
hold on
plot(test_ct, ann_regb_pred, 'o')
plot(test_ct, test_ct, '-')
title("ANN ELT B")
ylabel("ANN Response CO_2 [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend(["RMSE:    "+ann_regb_rmse+"\newlineR^2:    "+ann_regb_r2,'1:1 Fit'])
grid on
subplot(2, 2, 3)
hold on
plot(test_ct, lin_rega_pred, 'o')
plot(test_ct, test_ct, '-')
title("Linear ELT A")
ylabel("Linear Response CO_2 [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend(["RMSE:    "+lin_rega_rmse+"\newlineR^2:    "+lin_rega_r2,'1:1 Fit'])
grid on
subplot(2, 2, 4)
hold on
plot(test_ct, lin_regb_pred, 'o')
plot(test_ct, test_ct, '-')
title("Linear ELT B")
ylabel("Linear Response CO_2 [ppm]")
xlabel("Picarro CO_2 [ppm]")
legend(["RMSE:    "+lin_regb_rmse+"\newlineR^2:    "+lin_regb_r2,'1:1 Fit'])
grid on
sgtitle("Comparison of Linear and ANN Regression Performance")