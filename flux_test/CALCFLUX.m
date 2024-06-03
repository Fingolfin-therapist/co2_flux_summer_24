function [data, results] = CALCFLUX(data,co2_err,config, f_delivered)


% convert to working units
% ppm -> mol/m^3
% lpm -> cms

co2_err = config.ppm_to_mol(co2_err);
data.C = config.ppm_to_mol(data.C);
data.CA = config.ppm_to_mol(data.CA);
data.CB = config.ppm_to_mol(data.CB);
data.Q = config.lpm_to_cms(data.Q);
config.uQ = config.lpm_to_cms(config.uQ);

% smooth dataset
data = smoothdata(data, 'movmean', config.smooth_dt);

% calculate flux
data.F = 1e6*(data.Q.*(data.CB-data.CA))./config.As;
data.F_licor = 1e6*(data.Q.*(data.C-data.C(1)))./config.As;
data.UF = 1e6*config.flux_uncert(data.CB-data.CA, config.As, co2_err, config.uQ, data.Q);

results = [data.F(end), data.F_licor(end), f_delivered];


end

