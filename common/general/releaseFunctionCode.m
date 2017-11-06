function [ success ] = releaseFunctionCode(fn,outFolder,isFlatten)
    %RELEASEFUNCTIONCODE copy all the source code the function fn is using into outFolder.
    %   fn - the function name
    %   outFolder - the output folder for the code.
    %   isFlatten - optional parameter to indicate whether to flatten the
    %       folders structure or not (default is true)
    %   success - indication if the procedure suceeded
    if ~exist('fn','var') || ~exist('outFolder','var')
        error('Function Name and Output Folder Must Be Set');
    end
    
    if ~exist('isFlatten','var')
        isFlatten = true;
    end
    
    try
        srcs = functionDependencyWalker(which(fn),false);
        if isFlatten
            dest = cell(length(srcs),1);
            for i=1:length(srcs)
                minCharIdx = min([strfind(srcs{i},'+'),strfind(srcs{i},'@')]);
                if isempty(minCharIdx)
                    [~,flatPath,ext] = fileparts(srcs{i});
                    flatPath = [flatPath ext]; %#ok<AGROW>
                else
                    flatPath = srcs{i}(minCharIdx:end);
                end
                dest{i} = fullfile(outFolder,flatPath);
            end
        else
            [~, stripped] = prefix(srcs);
            dest = fullfile(outFolder,stripped);
        end
        
        mkdir(outFolder);
        for i=1:length(srcs)
            dname = fileparts(dest{i});
            if ~exist(dname,'dir')
                mkdir(dname);
            end
            copyfile(srcs{i},dest{i},'f');
        end
        
        success = 1;
    catch
        success = 0;
    end
end

