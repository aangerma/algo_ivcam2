function [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn)

if(isempty(g_output_dir))
    output_dir = fullfile(ivcam2tempdir, func_name);
else
    output_dir = g_output_dir;
end

fid = -1;
if(isempty(g_fprintff)) %% HVM log file
    if(isempty(g_LogFn))
        fn = fullfile(output_dir,[func_name '_log.txt']);
    else
        fn = g_LogFn;
    end
    mkdirSafe(output_dir);
    fid = fopen(fn,'a');
    fprintff = @(varargin) fprintf(fid,varargin{:});
else % algo_cal app_windows
    fprintff = g_fprintff;
end

end