function Y = NM80_readoutput(output_dir,P)


% return output depending on the QoI we are interested in
switch P.FixedParameters.QoI

    case 'Power'
        filename = fullfile(output_dir,'AeroPower.dat'); % location of the AeroPower.dat output file
        [Times,Azimuthdeg,PowerWatt,Axial_ForceN] = AeroPower(filename);
        Y = mean(PowerWatt);
        
    case 'Axial_Force'
        filename = fullfile(output_dir,'AeroPower.dat'); % location of the AeroPower.dat output file
        [Times,Azimuthdeg,PowerWatt,Axial_ForceN] = AeroPower(filename); 
        Y = mean(Axial_ForceN);
        
    case 'Sectional_normal_force'   
        % in this case the QoI is a vector, returning the time-averaged force at
        % each section
        filename = fullfile(output_dir,'B1n_BEM.txt');
        
        % Read output data generated by AeroModule
        D = readtable(filename,'HeaderLines', 4,"ReadVariableNames",true,...
            "PreserveVariableNames",true); % Reads the variable data from the 
                                           % specified .txt file
        % column 1 is time, 
        % column 2 is azimuth,
        % columns 3:end correspond to different radial locations
        Fn = D{:,3:end};     
        
        % Radial stations   
        r_sim = str2double(D.Properties.VariableNames(3:end)); 
        % no need to add hub radius, if the experimental locations are
        % reported as distance from blade root,
        % otherwise, add 1.24 m
%         r_sim = r_sim + 1.24; % according to Koen
        
        %% Calculate mean
        % Get mean (average in time) values at different radial stations
        Fn_mean = mean(Fn,1); % Mean (average in time) values at different radial stations
        
        %% Interpolation
        % These values are made available from Danaero experiments
        r_exp = P.FixedParameters.r_exp;
        Y   = spline(r_sim,Fn_mean,r_exp); % Interpolated data using spline
        
        
    otherwise
        error(strcat('QoI type unknown; check the turbine file ',P{29}));
end

end