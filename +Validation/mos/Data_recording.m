% this script is for recording data in order to optimize mos metric
% this script assumes that the unit is initialized with the default
% register values (if not, disconnect the unit and reconnect)

% function [data, data_JFIL_bypass] = Data_recording()
clear all;
hw = HWinterface;

% folder to save the recorded data
path = 'C:\Users\dshaim\Documents\MATLAB\mos_data_10_03';
if ~exist(path,'dir')
    mkdir(path);
end
% delete previously saved data
if exist([path,'\mos_data.mat'],'file') == 2
    delete([path,'\mos_data.mat']);
end
if exist([path,'\mos_data_JFIL_bypass.mat'],'file') == 2
    delete([path,'\mos_data_JFIL_bypass.mat']);
end

% initiate and "warm up" the unit so setReg and 
% runScript commands take effect
num_frames = 100;
for i=1:num_frames
    frame = hw.getFrame();
end

% set regs with the latest confidence configuration and set the gradient
% filters in JFIL to bypass
hw.runScript('X:\Users\dor\MOS optimization\final_confidence_configuration.txt');
hw.setReg('JFILgrad1bypass',true);
hw.setReg('JFILgrad2bypass',true);
% changing adaptive registers of bilateral filters
% this should be changed after fixing the LUTs
hw.setReg('RASTbiltAdapt$',uint8(0));
hw.setReg('JFILbiltAdaptR',uint8(0));
hw.setReg('JFILbiltAdaptS',uint8(0));
hw.shadowUpdate();

% define values for registers which we optimize over
sort_bypass_mode = [0,4];
JFIL_sharpS_range = [0,1,2,3,4,6,8,12,16,20,24,32,48,63];
JFIL_sharpR_range = [0,1,2,4,8,16,32,48,63];
RAST_sharpS_range = [0,1,2,3,4,6,8,12,16,20,24,32,48,63];
RAST_sharpR_range = [0,1,2,4,8,16,32,48,63];
dim_sizes = [length(sort_bypass_mode), length(JFIL_sharpS_range),...
             length(JFIL_sharpR_range), length(RAST_sharpS_range),...
             length(RAST_sharpR_range)];
tot_elm = prod(dim_sizes);

regs_indices = num2cell(1:5);
[sort_bypass_index, JFIL_sharpS_index, JFIL_sharpR_index,...
        RAST_sharpS_index, RAST_sharpR_index] = deal(regs_indices{:});

% data is the struct where we save all the recordings
data.frames = cell(dim_sizes);
% for each data recording we need to save the K matrix of that unit
data.K = reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
% save in data teh register values as additional field
reg_values.sort_bypass_mode = sort_bypass_mode;
reg_values.JFIL_sharpS_range = JFIL_sharpS_range;
reg_values.JFIL_sharpR_range = JFIL_sharpR_range;
reg_values.RAST_sharpS_range = RAST_sharpS_range;
reg_values.RAST_sharpR_range = RAST_sharpR_range;
data.reg_values = reg_values;
% save approximate distance (in mm) of mos target from camera for this capturing
data.distance = 500;

% data_JFIL_bypass is the struct where 
% we save all the recordings with JFIL bypassed
data_JFIL_bypass.frames = cell(dim_sizes(RAST_sharpS_index:RAST_sharpR_index));
% for each data recording we need to save the K matrix of that unit
data_JFIL_bypass.K = data.K;
% save in data teh register values as additional field
reg_values_JFIL_bypass.RAST_sharpS_range = RAST_sharpS_range;
reg_values_JFIL_bypass.RAST_sharpR_range = RAST_sharpR_range;
data_JFIL_bypass.reg_values = reg_values_JFIL_bypass;
% save approximate distance (in mm) of mos target from camera for this capturing
data_JFIL_bypass.distance = 500;

% initialize indices of 'for' loop with 1 in order to be able
% to compare them on the first iteration in the 'for' loop
constant_one_cell = num2cell(ones([1,5]));
[sort_bypass_ind, JFIL_sharpS_ind, JFIL_sharpR_ind,...
        RAST_sharpS_ind, RAST_sharpR_ind] = deal(constant_one_cell{:});
    
