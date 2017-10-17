function jStream=inn(jStream,  regs, luts, instance, lgr,traceOutDir)

lgr.print2file('\t\t------- inn -------\n');

%input layer 14 features
%input   14->5
%hidden1 5->3
%output  3->1
ns = [14 5 3 1];


if(~regs.JFIL.innBypass)
    
    
    fv = jStream.iFeatures;
    fv = permute(fv,[3 1 2]);
    fv = reshape(fv,ns(1),[]);
    
    
    
    
    
    weightsVector =regs.JFIL.innWeights;
    actY = regs.JFIL.innActFunc;
    nout = Pipe.JFIL.nnet(fv,weightsVector,ns,actY,regs.MTLB.fastApprox(5));
    jStream.ir = uint16(reshape(max(0,min(2^12-1,nout*(2^12-1))),size(jStream.ir)));
    
end

if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end
Pipe.JFIL.checkStreamValidity(jStream,'inn',true);
if(~isempty(traceOutDir) )
    Utils.buildTracer(dec2hexFast(jStream.ir,3),['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end inn -----\n');

end