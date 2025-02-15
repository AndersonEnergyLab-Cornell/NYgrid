function writeHydroGen(testyear)
%WRITEHYDROGEN Download and write monthly hydro generation of Niagara and
%St. Lawrence hydropower plant, calculate capacity factor, and write it to
%csv files.

%   Created by Bo Yuan, Cornell University
%   Last modified on September 13, 2021

%% Input handling
if isempty(testyear)
    testyear = 2019; % Default data in year 2019
end

outfilename = fullfile('Data','hydroGenMonthly_'+string(testyear)+'.csv');
matfilename = fullfile('Data','hydroGenMonthly_'+string(testyear)+'.mat');

if ~isfile(outfilename) || ~isfile(matfilename) % File doesn't exist
    %% Download hydro data
    % Robert Moses Niagara
    series_id_rmn = "ELEC.PLANT.GEN.2693-ALL-ALL.M";
    cap_rmn = 2460;
    gen_data_rmn = downloadGenEia(series_id_rmn,cap_rmn);
    
    % Robert Moses Power Dam (St Lawrence FDR)
    series_id_stl = "ELEC.PLANT.GEN.2694-ALL-ALL.M";
    cap_stl = 856;
    gen_data_stl = downloadGenEia(series_id_stl,cap_stl);
    
    % Combine data for hydro generation
    hydroGenMonthly = outerjoin(gen_data_rmn,gen_data_stl,"Keys","TimeStamp",...
        "MergeKeys",true);
    hydroGenMonthly.Properties.VariableNames = ["TimeStamp","rmnGen","rmnCF","stlGen","stlCF"];
    
    % Get data for a specific year
    hydroGenMonthly = hydroGenMonthly(year(hydroGenMonthly.TimeStamp) == testyear, :);
    hydroGenMonthly.TimeStamp = datetime(hydroGenMonthly.TimeStamp,"Format","MM/dd/uuuu");
    
    %% Save the data
    writetable(hydroGenMonthly,outfilename);
    save(matfilename,"hydroGenMonthly");
    fprintf("Finished writing hydro generation data in %s and %s!\n",outfilename,matfilename);
    
else
    fprintf("Hydro generation data already exists in %s and %s!\n",outfilename,matfilename);
    
end

end

function gen_data = downloadGenEia(series_id, capacity)
%DOWNLOADGENEIA Download and process monthy plant level generation data
%from EIA, e.g., Niagara and St. Lawrence hydropower

% Set api root and key for EIA data downloading
api_root = "https://api.eia.gov/series/?api_key=%s&series_id=%s";
api_key = "d354782d2f6b4294936898ba3e6d00d9";

% Download the data
url = sprintf(api_root,api_key,series_id);
data = webread(url);

% Format the data
series_data = data.series.data;
num_month = length(series_data);
gen_data = cell(num_month, 3);
for i=1:num_month
    time = series_data{i,1}{1,1};
    year = str2num(time(1:4));
    month = str2num(time(5:6));
    time_stamp = datetime(year,month,1,"Format","MM/dd/uuuu");
    gen = series_data{i,1}{2,1};
    cf = gen/(capacity*24*eomday(year,month));
    gen_data{i,1} = time_stamp;
    gen_data{i,2} = gen;
    gen_data{i,3} = cf;
end
gen_data = cell2table(gen_data,"VariableNames",["TimeStamp","Generation","CF"]);

end