%%
clear



regsRandomList = {'EPTGframeRate','FRMWxfov','FRMWyfov','FRMWprojectionYshear','FRMWxres','FRMWyres','FRMWlaserangleH','FRMWlaserangleV','FRMWundistLensCurve','FRMWundistXfovFactor','FRMWundistYfovFactor','DIGGundistBypass','EPTGmirrorFastFreq','EPTGslowCouplingFactor','EPTGslowCouplingPhase','EPTGscndModePhase','EPTGscndModeFreq','EPTGscndModeFactor'};

randCode = false;

outcfg=[tempname '.csv'];%
outDir = '\\invcam322\Ohad\data\lidar\EXP\verTest\';
mkdirSafe(outDir)
mkdirSafe([outDir 'pass']);

defregs.JFIL.bypass=true;
defregs.MTLB.assertionStop=true;

fw = Firmware;
fw.setRegs(defregs,outcfg);
fw.writeUpdated(outcfg);
cnt =1;

%%

for i=1:1000000
    %%
    ns=fprintf('%4d (%4d)...',i,cnt);
    
    try
        %%
        
        rng(i+1000);
        if(randCode)
        ll= randi(64)*2;
        [randregs.FRMW.txCode, randregs.GNRL.codeLength] = Utils.bin2uint32(Codes.propCode(ll,1) );
        randregs.FRMW.coarseSampleRate=uint8(2^floor(log2(256/double(randregs.GNRL.codeLength))));
        nn128 = @(x) floor(x/sum(x)*128);
        randregs.JFIL.sort1dWeights=uint8(nn128(randi(64,[1,4])));
        randregs.JFIL.sort2dWeights=uint8(nn128(randi(64,[1,4])));
        randregs.JFIL.sort3dWeights=uint8(nn128(randi(64,[1,4])));
        fw.setRegs(randregs,outcfg);
        end
        fw.randomize(outcfg,regsRandomList);
        
        %special cases
        
        
        
        regs=fw.get();
       

        fw.writeUpdated(outcfg);
        outputivs=Pipe.patternGenerator(outcfg,'outputdir',tempdir);
    catch e,
%          fprintf('%s\n',e.message);
%     pause(0.1);
    fprintf(repmat('\b',1,ns))
        continue;
    end
    
    cnt = cnt+1;
    
    try
        %%
        
        
        
        po=Pipe.autopipe(outputivs,'saveTrace',1,'viewResults',0,'verbose',0);
        fprintf(repmat('\b',1,ns));
        fname = sprintf('PASS_%07d',i);
        copyfile(outcfg,sprintf('%s/pass/%s.csv',outDir,fname));
    catch e,
        blck=intersect({e.stack.name},{'ASCNC','DIGG','RAST','DCOR','DEST','CBUF','JFIL','STAT','PCKR','patternGenerator'});
        funcname = e.stack(1).name;
        fname = sprintf('FAILED_%07d_%s_%s',i,blck{1},funcname);
        fprintf('---%s\n',fname);
        copyfile(outcfg,sprintf('%s/%s.csv',outDir,fname));

    end
    
end
