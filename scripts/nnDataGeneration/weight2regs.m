fn = '\\perclnx53\ohaData\output\tensorflowOutputoutputModel.txt';
w = fileReadNumeric(fn);
nnType = 'depth';


switch(nnType)
    case 'depth'
        assert(length(w)==314);
        regMask = 'JFILdnnWeights_%03d';
        w = Utils.fp20('from',single(w));
    otherwise
        error('unknonw network type');
end
fid = fopen(sprintf('nnweight_%s.csv',nnType),'w');
fprintf(fid,'uniqueID    , regName         , base , value    , comments\n');
fprintf(fid,['000.000.000\t,' regMask '\t,h\t,%05X\t,\n'],[0:length(w)-1;w(:)']);
fclose(fid);

