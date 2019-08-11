function [status] = Iv2CaptureLoopFG(baseDir,distance,ndfilter)
    
    % prepare inputs
    if ischar(distance) || isstring(distance)
        distance = str2double(distance);
    end
     if isnumeric(ndfilter)
         ndfilter = num2str(ndfilter);
     end
    
     numImages = 20;
     
    %prepare the folder
    template = 'Frame%04d.Mat';
    dname = fullfile(baseDir, num2str(distance),ndfilter,[]);
    mkdirSafe(dname);
    
    global gProjID;
    gProjID = iv2Proj.L520;
    
    
    %prepare the camera
    hw = HWinterface();
    hw.cmd('dirtybitbypass');
    hw.runScript('ldOn.txt');
    pause(1);
    
    %capture frame
    warning off;
    ivs_arr=Utils.FG_IVS(dname,numImages);
    warning on;
    
    %process frame
    for i=1:numImages
        ivs = ivs_arr(i);
        FlagsCodeStartMask = bitget(ivs.flags,2);
        flag_indexes=[];
        for index=1:length(FlagsCodeStartMask)
            if FlagsCodeStartMask(index)==1
                flag_indexes=[flag_indexes index];
            end
        end
        
        fast_size=512;
        slow_size=8;
        code_per_chunk=floor((flag_indexes(2)-flag_indexes(1))/slow_size)-1;
        total_code_amount=code_per_chunk*length(flag_indexes);
        fast=zeros(fast_size,total_code_amount,'logical');
        slow=zeros(slow_size,total_code_amount,'uint16');
        
        total_code=1;
        for chunk=1:length(flag_indexes)
            chunk_start_slow=flag_indexes(chunk)+1;
            chunk_start_fast=(flag_indexes(chunk)-1)*64+2;
            for code=1:code_per_chunk
                fast(:,total_code)=ivs.fast(chunk_start_fast+fast_size*(code):chunk_start_fast+fast_size*(code+1)-1)';
                slow(:,total_code)=ivs.slow(chunk_start_slow+slow_size*(code):chunk_start_slow+slow_size*(code+1)-1)';
                total_code=total_code+1;
            end
        end
        
        dist=distance*ones(1,total_code_amount);
        save(fullfile(dname,sprintf(template, i)),'fast','slow','dist','ndfilter');
    end
    fclose all;
    status =1;
    
end

