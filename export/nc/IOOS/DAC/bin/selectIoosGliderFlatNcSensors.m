function ncStruct = selectIoosGliderFlatNcSensors(pStruct, trajectoryTs, varargin)
%
% ncStruct = selectGliderFlatNcSensors(pStruct, varargin)
%
% See also writeIoosGliderFlatNc getIoosGliderFlatNcSensorMappings Dbd DbdGroup
% ============================================================================
% $RCSfile: selectIoosGliderFlatNcSensors.m,v $
% $Source: /home/kerfoot/cvsroot/slocum/matlab/spt/export/nc/IOOS/DAC/bin/selectIoosGliderFlatNcSensors.m,v $
% $Revision: 1.1 $
% $Date: 2014/06/04 19:32:20 $
% $Author: kerfoot $
% ============================================================================
%

app = mfilename;

sensorStruct = [];

% Validate args
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No profiles data structure specified');
elseif ~isstruct(pStruct)
    error(sprintf('%s:invalidArgument', app),...
        'pStruct must be a structured array representing individual profiles');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified');
end

% Process options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

sMap = getIoosGliderFlatNcSensorMappings();
if isempty(sMap)
    return;
end

% Add 'time' and 'pressure' fields to mapped to dbd.timestampSensor and
% dbd.depthSensor
% % % % % sMap.time = {'timestamp'}';
% % % % % sMap.pressure = {'depth'}';

% Fieldnames (variables) from the sensor map
vars = fieldnames(sMap);
% Select the available fields from pStruct
pFields = fieldnames(pStruct);

% Select the sensor mappings
for v = 1:length(vars)
    
    % Intialize the entry
    sensorStruct(end+1).ncVarName = vars{v};
    sensorStruct(end).sensor = '';
    sensorStruct(end).data = [];
    
    if isempty(sMap.(vars{v}))
% % % % %         warning(sprintf('%s:unknownSensorMapping', app),...
% % % % %             'Sensor map field contains no sensor mappings: %s\n',...
% % % % %             vars{v});
        continue;
    end
    
    % Search for the specified sensor in the available sensor mapping for
    % this sensor
    [C,AI] = intersect(sMap.(vars{v}), pFields);
    if isempty(C)
% % % % %         warning(sprintf('%s:sensorsNotFound', app),...
% % % % %             '%s: No sensors found in the Dbd instance\n',...
% % % % %             vars{v});
       continue;
    end
    
    % Take the first sensor found in the Dbd instance that satisfies the
    % mapping
    [Y,I] = min(AI);
    sensorStruct(end).sensor = C{I};
    
end

% Create the profile data strcuture that will be used to write data to the
% NetCDF file
VAR_STRUCT = struct('ncVarName', '',...
    'sensor', '',...
    'data', []);
META_STRUCT = struct('glider', '',...
    'startDatenum', NaN,...
    'endDatenum', NaN,...
    'lonLat', []);
ncStruct(length(pStruct)).profile_id = NaN;
ncStruct(length(pStruct)).meta = META_STRUCT;
ncStruct(length(pStruct)).vars = VAR_STRUCT;

% Loop through the profiles data structure and add the appropriate data
for p = 1:length(pStruct)
    
    ncStruct(p).profile_id = p;
    ncStruct(p).meta = META_STRUCT;
    ncStruct(p).vars = VAR_STRUCT;
    
    for v = 1:length(sensorStruct)
        
        ncStruct(p).vars(v).ncVarName = sensorStruct(v).ncVarName;
        ncStruct(p).vars(v).sensor = sensorStruct(v).sensor;
        if ~isempty(sensorStruct(v).sensor)
            ncStruct(p).vars(v).data = pStruct(p).(sensorStruct(v).sensor);
        end
        
    end
    
    % Get the list of NetCDF variable names for this profile
    ncVars = {ncStruct(p).vars.ncVarName}';
    
    % Set up the scalar variable data
    % profile_id
    [~,I] = ismember('profile_id', ncVars);
    ncStruct(p).vars(I).data = p;
    
    % profile_time
    [~,I] = ismember('profile_time', ncVars);
    ncStruct(p).vars(I).data =...
        datenum2epoch(mean([pStruct(p).meta.startDatenum pStruct(p).meta.endDatenum]));
    
    % profile_lat
    [~,I] = ismember('profile_lat', ncVars);
    ncStruct(p).vars(I).data = pStruct(p).meta.lonLat(2);
    
    % profile_lon
    [~,I] = ismember('profile_lon', ncVars);
    ncStruct(p).vars(I).data = pStruct(p).meta.lonLat(1);
    
    % trajectory 
    [~,I] = ismember('trajectory', ncVars);
    ncStruct(p).vars(I).data = sprintf('%s-%s',...
        pStruct(p).meta.glider,...
        datestr(trajectoryTs, 'yyyymmddTHHMM'));
    
    % Add the metadata field for this profile
    ncStruct(p).meta = pStruct(p).meta;
    
end
    