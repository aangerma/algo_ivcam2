function s = colorMap2string(a)
s=reshape(cell2str(arrayfun(@(x) dec2hex(round(x*255),2),a,'uniformoutput',false)',''),[6,size(a,1)])';
end