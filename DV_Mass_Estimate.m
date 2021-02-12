% Created by Joey Hammond and Colton Hook
% Function coding by Chris Larking, Christian Fuller, Miles Grave, Max McDermott
%
% This code and function sets evaluates a given mission concept and finds
% the optimal mass breakdown and maximum payload operational radius to
% maximize mission success. Success percentile and mass breakdown of
% optimal system is returned
%% Inputs


clear
clc
close all

%input orbit data, include numbers and rendevous location for non-instantanous factor
orbitname = 'Orb_1.0x1.15AU_Complete';
orbit = [1,1.35]; %AU
preposition_DV1 = 3000; %m/s   ---> launch vehicle
preposition_DV2 = 300; %m/s   ---> burn 1

mass_payload = 600; %kg
flyby_velocity_p = [0,0,10]; % [a,b,c] where flyby velocity (km/s) = a^2x + bx + c where x is heliocentric range in 1/AU
power_payload = 500; %W
R_max = [3, 8]; %Range of heliocentric rendevous design pts, AU
m_break = [.05,.7]; %Range of mass breakdown (propmass of departure stage/propmass of arrival and departure stages)

% prop = [thrust/type, drymass, ISP, power];
% thrust/type: = 0 if chemical/instantaneous thrust, else thrust in N
% drymass: mass of system independent of power and propellant/structure in kg
% ISP: specific impulse in s
% power: power required for operation in W

XR100 = [5, 250, 5000, 100000]; %2 XR-100 systems
XR100_2 = [10, 500, 5000, 200000]; %2 XR-100 systems
% R4D = [0, 3.63, 312, 46]; % 1 R4D system
R4D = [0, 3.63, 312, 0]; % 1 R4D system


% prop_scheme = [preposition_DV2, departure_DV, arrival_DV]
prop_scheme = [R4D;XR100;R4D];

%size of simulation
numR2 = 8;
numMass = 8;

% Neglect for now:
% percentages = [DVsuccess, margin, time] ---FIX
% DVsuccess: % total probability of success of DV system, from external failures
% margin: % margin on DV of each burn
% time: % mission ready time, yrs
% Expand to include other things like non-instantaneous model and gravity assist???

% Combined to determine percentile of orbits to design to!
% percentages = [96, 5, 20];
%% Current Assumptions (function assumptions not included)

% ----- Preposition -----
% Flight vehicle is Falcon Heavy Expendable
% Flight vehicle uses preposition_DV1
% Mission only viable at end of preposition process
% Max out launch vehicle mass

% -----  Departure  -----
% Solar panel at BOL throughout analysis
% Solar panels unnafected by transfer (AU >= .8)
% Solar panels sized to apogee
% 1 burn

% -----   Arrival   -----
% 1 burn

% -----    Misc     -----
% Standard units: km, yr
% No trajectory adjustment or orbital maintanence burns
% No gravity assists
% Non-instantaneous burns modeled as instantaneous calculated under a safety factor

%% Function list

% Non-instantanous adjusment
% [p1,p2] = NonInstantaneousLambert(Orbit); TEMPORARY
% [DV_adj] = DV_adjustment(DV,p,dtburn_dt); DONE

% [v] = flybyvelocity(R,p); DONE

% Power
% [power, mass, area_out] = panel_power(R,area,power); DONE
%       use panel_power(R, area) or use panel(R, [], power)

% Prop sizing
% [mass_array,power_area, dt] = prop_sizing1(total_mass, power_area, R, dv,prop_system); DONE
% [mass_array,power_area, dv, dt] = prop_sizing2(payload_mass, m0,power_area, R, prop_system)% m_payload = mass_array(1); DONE


% Launch Vehicle
% [max_m] = launchvehicle(DV); % Max

% Iteration Functions:
% [DV1, DV2, DT1, DT2, R2] = propsystemsim(m_total,mass_payload, power_payload, prop_scheme, R1, R_max); %DONE
% [success] = orbits(DV1, DV2, DT1, DT2, R2; %Colton

%% Future Work
% Change so no power draw on prepositioning function
% Add in orbits data processing
% Add post processing plots and readout
% Check: Is .05 struct good for eprop?
% Get good numbers on preposition costs!!!


% Far future work:

% Further noninstantaneous lambert study and funciton
% Refine points in analysis that assume eprop on 1st burn and chem prop on
        % 2nd burn
% Refine so burn time is adjustable and we can fuel dump stages
%% Calculations

% Find mass in launch vehicle
[p1,p2] = NonInstantaneousLambert(orbitname);
[m1] = launchvehicle(preposition_DV1);

% Find mass in preopositioned orbit
preposition_system = prop_scheme(1,:);
R1 = orbit(1);

[mass_array2,power_area2, ~] = prop_sizing1(m1, 0, R1, preposition_DV2, preposition_system);
m2 = mass_array2(1);


% Simulate a variety of proposed systems
[DV1, DV2, DT1, DT2, R2,m_break] = propsystemsim(m2, mass_payload, power_payload, prop_scheme, R1, R_max,m_break,numR2,numMass);

n = 1;
for ii = 1:size(DV1,1)
    for jj = 1:size(DV1,2)
        DV1_plot(n) = DV1(ii,jj)/1000;
        DV2_plot(n) = DV2(ii,jj)/1000;
        n = n+1;
    end
end
plot(DV1_plot,DV2_plot,'x')
xlabel('Burn 1 (km/s)')
ylabel('Burn 2 (km/s)')
title('Preprocessed DV Capabilities (Blind to dt)')


% Determine success rate of each proposed system
%   NOTES: need to verify indexing and array dimensions
%           may need to impliment parrallel loops (over 4 minutes for 5x5 currently)
%           need to know which variable sizes to reference for prealloaction/loop bounds
PosNum = 0;
tic
PercentCoverage = zeros(numR2,numMass);
maindata = LoadWholeOrbit(orbitname,12);
fprintf("0%%\n")
for ii = 1:size(DV1,1)
    for jj = 1:size(DV1,2)
        DV1sys = DV1(ii,jj); %pull single DV1 for system to check
        DV2sys = DV2(ii,jj); %pull single DV2 for system to check
        tburn1 = DT1(ii,jj); %pull single tburn1 for system to check
        tburn2 = DT2(ii,jj); %pull single tburn2 for system to check
        R2sys = R2(ii);      %pull single R2 for system to check (should this be ii or jj?)
        SuccessList = CheckSystem(orbitname,PosNum,DV1sys,DV2sys,tburn1,tburn2,R2sys,p1,p2,flyby_velocity_p,maindata); %produce list of successful ISOs
        %[a] = results(success,R2,m_break); ???
        PercentCoverage_sys = MixOrbitPositions(SuccessList,SuccessList); %check 2 spacecraft in the same orbit
        PercentCoverage(ii,jj) = mean(diag(PercentCoverage_sys)); %assume only evaluating 1 spacecraft (average over whole orbit)
    end
    fprintf("%.2f%%\n",100 * ii/size(DV1,1)) 
end
t_taken = toc;
fprintf("%.1f s taken, %.2f s/system\n",t_taken,t_taken/(numR2*numMass))


results(PercentCoverage,DV1,DV2,mass_array2,R2,m_break,ii,jj,mass_payload,power_payload,prop_scheme,R1)

