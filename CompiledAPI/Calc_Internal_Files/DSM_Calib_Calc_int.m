function [result, DSM_data,angxZO,angyZO] = DSM_Calib_Calc_int(im, sz , angxRawZOVec , angyRawZOVec ,dsmregs_current ,calibParams,fprintff)
    result = 1;
    margin = calibParams.dsm.margin;
    
    dsmXscale = dsmregs_current.Xscale;
    dsmYscale = dsmregs_current.Yscale;
    dsmXoffset = dsmregs_current.Xoffset;
    dsmYoffset = dsmregs_current.Yoffset;
    width = sz(2);
    height = sz(1);
    IR_image = Calibration.aux.average_images(im);
    if calibParams.dsm.useCenterOfProjection
        
        [angxZO,angyZO] = centerProjectZO(IR_image,sz);
        angxRawZO = invertDSM(angxZO,dsmXscale,dsmXoffset);
        angyRawZO = invertDSM(angyZO,dsmYscale,dsmYoffset);
    else
        
        
        angxRawZO = median(angxRawZOVec);
        angyRawZO = median(angyRawZOVec);
        if 0 % display
            runParams.outputFolder = output_dir;
            ff=Calibration.aux.invisibleFigure();
            plot(angxRawZOVec,angyRawZOVec,'r*');
            
            xlabel('x angle raw');
            ylabel('y angle raw');
            hold on
            plot(angxRawZO,angyRawZO,'b*')
            title(sprintf('Rest Angle Measurements [%.2g,%.2g]',angxRawZO,angyRawZO));
            
            Calibration.aux.saveFigureAsImage(ff,runParams,'DSM','Rest_Angle');
            fprintff('DSM: Rest Angle Measurements [%.2g,%.2g], Std: [%.2g,%.2g]\n ',angxRawZO,angyRawZO,std(angxRawZOVec),std(angyRawZOVec));
        end
        restFailed = (angxRawZO == 0 && angyRawZO == 0); % We don't really have the resting angle...
        
        angxZO = (angxRawZO+dsmXoffset)*dsmXscale - 2047;
        angyZO = (angyRawZO+dsmYoffset)*dsmYscale - 2047;
        
        if restFailed
            % todo log
            result = -1;
            fprintff('Raw rest angle is zero. This is not likely. setRestAngle script failed.')
        end
    end
    %    [angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO);
    [angmin,angmax] = minAndMaxAngs_calc(IR_image, angxZO,angyZO, width, height);
    % Calulcate raw angx/y of the edges:
    angx = [angmin(1);angmax(1)];
    angy = [angmin(2);angmax(2)];
    
    angxRaw = invertDSM(angx,dsmXscale,dsmXoffset);
    angyRaw = invertDSM(angy,dsmYscale,dsmYoffset);
    
    [DSM_data.dsmXscale,DSM_data.dsmXoffset] = calcDSMScaleAndOffset(angxRawZO,angxRaw,margin,'x');
    [DSM_data.dsmYscale,DSM_data.dsmYoffset] = calcDSMScaleAndOffset(angyRawZO,angyRaw,margin,'y');
end


function [angxZO,angyZO] = centerProjectZO(irImage,sz)
    valid = irImage>0;
    rowsVal = sum(valid,2)>0;
    rowC = uint16(0.5*(find(rowsVal,1,'first')+find(rowsVal,1,'last')));
    colsVal = sum(valid,1)>0;
    colC = uint16(0.5*(find(colsVal,1,'first')+find(colsVal,1,'last')));
    
    rowZO = single(0.5*(find(valid(:,colC),1,'first')+find(valid(:,colC),1,'last')));
    colZO = single(0.5*(find(valid(rowC,:),1,'first')+find(valid(rowC,:),1,'last')));
    
    angxZO = ((colZO-1)*2/(double(sz(2))-1)-1)*2047;
    angyZO = ((rowZO-1)*2/(double(sz(1))-1)-1)*2047;
end


function [angmin,angmax] = minAndMaxAngs_calc(IR_image, angxZO,angyZO, width, hight)
    % Get the column and row of the zero order in spherical:
    axDim = double([width , hight]);
    
    colZO = uint16(round((1 + angxZO/2047)/2*(axDim(1)-1)+1));
    rowZO = uint16(round((1 + angyZO/2047)/2*(axDim(2)-1)+1));
    
    % Y min angle shouldn't exceed -2047. Y Max angle can exceed. We wish that the column of the zero
    % order won't exceed 2047.
    % X angles can exceed. [-fovx,0] and [+fovx,0] are mapped to the edges of
    % the image. So, it makes sense to look only at the middle line (line of the ZO) when
    % handling x.
    
    
    for ax = 1:2
        if ax == 1
            vCenter =  IR_image(rowZO,:) > 0;
            angmin(ax) = ((find(sum(vCenter,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
        else
            vAll =  IR_image > 0;
            vCenter =  IR_image(:,colZO) > 0;
            angmin(ax) = ((find(sum(vAll,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
        end
        angmax(ax) = ((find(sum(vCenter,ax),1,'last' ))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
    end
end

function [angRaw] = invertDSM(ang,scale,offset)
    angRaw = (ang+2047)/scale - offset;
end

function [scale,offset] = calcDSMScaleAndOffset(ang2zero,angRaw,margin,axis)
    % Find the angle in angRaw that should be mapped to 2047. It is the ang
    % that is the furthest from the zero order.
    [diff,i] = max(abs(angRaw-ang2zero));
    angEdge = angRaw(i);
    edgeTarget = 2047;
    
    if i == 1
        if axis == 'x'
            % Transform angEdge to -2047 and ang2zero to 0.
            offset = single(-angEdge);
            scale = single(edgeTarget/single(diff));
        elseif axis == 'y'
            % Transform angEdge to -2047+margin and ang2zero to 0.
            offset = single( (edgeTarget/margin*angEdge-ang2zero)/(1-edgeTarget/margin));
            scale = single((edgeTarget-margin)/(ang2zero-angEdge));
        end
    else
        % Transform angEdge to +2047 and ang2zero to 0.
        offset = single(-ang2zero+diff);
        scale = single(edgeTarget/single(diff));
    end
end
