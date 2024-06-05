%% analysis_p2.m

clc, clear, close all

%%

config = analysis_config();

fluxes = [];

for dataset = config.datasets
    
    % import dataset
    [daq, licor] = IMPORTDATA(config.path, dataset);
    map = readtable(config.map_path);
    map = map(table2array(map(:,1)) == double(dataset),:);

    % synchronize dataset
    data = SYNC(daq, licor, map, config, dataset);

    % apply calibrations
    [data, co2_err] = CALIBRATE(data, dataset);

    for sp_idx = 1:1:height(map)
        
        % get sp timestamps
        tStartLicor = map{sp_idx, 10};
        tEndLicor = map{sp_idx, 11};

        % get delivered fluxes
        f_delivered = map{sp_idx, 13};

        % select setpoint
        sp = map{sp_idx, 12};
        data_sp_idx = data.T < tEndLicor  & data.T > tStartLicor;
        data_sp = data(data_sp_idx, :);        

        % calculate fluxes
        [data_sp, results] = CALCFLUX(data_sp, co2_err, config, f_delivered, sp);

        % store dataset
        writetimetable(data_sp, "data/analysis/" + dataset + "no" + sp_idx +"results.csv");

        % report results
        %disp(results);
        disp("-")

        % store fluxes
        fluxes = [fluxes; results];

    end

end

%% Plot

figure();
hold on;
plot(fluxes(:,3), fluxes(:,1), 'go', 'DisplayName', "DAQ Fluxes");
plot(fluxes(:,3), fluxes(:,2), 'bo','DisplayName', "LICOR Fluxes");
plot(fluxes(:,3),fluxes(:,3), 'r-', 'DisplayName', '1:1 Fit');
title("Lab Flux Test Results");
xlabel("Delivered CO_2 Flux [mg/m^2/s]")
ylabel("Measured CO_2 Flux [mg/m^2/s]")
legend()