function [dImgFil, iImgFil, cImgFil,nnfeatures,dNNOutput,iNNOutput,BTStages] = JFIL(pipeOutData,regs,luts,lgr,traceOutDir)

lgr.print2file('\n\t------- JFIL -------\n');


nnfeatures=[];
if(regs.JFIL.bypass)  %% do nothing.
    dImgFil = pipeOutData.zImgRAW;
    if(~regs.JFIL.bypassIr2Conf)
        iImgFil = uint8(pipeOutData.iImgRAW);%take 8 LSB
        cImgFil = pipeOutData.cImgRAW;
    else %put MSB's of IR into conf
        iImgFil = uint8(mod(pipeOutData.iImgRAW,2^8));
        cImgFil = uint8(idivide(pipeOutData.iImgRAW,2^8,'floor'));
    end
    
    if(regs.GNRL.rangeFinder)
        dImgFil=dImgFil(1);
        iImgFil=iImgFil(1);
        cImgFil=cImgFil(1);
        dNNOutput = [];
        iNNOutput = [];
    end
	    
else
    % init jStream
    jStream = struct;
    jStream.depth = pipeOutData.zImgRAW;
    jStream.ir = pipeOutData.iImgRAW;
    jStream.conf = pipeOutData.cImgRAW;
    jStream.flags=uint8(zeros(size(jStream.depth)));
    jStream.features={};
    if(regs.MTLB.debug)
        jStream.debug = {{'Input',jStream.depth,jStream.ir,jStream.conf}};
    end
    Pipe.JFIL.checkStreamValidity(jStream,'JFIL input',true);
     
%     if regs.MTLB.loggerImgPixelIndex < length(jStream.depth(:)) &&...
%             regs.MTLB.loggerImgPixelIndex >= 0
%         lgrImgPixIndx = regs.MTLB.loggerImgPixelIndex+1;
%     else
%         lgrImgPixIndx = [];
%     end
%     lgr.print2file(sprintf('\tpixel = %d (linear indices)\n',lgrImgPixIndx));
    
    
    Pipe.JFIL.printjStream(lgr,jStream);

    if(regs.GNRL.rangeFinder)
        jStream = Pipe.JFIL.maxPool(jStream, regs, luts,'maxPool',lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        dNNOutput = [];
        iNNOutput = [];
    else
        % Filters
        jStream = Pipe.JFIL.gradient    (jStream,  regs, luts, 'grad1', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream = Pipe.JFIL.sortEdge    (jStream,  regs, luts, 'sort1Edge01', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream = Pipe.JFIL.sort        (jStream,  regs, luts, 'sort2', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream = Pipe.JFIL.geom        (jStream,  regs, luts, 'geom', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream = Pipe.JFIL.upscale     (jStream,  regs, luts, 'xyus', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);

        jStream = Pipe.JFIL.sortEdge    (jStream,  regs, luts, 'sort1Edge03', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream = Pipe.JFIL.edge        (jStream,  regs, luts, 'edge4', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream.features.featA=jStream.depth;
%         lgr.print2file(sprintf('\tjStream.features.featA (1 value of pixel %d) = %X\n',lgrImgPixIndx,...
%             jStream.features.featA(lgrImgPixIndx)));
        BTStages.conf = jStream.conf;
        BTStages.preBT1 = jStream.depth;
    
        jStream = Pipe.JFIL.bilateral   (jStream,  regs, luts, 'bilt1', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        
        BTStages.BT1 = jStream.depth;
        
        jStream = Pipe.JFIL.bilateral   (jStream,  regs, luts, 'biltIR', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream.features.featB=jStream.depth;
%         lgr.print2file(sprintf('\tjStream.features.featB (1 value of pixel %d) = %X\n',lgrImgPixIndx,...
%             jStream.features.featB(lgrImgPixIndx)));
        
        jStream = Pipe.JFIL.bilateral   (jStream,  regs, luts, 'bilt2', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);

        BTStages.BT2 = jStream.depth;
            
        jStream.dFeatures = Pipe.JFIL.featureExtrationD(jStream,  regs, luts, 'dFeatures', lgr,traceOutDir);
        jStream.iFeatures = Pipe.JFIL.featureExtrationI(jStream,  regs, luts, 'iFeatures', lgr,traceOutDir);
        
%         if ~isempty(lgrImgPixIndx)
%             [r,c] = ind2sub(size(jStream.depth),lgrImgPixIndx);
%             lgr.print2file(sprintf('\tjStream.dFeatures (22 values of pixel %d) = %s\n',lgrImgPixIndx,...
%                 reshape([dec2hexFast(jStream.dFeatures(r,c,:),5),repmat(' ',22,1)]',6*22,[])'));
%         end
        
        jStream = Pipe.JFIL.dnn        (jStream,  regs, luts, 'dnn', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        
        dNNOutput = jStream.depth;
        
%         if ~isempty(lgrImgPixIndx)
%             [r,c] = ind2sub(size(jStream.depth),lgrImgPixIndx);
%             lgr.print2file(sprintf('\tjStream.iFeatures (14 values of pixel %d) = %s\n',lgrImgPixIndx,...
%                 reshape([dec2hexFast(jStream.iFeatures(r,c,:),5),repmat(' ',14,1)]',6*14,[])'));
%         end
        jStream = Pipe.JFIL.inn        (jStream,  regs, luts, 'inn', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        
        iNNOutput = jStream.ir;
        
        jStream = Pipe.JFIL.bilateral   (jStream,  regs, luts, 'bilt3', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        
        BTStages.BT3 = jStream.depth;
        
        jStream = Pipe.JFIL.gradient    (jStream, regs, luts, 'grad2', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        jStream = Pipe.JFIL.invalidation(jStream, regs, luts, 'invalidation', lgr,traceOutDir);
        Pipe.JFIL.printjStream(lgr,jStream);
        nnfeatures.d = jStream.dFeatures;
        nnfeatures.i = jStream.iFeatures;
        jStream = Pipe.JFIL.irShading       (jStream,  regs, luts, 'irShading', lgr,traceOutDir);
    end
    jStream = Pipe.JFIL.gamma       (jStream,  regs, luts, 'gamma', lgr,traceOutDir);
    Pipe.JFIL.printjStream(lgr,jStream);
    % Output
    dImgFil = jStream.depth;
    iImgFil = jStream.ir;
    cImgFil = jStream.conf;
    
    if(regs.MTLB.debug)
        %%
        figKey = 338877;

        [ny,nx]=goodLayout(length(jStream.debug));

        ha = zeros(length(jStream.debug),3);
        fa=zeros(3,1);
        figNames = {'Depth','IR','Confidence'};
        clims=cell(3,1);
        for j=1:3
            fa(j)=figure(figKey+j);
            clf;
            set(fa(j),'name',figNames{j});
            clims{j} = prctile_(double(vec(jStream.debug{1}{j+1})),[5,95])+[0 1e-3];
        end
        for i=1:length(jStream.debug)
            %         imgtxt = imresize(str2img(jStream.debug{i}{1}),2,'nearest');
            for j=1:3
                figure(fa(j));
                ha(i,j)=subplot(ny,nx,i);
                img =double(jStream.debug{i}{j+1});
                %             img(1:size(imgtxt,1),1:size(imgtxt,2))=double(imgtxt)*max(img(:));
                imagesc(img,clims{j});
                title(jStream.debug{i}{1})
                axis image;
                axis off
            end
        end
        linkaxes(ha);
    end
end

lgr.print2file('\n\t----- end JFIL -----\n');

end