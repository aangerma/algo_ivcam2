function logResults(results,runParams,fname)
    if ~exist('fname','var')
        fname = 'results.txt';
    end
    fullPath = fullfile(runParams.outputFolder,fname);
    fid = fopen(fullPath,'wt');
    fprintf(fid, struct2str(results));
    fclose(fid);
end 