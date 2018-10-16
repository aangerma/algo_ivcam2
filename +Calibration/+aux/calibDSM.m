function [dsmregs] = calibDSM(hw,fw,params,fprintff,verbose)
    %CALIBDSM find DSM scale and offset such that:
    % 1. The zero order reported angles are: [angx,angy] =[0,0]
    % 2. The range of angles cover as much as possible.
    
    
    % Start by setting  my own DSM values. This make sure none of the angles
    % are saturated.
    
    regs = fw.get();
    margin = params.dsm.margin;
    
    [angxRawZO,angyRawZO,restFailed] = zeroOrderAngles(hw);
    
    dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
    dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
    dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
    dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');
    hw.shadowUpdate();
    % Turn to spherical, and see the minimal and maximal angles we get per
    % axis.
    angxZO = (angxRawZO+dsmXoffset)*dsmXscale - 2047;
    angyZO = (angyRawZO+dsmYoffset)*dsmYscale - 2047;
    
    if restFailed
        warning('Raw rest angle is zero. This is not likely. setRestAngle script failed.')
        [angxZO,angyZO] = centerProjectZO(hw,regs);
        angxRawZO = invertDSM(angxZO,dsmXscale,dsmXoffset);
        angyRawZO = invertDSM(angyZO,dsmYscale,dsmYoffset);
    end
    % Set spherical:
    hw.setReg('DIGGsphericalEn',true);
    % Shadow update:
    hw.shadowUpdate();
    d_pre = hw.getFrame(30); %should be out of verbose so it will always happen (for log)
    if(verbose)
        ff=figure(sum(mfilename));
        pre_contour=(d_pre.i>0)-imerode(d_pre.i>0,ones(5));
        imagesc(cat(3,pre_contour,pre_contour*0,pre_contour*0));
      
        title('Spherical Validity Before DSM Calib')
        
        colZO = (1 + angxZO/2047)/2*(double(regs.GNRL.imgHsize)-1)+1;
        rowZO = (1 + angyZO/2047)/2*(double(regs.GNRL.imgVsize)-1)+1;
        hold on;
        plot( colZO,rowZO,'-s','MarkerSize',10,...
            'MarkerEdgeColor','red',...
            'MarkerFaceColor',[1 .6 .6]);
        
        txt1 = ['\leftarrow' sprintf(' Zero Order Angles=[%.0f,%.0f]',angxZO,angyZO)];
        text(double(colZO),double(rowZO),txt1)
    end
    
    
    
    
    [angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO,regs);
    % Calulcate raw angx/y of the edges:
    angx = [angmin(1);angmax(1)];
    angy = [angmin(2);angmax(2)];
    
    angxRaw = invertDSM(angx,dsmXscale,dsmXoffset);
    angyRaw = invertDSM(angy,dsmYscale,dsmYoffset);
    
    [dsmregs.EXTL.dsmXscale,dsmregs.EXTL.dsmXoffset] = calcDSMScaleAndOffset(angxRawZO,angxRaw,margin,'x');
    [dsmregs.EXTL.dsmYscale,dsmregs.EXTL.dsmYoffset] = calcDSMScaleAndOffset(angyRawZO,angyRaw,margin,'y');
    
    % Update DSM
    hw.setReg('EXTLdsmXscale',dsmregs.EXTL.dsmXscale);
    hw.setReg('EXTLdsmYscale',dsmregs.EXTL.dsmYscale);
    hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
    hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
    hw.shadowUpdate();
    d_post=hw.getFrame(30); %should be out of verbose so it will always happen (for log)
    
    if(verbose)
        post_contour=(d_post.i>0)-imerode(d_post.i>0,ones(5));
        imagesc(cat(3,pre_contour,post_contour,post_contour*0));
        title('Spherical Validity After DSM Calib')
        axis image;
        drawnow;
        pause(1);
        close(ff);
    end
    
    
    
    
    st = regionprops(d_post.i>0, 'BoundingBox' );
    colxMinMax = [st.BoundingBox(1)+0.5, st.BoundingBox(1)+st.BoundingBox(3)-0.5];
    rowyMinMax = [st.BoundingBox(2)+0.5, st.BoundingBox(2)+st.BoundingBox(4)-0.5];
    angxMinMax = round((colxMinMax-1)/(double(regs.GNRL.imgHsize)-1)*2047*2-2047);
    angyMinMax = round((rowyMinMax-1)/(double(regs.GNRL.imgVsize)-1)*2047*2-2047);
    fprintff('DSM: minAngX=%d, maxAngX=%d, minAngY=%d, maxAngY=%d.\n',angxMinMax(1),angxMinMax(2),angyMinMax(1),angyMinMax(2));   
    
    % Return to regular coordiantes
    hw.setReg('DIGGsphericalEn',false);
    % Shadow update:
    hw.shadowUpdate();
