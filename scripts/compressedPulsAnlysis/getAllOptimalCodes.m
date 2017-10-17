function [cBuff]=getAllOptimalCodes(N)
%{

for i=20:2:28
[cBuff,maxScore]=getOneBestCode(i);
save(sprintf('code%d',i),'cBuff','maxScore');
end

%%%PLOT SPECTRUM
plot(linspace(0,10,size(cBuff,2)*10),abs(fft(Utils.binarySeq(0:0.1:size(cBuff,2)-0.1,cBuff*2-1,1)')))


crrIJ =@(i,j,dt)dt*Utils.correlator(Utils.binarySeq(0:dt:size(cBuff,2)-dt,cBuff(i,:),1)',Utils.binarySeq(0:dt:size(cBuff,2)-dt,cBuff(j,:),1)'*2-1);
score = @(x) max(x)/max(x([1:maxind(x)-1 maxind(x)+1:end]))
crr = arrayfun(@(i) crrIJ(i,i,1)',1:size(cBuff,1),'uni',false);crr=[crr{:}]';
plot(crr')

%%% cross corr
xc = cell(size(cBuff,1),1);
parfor i=1:size(cBuff,1)
    z=nan(size(cBuff,1),1);
    for j=i:size(cBuff,1)
        z(j)=score(Utils.correlator(cBuff(i,:)',int8(cBuff(j,:)*2-1)'));
    end
    xc{i}=z;
    i
end
xc = [xc{:}];
imagesc(xc)

xcClean=xc;
ind=1:size(cBuff,1);
for i=1:size(xcClean,1)
bd=[false(i,1);xcClean(i+1:end,i)>1]
xcClean(:,bd)=[];xcClean(bd,:)=[];
ind(bd)=[];
imagesc(xcClean);
pause
end

%}
%

ind = mod(bsxfun(@minus,(1:N)',0:N-1)-1,N)+1;
iii=0;
cBuff = false(N,0);
maxScore  = floor(N/2)-1;
rec_buildCode(false(0,0));
cBuff=cBuff';

 function rec_buildCode(c)
        
        lc = length(c);
        if(lc==N)
            %check DC
            nnzc2 = nnz(c)*2;
            if(mod(N,2)==1)
                okdc = nnzc2/(N-1)==1 |  nnzc2/(N+1)==1;
            else
                okdc = nnzc2/N==1;
            end
            if(~okdc)
                return;
            end
            %check circularity
            cChk = c([end-1 end 1 2])*[1;2;4;8];
            bd = cChk==0 | cChk==1 | cChk==7 | cChk==8 | cChk==14 | cChk==15;
            if(bd)
                return;
            end
                corr = 	(c*2-1)*c(ind);
                
                score = corr(1)-max(corr(2:end));
                iii=iii+1;
                if(score== maxScore)
                    cBuff(:,end+1)=c;
                    %             fprintf('%s\n',mat2str(double(c)));
                end
                
                
            
            return;
        elseif(lc<2)
            
            rec_buildCode([c false]);
            rec_buildCode([c true]);
        else
            cChk = c(end-1:end)*[1;2];
            switch(cChk)
                case 0
                    rec_buildCode([c true]);
                case 3
                    rec_buildCode([c false]);
                otherwise
                    rec_buildCode([c false]);
                    rec_buildCode([c true]);
            end
        end
        
    end


end