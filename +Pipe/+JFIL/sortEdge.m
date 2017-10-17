function [ jStream ] = sortEdge( jStream, regs, luts, instance, lgr,traceOutDir )
% Two instances of this container in the pipe.
% Per register decision, do sort or edge.

selector = regs.JFIL.(instance);

if (selector==1)
    inst = ['sort',instance(end)];
    jStream = Pipe.JFIL.sort(jStream,  regs, luts, inst, lgr, []);
elseif (selector==0)
    inst = ['edge',instance(end)];
    jStream = Pipe.JFIL.edge(jStream,  regs, luts, inst, lgr, []);
else
    error('sortEdge says: bad input for argument "instance"');
end


if(~isempty(traceOutDir) )
    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end
end

