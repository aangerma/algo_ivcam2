function [a,l,xy00,xy11] = pgonProperties(pts)
%input: array of cmplx
%output: area length bboxTL bbox BR
if(size(pts,2)==2)
    pts = pts(:,1)+1j*pts(:,2);
elseif(size(pts,1)==2)
    pts = pts(1,:)+1j*pts(2,:)';
end
pts = pts(:);
pts(end+1)= pts(1);
a=0;
l=0;
xy00 = min(real(pts)) +1j*min(imag(pts));
xy11 = max(real(pts)) +1j*max(imag(pts));

for i=1:length(pts)-1
    pp = pts(i:i+1);
    m = [real(pp) imag(pp)];
    a = a +det(m)/2;
    l = l + abs(diff(pp));
end
end