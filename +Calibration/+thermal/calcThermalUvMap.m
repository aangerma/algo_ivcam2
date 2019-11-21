function [uvResults] = calcThermalUvMap(framesPerTemperature,calibParams,params)

nBins = calibParams.fwTable.nRows;
uvResults = nan(nBins,4);

for k = 1:nBins
    verticesCornersIr = [framesPerTemperature(k,:,6)', framesPerTemperature(k,:,7)', framesPerTemperature(k,:,8)'];
    cornersIr = [framesPerTemperature(k,:,4)', framesPerTemperature(k,:,5)'];
    cornersRGB = [framesPerTemperature(k,:,9)', framesPerTemperature(k,:,10)'];
    if all(isnan(verticesCornersIr(:,1))) || all(isnan(cornersRGB(:,1)))
        continue;
    end
    
    cornersIrRot = reshape(cornersIr,20,28,[]);
    cornersIrRot = reshape(rot90(cornersIrRot,2),[],2);
    cornersIrRot = rotateImPixelsBy180(cornersIrRot,params.depthRes(2),params.depthRes(1));
    verticesCornersIrRot = reshape(verticesCornersIr,20,28,[]);
    verticesCornersIrRot = reshape(rot90(verticesCornersIrRot,2),[],3);
    verticesCornersIrRot(:,1:2) = verticesCornersIrRot(:,1:2)*(-1);
    [~, uvResultsTemp,~] = Validation.aux.uvMappingOnCorners(cornersRGB,cornersIrRot,verticesCornersIrRot,params);
    uvResults(k,1) = uvResultsTemp.rmse;
    uvResults(k,2) = uvResultsTemp.maxErr;
    uvResults(k,3) = uvResultsTemp.maxErr95;
    uvResults(k,4) = uvResultsTemp.minErr;
end

end

function [xyRotated] = rotateImPixelsBy180(xy,imWidth,imHeight)
xyRotated(:,1) = 1 + imWidth - xy(:,1);
xyRotated(:,2) = 1 + imHeight - xy(:,2);
end