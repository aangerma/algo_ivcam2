function roi_flag = roiFlag(xyQout, angyQ, regs)
%%
xq = xyQout(1,:);



roi_flag = false(1,size(xyQout,2));
begind = find(abs(angyQ)<regs.DIGG.ycrossThr & xq>-4,1);
endind = find(abs(angyQ)<regs.DIGG.ycrossThr & xq>=bitshift(regs.GNRL.imgHsize,2),1);
if(isempty(begind))
%     if(regs.MTLB.assertionStop)
        error('could not find start of frame');
%     else
%         warning('could not find start of frame');
%         begind=2;
%     end
end
if(isempty(endind)|| endind==length(xq))
    endind = length(xq)-1;
end
roi_flag(begind:endind)=true;

if(regs.MTLB.debug)
    %%
    N= 1:10:size(xyQout,2);
    f=figure(35212);
    hh=axes('parent',f);
    a=plot(xyQout(1,N)/4,xyQout(2,N),'b');
    se = find(abs(diff(roi_flag))==1);
    hold on;
    plot(xyQout(1,se(1))/4,xyQout(2,se(1)),'g.','markersize',50);title('ROI flag')
    plot(xyQout(1,se(2))/4,xyQout(2,se(2)),'r.','markersize',50);title('ROI flag')
    plot(xyQout(1,1:se(1))/4,xyQout(2,1:se(1)),'g','linewidth',5);
    plot(xyQout(1,se(2):end)/4,xyQout(2,se(2):end),'r','linewidth',5);
    rectangle('position',[0 0 regs.GNRL.imgHsize,regs.GNRL.imgVsize],'linewidth',5);
    set(hh,'ydir','reverse');
    hold off
    axis equal
end
end

