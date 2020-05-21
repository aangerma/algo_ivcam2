function [isEqual] = compareStructs2Level(struct1,struct2,reportPath)
isEqual = true;

if isequaln(struct1,struct2)
    return;
end
fnames = fieldnames(struct1);
fileID = fopen(fullfile(reportPath),'w');
for iField =1:numel(fnames)
    isTheSame = isequaln(struct1.(fnames{iField}), struct2.(fnames{iField}));
    isEqual = isEqual & isTheSame;
    fprintf(fileID,'%s  %d\n',fnames{iField}, isTheSame);
    if ~ isTheSame && isstruct(struct1.(fnames{iField}))
        fnamesInner = fieldnames(struct1.(fnames{iField}));
        for iFieldInner =1:numel(fnamesInner)
            isTheSameInner = isequaln(struct1.(fnames{iField}).(fnamesInner{iFieldInner}), struct2.(fnames{iField}).(fnamesInner{iFieldInner}));
            fprintf(fileID,'        %s  %d\n',fnamesInner{iFieldInner}, isTheSameInner);
        end
    end
end
fclose(fileID);

end

