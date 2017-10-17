function [ jStream ] = invalidation( jStreamOld, regs, luts,instance, lgr,traceOutDir ) %#ok
%set depth to 0 (invalid) and confidence (0) if confidence is lower than
%threshold

lgr.print2file('\t\t------- invalidation -------\n');

jStream = jStreamOld;
if(~regs.JFIL.invBypass)
    
    LUT = uint32(regs.JFIL.invDepthConfidence(1:end-1));
    
    dmin = regs.JFIL.invMinMax(1);
    dmax = regs.JFIL.invMinMax(2);
    
    invDpth = jStream.depth<dmin | jStream.depth>dmax;
    %2016-11-15 logic lineup with doc
    if (regs.JFIL.invUseGlobalConf)
        invDpth = invDpth |  jStream.conf<regs.JFIL.invConfThr;
    else
        for i=1:length(LUT)
            confMsk = jStream.conf==i;
            depthMsk = jStream.depth<LUT(i);
            invDpth  = invDpth | (confMsk & depthMsk);
        end
    end
    
    jStream.depth(invDpth) = 0;
    jStream.conf(invDpth) = 0;
end
if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

if(~isempty(traceOutDir) )

    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end invalidation -----\n');

end