% total_time = 0;
for ind = 1:tot_elm
%     tic;
    % print on screen the number of iteration each 100 iterations
    if mod(ind,100) == 0
        fprintf('starting iteration number: %d\n',ind);
    end
    [sort_bypass_ind_new, JFIL_sharpS_ind_new, JFIL_sharpR_ind_new, ...
        RAST_sharpS_ind_new, RAST_sharpR_ind_new] = ind2sub(dim_sizes,ind);
    if RAST_sharpR_ind_new~=RAST_sharpR_ind || ind==1
        RAST_sharpR_ind = RAST_sharpR_ind_new;
        hw.setReg('RASTbiltSharpnessR',uint8(RAST_sharpR_range(RAST_sharpR_ind)));
    end    
    % if the last 'if' statement got executed, the next 'if' statement 
    % will surely be executed as well because when RAST_sharpR_ind changes
    % RAST_sharpS_ind jumps back to 1
    if RAST_sharpS_ind_new~=RAST_sharpS_ind || ind==1
        RAST_sharpS_ind = RAST_sharpS_ind_new;
        hw.setReg('RASTbiltSharpnessS',uint8(RAST_sharpS_range(RAST_sharpS_ind)));
        hw.setReg('JFILbypass$',true);
        hw.setReg('DIGGgammaScale',int16([256, 256]));
        hw.shadowUpdate();
        frame = hw.getFrame();
        % assigning a frame to JFIL_bypass data
        data_JFIL_bypass.frames{RAST_sharpS_ind,RAST_sharpR_ind}.frame = frame;
        % generate struct for saving the register values
        data_JFIL_bypass.frames{RAST_sharpS_ind,RAST_sharpR_ind}.params = ...
            JFIL_bypass_params(RAST_sharpS_range(RAST_sharpS_ind), ...
                RAST_sharpR_range(RAST_sharpR_ind));
        % setting JFILbypass back to false to capture with JFIL
        hw.setReg('JFILbypass$',false);
        hw.setReg('DIGGgammaScale',int16([1024, 1024]));
    end
    % if one of the above 'if' statements got executed
    % the next if will surely be executed as well because for the same
    % reason as written in the above comment
    if JFIL_sharpR_ind_new~=JFIL_sharpR_ind || ind==1
        JFIL_sharpR_ind = JFIL_sharpR_ind_new;
        hw.setReg('JFILbilt1SharpnessR',uint8(JFIL_sharpR_range(JFIL_sharpR_ind)));
        hw.setReg('JFILbilt2SharpnessR',uint8(JFIL_sharpR_range(JFIL_sharpR_ind)));
        hw.setReg('JFILbilt3SharpnessR',uint8(JFIL_sharpR_range(JFIL_sharpR_ind)));
    end
    % if one of the above 'if' statements got executed
    % the next if will surely be executed as well because for the same
    % reason as written in the above comment
    if JFIL_sharpS_ind_new~=JFIL_sharpS_ind || ind==1
        JFIL_sharpS_ind = JFIL_sharpS_ind_new;       
        hw.setReg('JFILbiltSharpnessS',uint8(JFIL_sharpS_range(JFIL_sharpS_ind)));
    end
    % if one of the above 'if' statements got executed
    % the next if will surely be executed as well because for the same
    % reason as written in the above comment
    if sort_bypass_ind_new~=sort_bypass_ind || ind==1
        sort_bypass_ind = sort_bypass_ind_new;
        hw.setReg('JFILsort1bypassMode',uint8(sort_bypass_mode(sort_bypass_ind)));
        hw.setReg('JFILsort2bypassMode',uint8(sort_bypass_mode(sort_bypass_ind)));
        hw.setReg('JFILsort3bypassMode',uint8(sort_bypass_mode(sort_bypass_ind)));
        hw.shadowUpdate();
    end       
    frame = hw.getFrame();
    % assigning a frame to data
    data.frames{sort_bypass_ind,JFIL_sharpS_ind, ...
        JFIL_sharpR_ind,RAST_sharpS_ind, ...
        RAST_sharpR_ind}.frame = frame;
    % generate struct for saving the register values
    data.frames{sort_bypass_ind,JFIL_sharpS_ind, ...
        JFIL_sharpR_ind,RAST_sharpS_ind, ...
        RAST_sharpR_ind}.params = ...
        create_params_struct(sort_bypass_mode(sort_bypass_ind), ...
            JFIL_sharpS_range(JFIL_sharpS_ind), ...
            JFIL_sharpR_range(JFIL_sharpR_ind), ...
            RAST_sharpS_range(RAST_sharpS_ind), ...
            RAST_sharpR_range(RAST_sharpR_ind));
    % save recorded data each 5K iterations
    if mod(ind,5000) == 0
        save_data(data, data_JFIL_bypass, path);
    end
%     elapsedTime  = toc;
%     total_time = total_time + elapsedTime;
end

disp('finished recording data');
save_data(data, data_JFIL_bypass, path);
        
% fprintf('average loop time: %f seconds\n',total_time/tot_elm);
% end

%% auxilary functions
function params_struct = JFIL_bypass_params(RAST_sharpS,RAST_sharpR)
% this function generate a struct that contain
% the values of the registers (related to mos optimization)
% for JFIL bypass recording

    params_struct.RAST_sharpS = RAST_sharpS;
    params_struct.RAST_sharpR = RAST_sharpR;   
end

function [] = save_data(data, data_JFIL_bypass, path)
% this function saves the recorded data

    tic;
    fprintf('saving recorded data to: %s\n',path);
    save([path,'\mos_data'],'data','-v7.3','-nocompression');
    save([path,'\mos_data_JFIL_bypass'],'data_JFIL_bypass','-v7.3','-nocompression');
    disp('finished saving data');
    toc;
end