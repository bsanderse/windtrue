function data = read_interpolatef(filename)

%% Read output data generated by AeroModule
% = 'B1n_BEM.txt'; % Specify the .txt file (Variable of interest)
D = readtable(filename,'HeaderLines', 4,"ReadVariableNames",true,...
    "PreserveVariableNames",true); % Reads the variable data from the 
                                   % specified .txt file
r_a = str2double(D.Properties.VariableNames(3:end)); % Radial stations
%% Calculate mean
D_a = mean(D{:,3:end},1); % Mean values at different radial stations

%% Interpolation
% These values are made available from Danaero experiments
r_i = [11.87, 17.82, 28.97, 35.53]; % Measurement radial stations
data = spline(r_a,D_a,r_i); % Interpolated data using spline

% %% Write interpolated data
% T = table(r_i',D_a','VariableNames',{'r_i','aero_data'});
% writetable(T,'output.dat','Delimiter','\t','WriteVariableNames',true);
% type output.dat




