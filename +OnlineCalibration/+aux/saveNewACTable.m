function [tablefn] = saveNewACTable(newAcDataTable,acTableHeadDir)
id = 0;
acTableDir = fullfile(acTableHeadDir,sprintf('acTable_%03d',id));
while exist(acTableDir, 'dir')
    id = id + 1;
    acTableDir = fullfile(acTableHeadDir,sprintf('acTable_%03d',id));
end
mkdirSafe(acTableDir);
tablefn = fullfile(acTableDir,'Algo_AutoCalibration_calibInfo_Ver_00_00.bin');

fid = fopen(tablefn,'w');
fwrite(fid,newAcDataTable,'uint8');
fclose(fid);

end

