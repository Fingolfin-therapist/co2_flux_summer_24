function config = analysis_config()
%ANALYSIS_CONFIG Summary of this function goes here
%   Detailed explanation goes here

    % Chamber Surface Area
    config.As = 0.064844702; % [m^2]
    config.V  = 0.015220183; % [m^3]
    
    % Environment Assumptions
    config.P = 78082.9; % [Pa]
    config.T = 293.15; % [K]
    
    % Flow Meas. Uncertainty
    config.uQ = 0.33; % [lpm]
    
    % MFC Uncertainty (%RD)
    config.uQ_mfcperc = 2;
    
    % Preprocessing
    config.sample_dt = seconds(5);     % retiming applied to entire dataset
    config.smooth_dt = minutes(10);     % retiming applied to per set-point dataset
    
    % Choose Dataset (File Location)
    config.datasets = ["5.21","5.22", "5.29"];
    config.path = "data/";
    config.map_path = "data/mapping.csv";

    % Unit Conversion Functions
    config.ppm_to_mol = @(ppm) (ppm*config.P)/(1e6*8.314*config.T);  % ppm to mol/m^3
    config.mol_to_ppm = @(mol) (1e6*8.314*mol*config.T)/config.P;    % mol/m^3 to ppm
    config.lpm_to_cms = @(lpm) lpm/60000;              % liters per min to m^3 per min
    config.cms_to_lpm = @(cms) cms*60000;              % m^3 per min to liters per min
    
    % Uncertainty in Flux Measurement Function
    config.flux_uncert = @(dC, As, uQ, uC, Q) sqrt( (dC.*uQ./As).^2 + ((2.*Q.*uC)./As).^2 );
end

