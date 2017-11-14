function  [zImgRAW, cImgRAW, iImgRAW] = CBUF(pflow,regs,~,lgr,traceOutDir)
lgr.print2file('\n\t------- CBUF -------\n');
if(isempty(pflow.pixIndOutOrder))%no pixels arrived to CBUF
    zImgRAW = zeros(size(pflow.pipeFlags), 'uint16');
    iImgRAW = zeros(size(pflow.pipeFlags), 'uint16');
    cImgRAW = zeros(size(pflow.pipeFlags), 'uint8');
    
else
    if(regs.CBUF.bypass)
        streamAsInput = @(v) reshape([vec(v(pflow.pixIndOutOrder));zeros(numel(v)-numel(pflow.pixIndOutOrder),1)],size(v));
        %rearange data
        zImgRAW=streamAsInput(pflow.zImgRAW);
        iImgRAW=streamAsInput(pflow.iImgRAW);
        cImgRAW=streamAsInput(pflow.cImgRAW);
    else
        zImgRAW = pflow.zImgRAW;
        iImgRAW = pflow.iImgRAW;
        cImgRAW = pflow.cImgRAW;
        
        
        %%
        if(regs.GNRL.imgVsize>=721)
            MAX_BUFFER_SIZE=64;
        elseif(regs.GNRL.imgVsize>=513)
            MAX_BUFFER_SIZE=85;
        else
            MAX_BUFFER_SIZE=120;
        end
        
        CYCLES_PER_PIX_RELEASE = 5;
        [y,x]=ndgrid(1:double(regs.GNRL.imgVsize),1:double(regs.GNRL.imgHsize));
        t = pflow.pixRastOutTime(pflow.pixIndOutOrder);
        t=t-t(1);
        x=x(pflow.pixIndOutOrder);
        y=y(pflow.pixIndOutOrder);
        
        
        
        bufRightPointer = Pipe.CBUF.maxrun(x);
        
        
        
        %
        
        xlutIndx = bitshift(x-1,-int16(regs.CBUF.xBitShifts));%x-1 -->zero base
        assert(all(xlutIndx<=15));
        
        reqXbufferSize = double(vec(regs.CBUF.xRelease(xlutIndx+1)));
        nsecPerColum = CYCLES_PER_PIX_RELEASE*1000/double(regs.MTLB.asicCBUFclock)*double(regs.GNRL.imgVsize);
        
        optBufLeftPointer = max(0,bufRightPointer-reqXbufferSize);
        actBufLeftPointer = Pipe.CBUF.stepInc(optBufLeftPointer,[0;diff(double(t))]/nsecPerColum);
       
        
        if(regs.MTLB.debug)
            %%
            figure(435234)
            actBufferSize = bufRightPointer-actBufLeftPointer;
            ah(1)=subplot(211);
            plot(t,x,t,bufRightPointer,t,optBufLeftPointer,t,actBufLeftPointer);legend('x','buffer Right marker','optimal buffer left marker','actual buffer left marker')
            legend('x','buffRightPointer','buffLeftPointer(optimal)','buffLeftPointer(actual)','location','best')
            set(ah(1),'xlim',t([1 end]));
            grid on
            grid minor
            ah(2)=subplot(212);
            plot(t,actBufferSize,t,t*0+MAX_BUFFER_SIZE,t,x-actBufLeftPointer,t,reqXbufferSize,t,t*0,'r');
            legend('Buffer size','max buffer size','x distance from right pointer','requested buffer size','location','best');
            set(ah(2),'xlim',t([1 end]));
            linkaxes(ah,'x');
            grid on
            grid minor
            
        end
        underflowInd = (x<actBufLeftPointer);
        if(nnz(underflowInd)>0)
            txt=sprintf('CBUF underflow (%d, Assigned buffer is not big enough to accomodate scanline curve)',nnz(underflowInd));
            lgr.print2file('\t***%s***\n',txt);
            
            
            %discard underflow pixels
            zImgRAW(underflowInd) = uint16(0);
            iImgRAW(underflowInd) = uint16(0);
            cImgRAW(underflowInd) = uint8(0);
        end
        overflowInd = (bufRightPointer-actBufLeftPointer>MAX_BUFFER_SIZE);
        if(any(overflowInd))
            txt=sprintf('CBUF overflow (%d slow axis is changing too fast)',nnz(overflowInd));
            lgr.print2file('\t***%s***\n',txt);
            
            %discard overflow pixels
            zImgRAW(overflowInd) = uint16(0);
            iImgRAW(overflowInd) = uint16(0);
            cImgRAW(overflowInd) = uint8(0);
        end
        lgr.print2file('scan coverege: %.2f%%\nunderflow margin: %d\noverflow margin: %d\n',...
            length(pflow.pixIndOutOrder)/numel(iImgRAW)*100,...
            min(x(find(x>MAX_BUFFER_SIZE,1):end)-actBufLeftPointer(find(x>MAX_BUFFER_SIZE,1):end)),...
            MAX_BUFFER_SIZE-max(x-actBufLeftPointer));
        
    end
end
if(~isempty(traceOutDir) )
    %CBUF OUT
    pio=1:numel(zImgRAW);
    cbufOutTxt = [dec2hexFast(cImgRAW(pio),1) dec2hexFast(zImgRAW(pio),4) dec2hexFast(iImgRAW(pio),3)];
    Utils.buildTracer(cbufOutTxt,'CBUF_out',traceOutDir);
end
lgr.print2file('\t----- end CBUF -----\n');
end
