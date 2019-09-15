function SaveFramesWrapper(hw, type , n , path )             % get frame without post processing (averege) (SDK like)
    mkdirSafe(path);
    if (strcmp(type,'ALT_IR')) 
        type = 'I';
    end

    switch type
        case 'I'
            stream = hw.getFrame(n,false);
            for i=1:n
                fn = fullfile(path ,[type sprintf('_%04d.bin',i)]);
                writeAllBytes(stream(i).i(:),fn);
            end
        case 'Z'
            stream = hw.getFrame(n,false);            
            for i=1:n
                fn = fullfile(path ,[type sprintf('_%04d.bin',i)]);
                writeZ(stream(i).z(:),fn);
            end 
        case 'ZI'
            stream = hw.getFrame(n,false);            
            for i=1:n
                mkdirSafe(path);
                fn_I = fullfile(path ,['I' sprintf('_%04d.bin',i)]);
                fn_Z = fullfile(path ,['Z' sprintf('_%04d.bin',i)]);
                writeAllBytes(stream(i).i(:),fn_I);
                writeZ(stream(i).z(:),fn_Z);
            end
        case 'IC'    
            C_image = hw.getColorFrameRAW(1);
            stream  = hw.getFrame(n,false);
            for i=1:n
                mkdirSafe(path);
                fn_I = fullfile(path ,['I' sprintf('_%04d.bin',i)]);
                writeAllBytes(stream(i).i(:),fn_I);
                if(i==1)
                    fn_C = fullfile(path ,['RGB' sprintf('_%04d.bin',i)]);
                    writeZ(C_image(1).color(:),fn_C);
                end
            end
        case 'ICZ'
            C_image = hw.getColorFrameRAW(1);
            stream  = hw.getFrame(n,false);
            for i=1:n
                mkdirSafe(path);
                fn_I = fullfile(path ,['I' sprintf('_%04d.bin',i)]);
                fn_Z = fullfile(path ,['Z' sprintf('_%04d.bin',i)]);
                writeAllBytes(stream(i).i(:),fn_I);
                writeZ(stream(i).z(:),fn_Z);
                if(i==1)
                    fn_C = fullfile(path ,['RGB' sprintf('_%04d.bin',i)]);
                    writeZ(C_image(1).color(:),fn_C);
                end
            end

    end
end


function [size]= writeZ(frame,fn)
   size = writeAllBytes(typecast(frame,'uint8'),fn);
end


