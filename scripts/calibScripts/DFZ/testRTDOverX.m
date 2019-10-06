clear
OutputDir = 'C:\temp\unitCalib\Testing';
calpath = {'\\143.185.124.215\shared\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2506\F9280052\Algo1 3.09.0\mat_files';
    '\\143.185.124.215\shared\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2506\F9280058\Algo1 3.09.0\mat_files';
    '\\143.185.124.215\shared\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2506\F9280292\Algo1 3.09.0\mat_files';
    '\\143.185.124.215\shared\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2506\F9280334\Algo1 3.09.0\mat_files';
    '\\143.185.124.215\shared\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2506\F9280379\Algo1 3.09.0\mat_files'};
for i= 1:numel(calpath)
   [results(i),sDelay(i)] = rtdOverXResults( calpath{i} ,OutputDir,5);
end
save resultsWithRTDOverXFixNonSym.mat results sDelay
for i= 1:numel(calpath)
   [results(i),sDelay(i)] = rtdOverXResults( calpath{i} ,OutputDir,0);
end
save resultsWithoutRTDOverXFixNonSym.mat results sDelay