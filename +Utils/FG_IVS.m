function [ ivs_arr ] = FG_IVS( output_dir,num_frames,res,p)
%    output_dir = 'C:\Users\tbenshab\Desktop\FG_recording1';
    if ~exist('res','var')
        res = [720 1280];
    end
    if ~exist('p','var')
        pos.left = 0;
        pos.top = 0;
    else if (isstruct(p)& isfield(p,'left')&& isfield(p,'top')) 
            pos.left = min(max(p.left,0),100);
            pos.top = min(max(p.top,0),100);
        else
            pos.left = 0;
            pos.top = 0;
        end
    end
    [base_name] = Utils.FG_record(output_dir,num_frames,res,pos);
    conf_fn = fullfile(output_dir, base_name );
    Utils.GetDevConfig(conf_fn);
    ivs_arr = io.FG.USBreadFrames(output_dir,'numFrames',num_frames);
    
    for i=1:1:size(ivs_arr,1)
        fn = strcat(base_name,int2str(i),'.ivs');
        full_fn = fullfile(output_dir, fn );
        io.writeIVS(full_fn, ivs_arr(i));
    end
end


