function jStream=dnn(jStream,  regs, luts, instance, lgr,traceOutDir)

lgr.print2file('\t\t------- dnn -------\n');

ns = [22 10 5 4 1];
if(~regs.JFIL.dnnBypass)
    
    fv = jStream.dFeatures;
    fv = permute(fv,[3 1 2]);
    fv = reshape(fv,ns(1),[]);

  
    weightsVector =regs.JFIL.dnnWeights;
    actY = regs.JFIL.dnnActFunc;
    nout = Pipe.JFIL.nnet(fv,weightsVector,ns,actY,regs.MTLB.fastApprox(5));
    nout = reshape(nout,size(jStream.depth));
    jStream.depth = uint16(max(0,nout*regs.JFIL.nnNormInv));
    bdpixels = (jStream.depth==0);
    jStream.conf(bdpixels)=0;
    
    savedPixels = jStream.conf==0 &  jStream.depth~=0;
    jStream.conf(savedPixels)=regs.JFIL.dnnMinConf;
end
if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

Pipe.JFIL.checkStreamValidity(jStream,'dnn',true);

if(~isempty(traceOutDir) )
   
    Utils.buildTracer([dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end dnn -----\n');

end