end

function [angxZO,angyZO] = centerProjectZO(hw,regs)
    % Set spherical:
    hw.setReg('DIGGsphericalEn',true);
    % Shadow update:
    hw.shadowUpdate();
    d = hw.getFrame(30);
    valid = d.i>0;
    rowsVal = sum(valid,2)>0;
    rowC = uint16(0.5*(find(rowsVal,1,'first')+find(rowsVal,1,'last')));
    colsVal = sum(valid,1)>0;
    colC = uint16(0.5*(find(colsVal,1,'first')+find(colsVal,1,'last')));
    
    rowZO = single(0.5*(find(valid(:,colC),1,'first')+find(valid(:,colC),1,'last')));
    colZO = single(0.5*(find(valid(rowC,:),1,'first')+find(valid(rowC,:),1,'last')));
    
    angxZO = ((colZO-1)*2/(double(regs.GNRL.imgHsize)-1)-1)*2047;
    angyZO = ((rowZO-1)*2/(double(regs.GNRL.imgVHsize)-1)-1)*2047;
    
    
    % Undo spherical:
    hw.setReg('DIGGsphericalEn',false);
    % Shadow update:
    hw.shadowUpdate();
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
function [angRaw] = invertDSM(ang,scale,offset)
    angRaw = (ang+2047)/scale - offset;
end
function [angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO,regs)
    % Get the column and row of the zero order in spherical:
    axDim = [double(regs.GNRL.imgHsize),double(regs.GNRL.imgVsize)];
    
    
    % Get a sample image:
    hw.runPresetScript('startStream');
    d = hw.getFrame(30);
    colZO = uint16(round((1 + angxZO/2047)/2*(axDim(1)-1)+1));
    rowZO = uint16(round((1 + angyZO/2047)/2*(axDim(2)-1)+1));
   
    % Y min angle shouldn't exceed -2047. Y Max angle can exceed. We wish that the column of the zero
    % order won't exceed 2047.
    % X angles can exceed. [-fovx,0] and [+fovx,0] are mapped to the edges of
    % the image. So, it makes sense to look only at the middle line (line of the ZO) when
    % handling x.
    
        
    for ax = 1:2
        if ax == 1
            vCenter =  d.i(rowZO,:) > 0;
            angmin(ax) = ((find(sum(vCenter,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
        else
            vAll =  d.i > 0;
            vCenter =  d.i(:,colZO) > 0;
            angmin(ax) = ((find(sum(vAll,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
        end
        angmax(ax) = ((find(sum(vCenter,ax),1,'last' ))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
    end
    
    
    
end

function [angxRaw,angyRaw,restFailed] = zeroOrderAngles(hw)
    % % Enable the MC - Enable_MEMS_Driver
    % hw.cmd('execute_table 140');
    % % Enable the logger
    % hw.cmd('mclog 01000000 43 13000 1');
    
    hw.runPresetScript('stopStream');
    hw.cmd('exec_table 140');% setRestAngle
    % assert(res.IsCompletedOk, 'For DSM calib to work, it should be the first thing that happens after connecting the USB. Before any capturing.' )
    
    

    %  Notes:
    %   - Signal is noisy due to ADC noise, multiple reads should be performed together with averaging
    %   - Signal is the PZR voltage before the DSM scale and offset
    hw.cmd('mwd fffe2cf4 fffe2cf8 40');
    hw.cmd('mwd fffe2cf4 fffe2cf8 00');
    for i = 1:100
        hw.cmd('mwd fffe2cf4 fffe2cf8 40');
        %  Read FA (float, 32 bits)
        [~,FA] = hw.cmd('mrd fffe882C fffe8830');
        angyRaw(i) = typecast(FA,'single');
        % Read SA (float, 32 bits)
        [~,SA] = hw.cmd('mrd fffe880C fffe8810');
        angxRaw(i) = typecast(SA,'single');
        hw.cmd('mwd fffe2cf4 fffe2cf8 00');
        
    end
    angxRaw = mean(angxRaw);
    angyRaw = mean(angyRaw);
    
    % % Disable MC - Disable_MEMS_Driver
    hw.runPresetScript('resetRestAngle');
    % hw.runPresetScript('maRestart');
    % hw.runPresetScript('systemConfig');
    
    hw.cmd('exec_table 140//enable mems drive');
    hw.cmd('exec_table 141//enable mems');
    hw.cmd('exec_table 142//enable FB');
    hw.runPresetScript('startStream');
    restFailed = (angxRaw == 0 && angyRaw == 0); % We don't really have the resting angle...
    %     warning('Raw rest angle is zero... This is not likely. Probably setRestAngle script failed.');
    
end