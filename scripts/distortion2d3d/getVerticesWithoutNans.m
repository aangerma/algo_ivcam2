function [rows,cols,vNoNans] = getVerticesWithoutNans(v,checkerSize)
vInternal = reshape(v,checkerSize);
cols = any(~isnan(vInternal(:,:,1)),1);
rows = any(~isnan(vInternal(:,:,1)),2);
vTemp = vInternal(rows,cols,:);
vNoNans = reshape(vTemp,[],3);
if ~any(isnan(vTemp(:,:,1)),'all') %Fix in case of cropped
    return;
end
nanDisp = isnan(vTemp(:,:,1));
colsNew1 = sum(nanDisp,1) < size(vTemp,1)/2;
rowsNew1 = sum(nanDisp,2) < size(vTemp,2)/2;
vTemp = vTemp(rowsNew1,colsNew1,:);
cols(cols) = colsNew1;
rows(rows) = rowsNew1;
if any(isnan(vTemp(:,:,1)),'all')
    rowsNew2 = true(size(vTemp,1),1);
    colsNew2 = true(1,size(vTemp,2));
    for iRows = 1:size(vTemp,1)/2
        if any(isnan(vTemp(iRows,:,1)))
            rowsNew2(iRows,1) = false;
        end
        if any(isnan(vTemp(end-iRows+1,:,1)))
            rowsNew2(end-iRows+1,1) = false;
        end
        if rowsNew2(iRows,1) && rowsNew2(end-iRows+1,1)
            break;
        end
    end
    for iCols = 1:size(vTemp,2)/2
        if any(isnan(vTemp(:,iCols,1)))
            colsNew2(1,iRows) = false;
        end
        if any(isnan(vTemp(:,end-iCols+1,1)))
            colsNew2(1,end-iCols+1) = false;
        end
        if colsNew2(1,iRows) && colsNew2(1,end-iCols+1)
            break;
        end
    end
    vTemp = vTemp(rowsNew2,colsNew2,:);
    cols(cols) = colsNew2;
    rows(rows) = rowsNew2;
    %     sumNotNanInRow = sum(~isnan(vTemp(:,:,1)),2);
    %     [binCounts,~] = histcounts(sumNotNanInRow, max(sumNotNanInRow)-min(sumNotNanInRow)+1);
    %     [ixRow, ~] = max(binCounts);
    %     rowsNew = sumNotNanInRow >= sumNotNanInRow(ixRow);
    %     sumNotNanInCol = sum(~isnan(vTemp(:,:,1)),1);
    %     [binCounts,~] = histcounts(sumNotNanInCol, max(sumNotNanInCol)-min(sumNotNanInCol)+1);
    %     [ixCol, ~] = max(binCounts);
    %     colsNew = sumNotNanInCol >= sumNotNanInCol(ixCol);
    
end

vNoNans = reshape(vTemp,[],3);
if any(isnan(vNoNans(:,:,1)),'all')
    disp('debug');
end
end