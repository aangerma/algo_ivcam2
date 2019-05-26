if ~exist('hw','var')
    hw = HWinterface;
    hw.cmd('dirtybitbypass');
    hw.startStream([],[],[1920 1080]);
    hw.getFrame;
    hw.getColorFrame;
    
    [ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
    intr = typecast(b,'single');
    Krgb = eye(3);
    Krgb([1,5,7,8,4]) = intr([6:9,1]);
    
    [ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
    extr = typecast(b,'single');
    Rrgb = reshape(extr(1:9),[3 3])';
    Trgb = extr(10:12)';
    
    P = Krgb*[Rrgb Trgb];
    
    camera = struct('zMaxSubMM',hw.z2mm,'K',hw.getIntrinsics);
end
frame = mergestruct(hw.getColorFrame,hw.getFrame);
z = rot90(frame.z,2);
verts = Validation.aux.imgToVertices(z,camera);
uv = P * [verts ones(size(verts,1),1)]';
u = (uv(1,:)./uv(3,:))';
v = (uv(2,:)./uv(3,:))';
Iw = du.math.imageWarp(double(frame.color),v,u);
V = zeros(640*360,1);
mask = z>0;
V(mask) = Iw;
imshowpair(reshape(V,[360 640]),rot90(frame.i,2))
