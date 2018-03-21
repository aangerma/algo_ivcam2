function  captureForRx(hw, folder)

mkdirSafe(folder);

hw.setReg('JFILbypass',true);
hw.setReg('JFILbypassIr2Conf',true);
hw.shadowUpdate();

NT = 15;

Depths = {};
IRs = {};

iCapture = 1;
while (true)
    showTarget(hw);
    
    frame = hw.getFrame();
    
    depths = zeros([NT size(frame.d)], 'uint16');
    irs = zeros([NT size(frame.d)], 'uint16');
    for i=1:NT
        frame = hw.getFrame();
        ir12 = uint16(frame.i) + bitshift(uint16(frame.c),8);
        irs(i,:,:) = fillHolesMM(ir12);
        depths(i,:,:) = fillHolesMM(frame.d);
    end
    
    depth = median(depths, 1);
    ir = median(irs, 1);
    
    irFilename = sprintf('frame_%03d.bini', iCapture);
    irFullpath = fullfile(folder, filesep, irFilename);
    io.writeBin(irFullpath, ir);

    dFilename = sprintf('frame_%03d.binz', iCapture);
    irFullpath = fullfile(folder, filesep, dFilename);
    io.writeBin(irFullpath, depth);
    
    Depths{iCapture} = depth;
    IRs{iCapture} = ir;
    save(fullfile(folder, filesep, 'captures.mat'), 'Depths', 'IRs');
    
    iCapture = iCapture + 1;
end

end

function  showTarget(hw)

f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
%maximizeFig(f); 
axis image; axis off;
colormap(gray(256));
title('Adjust circle to the required position');

while(ishandle(f) && get(f,'userdata')==0)
    frame = hw.getFrame();
    imagesc(frame.i);
    hold on;
    pos = [310 230 20 20]; 
    rectangle('Position',pos,'Curvature',[1 1], 'EdgeColor','r');
    axis equal
    drawnow;
end

close(f);

end

