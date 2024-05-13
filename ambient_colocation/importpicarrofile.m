function dat = importpicarrofile(filename, dataLines)
%IMPORTFILE Import data from a text file
%  CFKADS255820240430082117ZDATALOGUSERSYNC = IMPORTFILE(FILENAME) reads
%  data from text file FILENAME for the default selection.  Returns the
%  data as a table.
%
%  CFKADS255820240430082117ZDATALOGUSERSYNC = IMPORTFILE(FILE,
%  DATALINES) reads data for the specified row interval(s) of text file
%  FILENAME. Specify DATALINES as a positive scalar integer or a N-by-2
%  array of positive scalar integers for dis-contiguous row intervals.
%
%  Example:
%  CFKADS255820240430082117ZDataLogUserSync = importfile("C:\Users\Lincoln Scheer\Desktop\5-7-2024-Dataset\picarro\2024\04\30\CFKADS2558-20240430-082117Z-DataLog_User_Sync.dat", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 07-May-2024 14:11:20

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 21);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = " ";

% Specify column names and types
opts.VariableNames = ["DATE", "TIME", "FRAC_DAYS_SINCE_JAN1", "FRAC_HRS_SINCE_JAN1", "JULIAN_DAYS", "EPOCH_TIME", "ALARM_STATUS", "INST_STATUS", "CavityPressure", "CavityTemp", "DasTemp", "EtalonTemp", "WarmBoxTemp", "MPVPosition", "OutletValve", "CO_sync", "CO2_sync", "CO2_dry_sync", "CH4_sync", "CH4_dry_sync", "H2O_sync"];
opts.VariableTypes = ["datetime", "datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";

% Specify variable properties
%opts = setvaropts(opts, "TIME", "WhitespaceRule", "preserve");
%opts = setvaropts(opts, "TIME", "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TIME", "InputFormat", "HH:mm:ss.sss");
opts = setvaropts(opts, "DATE", "InputFormat", "yyyy-MM-dd");

% Import the data
dat = readtable(filename, opts);
dat.T = datetime(dat.DATE + timeofday(dat.TIME), "Format","default");
dat.TIME = [];
dat.DATE = [];

dat = table2timetable(dat);

end