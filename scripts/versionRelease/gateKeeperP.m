%%
clear

%,'STATstt1Bypass','STATstt1cellHsize','STATstt1cellVsize','STATstt1iconCellCoord','STATstt1integralImageBypass','STATstt1invCntBypass','STATstt1invalOrPxl','STATstt1linearReference','STATstt1lowThrPxlNum','STATstt1normMult','STATstt1scaleMode','STATstt1src','STATstt1tCamOutFormat','STATstt2Bypass','STATstt2cellHsize','STATstt2cellVsize','STATstt2iconCellCoord','STATstt2integralImageBypass','STATstt2invCntBypass','STATstt2invalOrPxl','STATstt2linearReference','STATstt2lowThrPxlNum','STATstt2normMult','STATstt2scaleMode','STATstt2src','STATstt2tCamOutFormat'
regsRandomList  = {'FRMWtxCode','GNRLcodeLength','GNRLsampleRate','GNRLrangeFinder','DIGGsphericalEn','CBUFbypass','DCORambLUTExp','DCORambMap','DCORambStartLUT','DCORbypass','DCORfineCorrRange','DCORirLUTExp','DCORirMap','DCORirStartLUT','DCORoutIRcma','DCORoutIRcmaBin','DCORoutIRnest','DCORpsnr','DCORtmplMode','DCORyScalerBits','DCORyScalerDivExp','DESTambiguityMinConf','DESTambiguityMinRTD','DESTxbaseline','DESTybaseline','DESTconfactIn','DESTconfactOt','DESTconfq','DESTconfv','DESTconfw1','DESTconfw2','DESTdepthAsRange','DESTrxPWRpdScale','DESTsmoothKerLen','DESTtmptrOffset','DESTtmptrScale','DESTtxFRQpd','DESTtxPWRpdScale','DIGGbitshift','DIGGgammaBypass','DIGGgammaScale','DIGGgammaShift','DIGGnestBypass','DIGGnestLdOnDelay','DIGGnestNumOfSamplesExp','DIGGnotchBypass','DIGGycrossThr','EPTGinputAsRange','EPTGirImageType','EPTGmirrorFastFreq','EPTGmultiFocalROI','EPTGnMaxSamples','EPTGnoiseLevel','EPTGsampleJitter','EPTGseed','EPTGslowCouplingFactor','EPTGslowscanType','MTLBtxSymbolLength','EPTGzImageType','FRMWcbufConstLUT','FRMWcoarseMasking','FRMWcoarseSampleRate','FRMWlaserangleH','FRMWlaserangleV','FRMWnotchBw0','FRMWnotchBwDecay','FRMWpllClock','FRMWprojectionYshear','FRMWxR2L','FRMWxfov','FRMWyfov','GNRLzMaxSubMMExp','JFILbilt1SharpnessR','JFILbilt1bypass','JFILbilt2SharpnessR','JFILbilt2bypass','JFILbilt3SharpnessR','JFILbilt3bypass','JFILbiltAdaptR','JFILbiltAdaptS','JFILbiltConfAdaptR','JFILbiltConfAdaptS','JFILbiltConfMaskD','JFILbiltConfMaskIR','JFILbiltConfThr','JFILbiltConfWeightD','JFILbiltDepthAdaptR','JFILbiltDepthAdaptS','JFILbiltGauss','JFILbiltIRAdaptR','JFILbiltIRAdaptS','JFILbiltIRSharpnessR','JFILbiltIRSharpnessS','JFILbiltIRValueAdaptR','JFILbiltIRValueAdaptS','JFILbiltIRbypass','JFILbiltSharpnessS','JFILbiltSigmoid','JFILbypass','JFILdFeatures','JFILdFeaturesConfThr','JFILdFeaturesNorm','JFILdFeaturesSortType','JFILdnnBypass','JFILdnnMinConf','JFILdnnWeights','JFILedge1bypassMode','JFILedge3bypassMode','JFILedge4bypassMode','JFILgammaBypass','JFILgammaScale','JFILgammaShift','JFILgeomBadConf','JFILgeomBypass','JFILgeomConfThr','JFILgeomGoodConf','JFILgeomMinHits','JFILgeomTemplateEnable','JFILgrad1ConfLevel','JFILgrad1ConfUpdVal','JFILgrad1Mask','JFILgrad1ThrFactor','JFILgrad1bypass','JFILgrad1thrAveDiag','JFILgrad1thrAveDx','JFILgrad1thrAveDy','JFILgrad1thrMaxDiag','JFILgrad1thrMaxDx','JFILgrad1thrMaxDy','JFILgrad1thrMinDiag','JFILgrad1thrMinDx','JFILgrad1thrMinDy','JFILgrad1thrMode','JFILgrad1thrSpike','JFILgrad2ConfLevel','JFILgrad2ConfUpdVal','JFILgrad2Mask','JFILgrad2ThrFactor','JFILgrad2bypass','JFILgrad2thrAveDiag','JFILgrad2thrAveDx','JFILgrad2thrAveDy','JFILgrad2thrMaxDiag','JFILgrad2thrMaxDx','JFILgrad2thrMaxDy','JFILgrad2thrMinDiag','JFILgrad2thrMinDx','JFILgrad2thrMinDy','JFILgrad2thrMode','JFILgrad2thrSpike','JFILiFeatures','JFILiFeaturesNorm','JFILinnBypass','JFILinnWeights','JFILinvBypass','JFILinvConfThr','JFILinvDepthConfidence','JFILinvMinMax','JFILinvUseGlobalConf','JFILmaxPoolBypass','JFILmaxPoolConfThr','JFILsort1Edge01','JFILsort1Edge03','JFILsort1bypassMode','JFILsort1dWeights','JFILsort1doConfAveraging','JFILsort1fixedConfValue','JFILsort1iWeights','JFILsort2bypassMode','JFILsort2dWeights','JFILsort2doConfAveraging','JFILsort2fixedConfValue','JFILsort2iWeights','JFILsort3bypassMode','JFILsort3dWeights','JFILsort3doConfAveraging','JFILsort3fixedConfValue','JFILsort3iWeights','JFILupscalex1y0','JFILupscalexyBypass','PCKRallInDepth','PCKRconfEn','PCKRdepthEn','PCKRirEn','PCKRprivacyC','PCKRprivacyEn','PCKRprivacyI','PCKRprivacyZ','RASTbiltAdapt','RASTbiltAdaptR','RASTbiltBypass','RASTbiltDiag','RASTbiltSharpnessR','RASTbiltSharpnessS','RASTbiltSigmoid','RASTbiltSpat','RASTconfDC','RASTdcLevel','RASTdiscardLateChuncks','RASTinvalidateDiffTxRx','RASTirDiscardsidelobes','RASTmmSide','RASToutIRmm','RASToutIRvar','RASTsideLobeDir','RASTskipOnTxModeChange','FRMWdiggGammaFactor','FRMWjfilGammaFactor','FRMWundistLensCurve'};
cntGfn = tempname;
cntBfn = tempname;

