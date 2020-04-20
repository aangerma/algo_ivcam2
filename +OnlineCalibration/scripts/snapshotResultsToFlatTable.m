clear
resultsfn = 'C:\source\algo_ivcam2\+OnlineCalibration\tests\resultsArrayWithKdepthAndRotConstantW_23-Mar-2020.mat';
tablefn = strrep(resultsfn,'.mat','_table_and_params.mat');
load(resultsfn);

% resultsArray{1}

for i = 1:numel(resultsArray)
   res = resultsArray{i};
   if numel(fieldnames(res))<3
       flatRes = copyWithNans(res,resArr(1));
   else
       res.depthRes = sprintf('%dx%d',res.originalParams.depthRes);
       res.rgbRes = sprintf('%dx%d',res.originalParams.rgbRes);
       res.presetNum = contains(res.sceneFullPath,'LongRange');
       
       res = rmfield(res,'originalParams');
       if ~isfield(res.validScene,'isValid')
           res.validScene.isValid = 1;
       end
       res.validOutput = rmfield(res.validOutput,'newParams');
       flatRes = flattenStruct2levels(res);
       if ~isfield(flatRes,'errorMessage')
           flatRes.errorMessage = '';
       end
       
   end
   resArr(i) = flatRes;
end
% writetable(struct2table(resArr),tablefn);

resT = struct2table(resArr);
testParams = resultsArray{1}.originalParams; 
save(tablefn,'resT','testParams');

function flat = copyWithNans(res,ex)
fnamesRef = fieldnames(ex);
for i = 1:numel(fnamesRef)
    if ~isfield(res,fnamesRef{i})
        flat.(fnamesRef{i}) = nan;
    else
        flat.(fnamesRef{i}) = res.(fnamesRef{i});
    end
end
end
function flat = flattenStruct2levels(st)

fnames = fieldnames(st);
for i = 1:numel(fnames)
    val = st.(fnames{i});
    if ~isstruct(st.(fnames{i}))  
        flat.(fnames{i}) = val;
        if val == inf
            flat.(fnames{i}) = nan;
        end
    else
        subfnames = fieldnames(val);
        for j = 1:numel(subfnames)
            flat.([fnames{i},'_',subfnames{j}]) = val.(subfnames{j});
        end
        
    end
end


end