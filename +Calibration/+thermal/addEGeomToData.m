function [data] = addEGeomToData(data)



for i = 1:numel(data.framesData) 
    v = data.framesData(i).ptsWithZ(:,6:8);
    if size(v,1) == 20*28
        v = reshape(v,20,28,3);
        rows = find(any(~isnan(v(:,:,1)),2));
        cols = find(any(~isnan(v(:,:,1)),1));
        grd = [numel(rows),numel(cols)];
        v = reshape(v(rows,cols,:),[],3);
    else
        grd = [9,13];
    end
    res = Validation.aux.gridError(v, grd, 30);
    data.framesData(i).eGeom = res.absErrorMean;
end

end

