function [status] = Iv2CaptureLoop(baseDir,distance,ndfilter)
    
    status = -1;
    template = 'Frame_%04d_%s.bin';
    dname = fullfile(baseDir,distance,ndfilter,[]);
    mkdirSafe(dname);
    hw = HWinterface();
    frames = hw.getFrame(10,0);
    fields = {'z','i','c'};
    for i=1:length(frames)
        for f=1:length(fields)
            fname = fullfile(dname,sprintf(template,i,fields{f}));
            fd = fopen(fname,'wb');
            fwrite(fd,frames(i).(fields{f}));
            fclose(fd);
        end
    end
    clear hw;
    status =1;
    
    
end

