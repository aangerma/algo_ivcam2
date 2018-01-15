function [shiftedData] = shiftColumnsByNum(data,index)
dataRep = repmat(data,2,1);
oldIndices = 1:size(dataRep,1);
newIndices = (1:size(data,1))+index;
shiftedData = interp1(oldIndices,dataRep,newIndices); 
end

