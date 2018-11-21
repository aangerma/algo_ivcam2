function [base_name] = FG_record(path,num_frames,res,pos)
    %clear all;
     hw = HWinterface;
    % folder to save the recorded data
    % path = 'C:\Users\tbenshab\Desktop\FG_recording';
    if ~exist(path,'dir')
        mkdir(path);
    end
    if ~exist('res','var')
        res = [720 1280];
    end
    if ~exist('pos','var')
        pos.left = 0;
        pos.top = 0;
    end

    % initiate and "warm up" the unit so setReg and
    % runScript commands take effect
    hw.FG_getFrame(100,res,pos);
    base_name = sprintf('FG_%dx%d_L%d_T%d_',res(1),res(2),pos.left, pos.top);
%    base_name = strcat('fg_',int2str(res(1)),'x',int2str(res(2)))    
%    base_name = strcat(base_name,int2str(res(1)),'x',int2str(res(2)))    
    for i=1:num_frames
        frame = hw.FG_getFrame(1,res,pos);
        name = strcat(base_name, int2str(i),'.bin');
        fn = fullfile(path,name);
        fid = fopen(fn,'w');
        fwrite(fid,frame.fg,'uint8');
        fclose(fid);
    end
end
   
 
 
 
