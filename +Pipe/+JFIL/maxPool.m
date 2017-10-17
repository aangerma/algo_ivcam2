function [jStream] = maxPool(jStream, regs, luts,instance,lgr,traceOutDir)%#ok

lgr.print2file('\t\t------- maxPool -------\n');

if(regs.JFIL.maxPoolBypass)
    jStream.depth=jStream.depth(1);
    jStream.conf=jStream.conf(1);
    jStream.ir=jStream.ir(1);
    
else
    ind = maxind(jStream.conf(:));
    jStream.depth=jStream.depth(ind);
    jStream.conf=jStream.conf(ind);
    jStream.ir = jStream.ir(ind);
    if(jStream.conf<regs.JFIL.maxPoolConfThr)
        jStream.conf=0;
        jStream.depth=0;
    end
end

if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

Pipe.JFIL.checkStreamValidity(jStream,instance,false);
if(~isempty(traceOutDir) )
    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end maxPool -----\n');

end


