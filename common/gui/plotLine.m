function a=plotLine(varargin)
BIG_NUM = 1e99;
abc = varargin{1};
indx = find(cellfun(@(x) strcmp(x,'parent'),varargin(2:end)));
if(~isempty(indx) && indx+2<=nargin)
    h = varargin{indx+2};
else
    h = gca;
end
yl = get(h,'ylim');
xl = get(h,'xlim');

bot = max(-(abc(2)*yl(1)+abc(3))/abc(1),-BIG_NUM);
top = min(-(abc(2)*yl(2)+abc(3))/abc(1), BIG_NUM);

lft = max(-(abc(1)*xl(1)+abc(3))/abc(2),-BIG_NUM);
rht = min(-(abc(1)*xl(2)+abc(3))/abc(2), BIG_NUM);

pt(1) = bot + 1j*yl(1);
pt(2) = top + 1j*yl(2);
pt(3) = xl(1) + 1j*lft;
pt(4) = xl(2) + 1j*rht;
mpt = mean(pt);
[~,ix] = sort(abs(pt-mpt));
x = real(pt(ix(1:2)));
y = imag(pt(ix(1:2)));
a=line(x,y,varargin{2:end});
end