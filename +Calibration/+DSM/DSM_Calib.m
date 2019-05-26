function dsmregs = DSM_Calib(hw,fprintff,calibParams,runParams)
    [path_spherical, angxRawZOVec , angyRawZOVec, dsmregs_current, sz] = DSM_Calib_init(hw,calibParams,runParams);
    [~ , DSM_data ,angxZO ,angyZO]  = DSM_Calib_Calc(path_spherical, sz , angxRawZOVec , angyRawZOVec ,dsmregs_current ,calibParams);
    dsmregs     = DSM_Calib_Output(hw,fprintff,DSM_data,angxZO ,angyZO , runParams); 
    % matlab GUI
    
end

function dsmregs = DSM_Calib_Output(hw,fprintff,DSM_data,angxZO,angyZO,runParams)
    verbose = runParams.verbose;
    sz = hw.streamSize();
%% matlab only
    d_pre       = hw.getFrame(30); %should be out of verbose so it will always happen (for log)
%% 
% calibration structure 
    dsmregs.EXTL.dsmXscale  = DSM_data.dsmXscale;
    dsmregs.EXTL.dsmXoffset = DSM_data.dsmXoffset;
    dsmregs.EXTL.dsmYscale  = DSM_data.dsmYscale;
    dsmregs.EXTL.dsmYoffset = DSM_data.dsmYoffset;

% converet DSM_data to register set
    hw.setReg('EXTLdsmXscale' ,dsmregs.EXTL.dsmXscale);
    hw.setReg('EXTLdsmYscale' ,dsmregs.EXTL.dsmYscale);
    hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
    hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
    hw.shadowUpdate();
    pause(0.1);
%% matlab only
    d_post=hw.getFrame(30); %should be out of verbose so it will always happen (for log)

    if(verbose)
        ff=Calibration.aux.invisibleFigure();
        pre_contour=(d_pre.i>0)-imerode(d_pre.i>0,ones(5));
        imagesc(cat(3,pre_contour,pre_contour*0,pre_contour*0));

        title('Spherical Validity before (r) and after (g) DSM Calib')

        colZO = (1 + angxZO/2047)/2*(double(sz(2))-1)+1;
        rowZO = (1 + angyZO/2047)/2*(double(sz(1))-1)+1;
        hold on;
        plot( colZO,rowZO,'-s','MarkerSize',10,...
            'MarkerEdgeColor','red',...
            'MarkerFaceColor',[1 .6 .6]);

        txt1 = ['\leftarrow' sprintf(' Zero Order Angles=[%.0f,%.0f]',angxZO,angyZO)];
        text(double(colZO),double(rowZO),txt1)


        post_contour=(d_post.i>0)-imerode(d_post.i>0,ones(5));
        imagesc(cat(3,post_contour*0,post_contour,post_contour*0));



        Calibration.aux.saveFigureAsImage(ff,runParams,'DSM','Spherical_Validity');
    end
    [~,st]      = maxAreaStat(d_post.i>0,size(d_post.i>0));
    colxMinMax  = [st.BoundingBox(1)+0.5, st.BoundingBox(1)+st.BoundingBox(3)-0.5];
    rowyMinMax  = [st.BoundingBox(2)+0.5, st.BoundingBox(2)+st.BoundingBox(4)-0.5];
    angxMinMax  = round((colxMinMax-1)/(double(sz(2))-1)*2047*2-2047);
    angyMinMax  = round((rowyMinMax-1)/(double(sz(1))-1)*2047*2-2047);
    fprintff('DSM: minAngX=%d, maxAngX=%d, minAngY=%d, maxAngY=%d.\n',angxMinMax(1),angxMinMax(2),angyMinMax(1),angyMinMax(2));   
%% 
    % Return to regular coordiantes
    hw.setReg('DIGGsphericalEn',false);
    % Shadow update:
    hw.shadowUpdate();

end

function [path_spherical, angxRawVec ,angyRawVec ,dsmregs, sz] = DSM_Calib_init(hw,calibParams,runParams)
%%  prepare angxRawVec angyRawVec
    nSamples = calibParams.dsm.nSamples;
    StopMirrorInRestAngle(hw);
    [angxRawVec, angyRawVec] = Calibration.DSM.memsRawData(hw,nSamples);
    RestartMirror(hw,runParams);
%%  save spherical images in dir
    % Set spherical:
    hw.setReg('DIGGsphericalEn',true);
    % Shadow update:
    hw.shadowUpdate();
    pause(0.1);
    NumberOfFrames = calibParams.gnrl.Nof2avg; % should be 30
    path_spherical = fullfile(tempdir,'DSM_spherical');
    Calibration.aux.SaveFramesWrapper(hw ,'I',NumberOfFrames,path_spherical); % get frame without post processing (averege) (SDK like)
%%  read DSM scale / offset 
    dsmregs.Xscale = typecast(hw.read('EXTLdsmXscale'),'single');
    dsmregs.Yscale = typecast(hw.read('EXTLdsmYscale'),'single');
    dsmregs.Xoffset= typecast(hw.read('EXTLdsmXoffset'),'single');
    dsmregs.Yoffset= typecast(hw.read('EXTLdsmYoffset'),'single');

    sz = hw.streamSize();
end


function StopMirrorInRestAngle(hw)
%%  stopping mirror  
    % % Enable the MC - Enable_MEMS_Driver
    % hw.cmd('execute_table 140');
    % % Enable the logger
    % hw.cmd('mclog 01000000 43 13000 1');
   
    hw.stopStream;
    pause(3);
    hw.cmd('exec_table 140');% setRestAngle
    pause(0.5);
    % assert(res.IsCompletedOk, 'For DSM calib to work, it should be the first thing that happens after connecting the USB. Before any capturing.' )
end

function RestartMirror(hw,runParams)
    % % Disable MC - Disable_MEMS_Driver
    hw.runPresetScript('resetRestAngle');
    % hw.runPresetScript('maRestart');
    % hw.runPresetScript('systemConfig');
    Calibration.aux.startHwStream(hw,runParams);
end

function [binIm1stat,stat] = maxAreaStat(binaryIm,sz)
st = regionprops(binaryIm);
for i = 1:numel(st)
%     hold on
%     rectangle('Position',[st(i).BoundingBox(1),st(i).BoundingBox(2),st(i).BoundingBox(3),st(i).BoundingBox(4)],...
%         'EdgeColor','r','LineWidth',2 )
    area(i) = st(i).BoundingBox(3)*st(i).BoundingBox(4)/(prod(sz));
end
[m,mI] = max(area);
if m < 0.8
    warning('Largest connected region in image covers only %2.2g of the image.',m);
end
stat = st(mI);
% Remove the smaller stats from the image
binIm1stat = binaryIm;
for i = 1:numel(st)
    if i~=mI
       iC = ceil(st(i).BoundingBox(1)):floor(st(i).BoundingBox(1)+st(i).BoundingBox(3));
       iR = ceil(st(i).BoundingBox(2)):floor(st(i).BoundingBox(2)+st(i).BoundingBox(4));
       binIm1stat(iR,iC) = 0;
    end
end

end
