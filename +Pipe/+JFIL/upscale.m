function [ jStream ] = upscale( jStream, regs, luts, instance, lgr,traceOutDir )%#ok

lgr.print2file('\t\t------- upscale -------\n');

upscaleXYBypass = regs.JFIL.upscalexyBypass;
upscaleFlagXY = regs.JFIL.upscalex1y0;

if(upscaleXYBypass~=1)
    if(upscaleFlagXY==1)
        jStream.depth = us(jStream.depth);
        jStream.conf  = us(jStream.conf);
        jStream.ir    = us(jStream.ir);
        if(isfield(jStream,'flags'))
            jStream.flags    = us(jStream.flags);
        end
    elseif(upscaleFlagXY==0)
        jStream.depth = us(jStream.depth')';
        jStream.conf  = us(jStream.conf')';
        jStream.ir    = us(jStream.ir')';
        if(isfield(jStream,'flags'))
            jStream.flags    = us(jStream.flags);
        end
    end
end

if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

Pipe.JFIL.checkStreamValidity(jStream,instance,true);

if(~isempty(traceOutDir) )
    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end upscale -----\n');

end

function o = us(i)
o = cast(zeros([size(i,1) size(i,2)*2]),'like',i);
o(:,1:2:end)=i;
end
