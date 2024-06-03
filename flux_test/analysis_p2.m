%% analysis_p2.m

clc, clear, close all

%%

config = analysis_config();


for dataset = config.datasets
    
    % import dataset
    [daq, licor] = IMPORTDATA(config.path, dataset);
    map = readtable(config.map_path);
    map = map(table2array(map(:,1)) == double(dataset),:);

    % synchronize dataset
    data = SYNC(licor, daq, map, config, dataset);

    % apply calibrations
    [data, co2_err] = CALIBRATE(data, dataset);

    for sp_idx = height(map)
        
        % get sp timestamps
        tStartLicor = map{sp_idx, 10};
        tEndLicor = map{sp_idx, 11};

        
        [data, results] = CALCFLUX(data, co2_err, config);

    end

    



end