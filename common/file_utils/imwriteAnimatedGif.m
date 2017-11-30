function imwriteAnimatedGif(imCell,outfn)
mm=minmax(vec([imCell{:}]));
imCell=cellfun(@(x) (x-mm(1))/diff(mm),imCell,'uni',0);
for i=1:length(imCell)
    switch(size(imCell{i},3))
        case 1
            [imind,cm] =gray2ind(imCell{i},256);
        case 3
            [imind,cm] = rgb2ind(imCell{i},256);
        otherwise
            error('unknown # of channels');
            
    end
    
    if(i==1)
        imwrite(imind,cm,outfn,'gif', 'Loopcount',inf,'DelayTime',0.1);
    else
        imwrite(imind,cm,outfn,'gif','WriteMode','append','DelayTime',0.1);
    end
    
end
end