defregs.FRMW.xres=uint16(64);
defregs.FRMW.yres=uint16(48);
defregs.MTLB.fastApprox=false;
defregs.FRMW.marginL = int16(0);%randomize
defregs.EPTG.frameRate = single(600);

failedSeeds=[];
fw = Firmware;
fw.setRegs(defregs,[]);


%%
        for seed=1:100000
            %%
            
            %     ns=fprintf('%4d (%4d)...',i,cnt);
            
            try
                %%
                fw_ = copy(fw);
               
                rng(seed);
                outcfg = [tempname '.csv'];
                fw_.randomize(outcfg,regsRandomList);
                fw_.writeUpdated(outcfg);
                
            catch e,
                %         fprintf('%s\n',e.message);
                %     pause(0.1);
                %     fprintf(repmat('\b',1,ns))
                continue;
            end
            cntG=0;
            cntB=0;
            
            %      cnt =aux.counter(cntBfn);
                outdir = tempname;
                mkdir(outdir);
            try
                %%

                outputivs=Pipe.patternGenerator(outcfg,'outputdir',outdir);
                Pipe.autopipe(outputivs,'saveTrace',1,'viewResults',0,'verbose',0);
                %         fprintf(repmat('\b',1,ns))
                cntG =aux.counter(cntGfn);
            catch e,
                blck=intersect({e.stack.name},{'ASCNC','DIGG','RAST','DCOR','DEST','CBUF','JFIL','STAT','PCKR'});
                if(isempty(blck))
                    blck={'unknown'};
                end
                funcname = e.stack(1).name;
                fname = sprintf('FAILED_%07d_%s_%s',seed,blck{1},funcname);
                fprintf('%s\n',fname);
                copyfile(outcfg,sprintf('%s/%s.csv',fileparts(outcfg),fname));
                cntB =aux.counter(cntBfn);
            end
            rmdir(outdir,'s');
            fprintf('%d/%d\n',cntG+cntB,cntB);
        end

