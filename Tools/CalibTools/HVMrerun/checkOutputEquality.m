function checkOutputEquality(dataOut, dataRes)

fnames = fieldnames(dataOut);
for iField = 1:length(fnames)
    isTheSame = isequaln(dataOut.(fnames{iField}), dataRes.(fnames{iField}));
    fprintf(', %s reproduced = %d ', fnames{iField}, isTheSame);
end