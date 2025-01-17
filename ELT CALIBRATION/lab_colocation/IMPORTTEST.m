function dilutiontest442024 = IMPORTTEST(filename, dataLines)
%IMPORTFILE Import data from a text file
%  DILUTIONTEST442024 = IMPORTFILE(FILENAME) reads data from text file
%  FILENAME for the default selection.  Returns the data as a table.
%
%  DILUTIONTEST442024 = IMPORTFILE(FILE, DATALINES) reads data for the
%  specified row interval(s) of text file FILENAME. Specify DATALINES as
%  a positive scalar integer or a N-by-2 array of positive scalar
%  integers for dis-contiguous row intervals.
%
%  Example:
%  dilutiontest442024 = importfile("S:\lascheer\CO2_FLUX\Test 4 April 2024\dilution_test_4_4_2024.csv", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 05-Apr-2024 10:00:55

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TARGET", "Var2", "Var3", "START", "END"];
opts.SelectedVariableNames = ["TARGET", "START", "END"];
opts.VariableTypes = ["double", "string", "string", "datetime", "datetime"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var2", "Var3"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var2", "Var3"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "START", "InputFormat", "MM/dd/yy HH:mm");
opts = setvaropts(opts, "END", "InputFormat", "MM/dd/yy HH:mm");

% Import the data
dilutiontest442024 = readtable(filename, opts);

end