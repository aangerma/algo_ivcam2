function [ jStream ] = gamma( jStream, regs, luts,instance, lgr,traceOutDir )

lgr.print2file('\t\t------- gamma -------\n');

if(regs.JFIL.gammaBypass)
    jStream.ir = uint8(jStream.ir);
else
    inData = jStream.ir;
    jStream.ir = Utils.applyGamma(inData,12, uint32(regs.JFIL.gamma(1:65)),8,  regs.JFIL.gammaScale, regs.JFIL.gammaShift);
    jStream.ir = uint8(jStream.ir); %do not move this line up so the functionDependencyWalker will see apply gamma
end

if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

Pipe.JFIL.checkStreamValidity(jStream,instance,false);
if(~isempty(traceOutDir) )
    Utils.buildTracer(dec2hexFast(jStream.ir,2),['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end gamma -----\n');

end