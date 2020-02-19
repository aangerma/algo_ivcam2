colorRes = [1920 1080];%[640 480];
zRes = [768 1024];
cintoffs = 6; %6 for fhd, 17 for 720p 39 vga
resize = 0;

if ~exist('hw','var')
    hw = HWinterface;
    hw.setPresetControlState(2)
    hw.cmd('dirtybitbypass');
    %hw.cmd('algo_thermloop_en 0');
    hw.startStream([],zRes,colorRes);
    hw.getFrame;
    hw.getColorFrame;
    
    [ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
    intr = typecast(b,'single');
    Krgb = eye(3);
    Krgb([1,5,7,8,4]) = intr([cintoffs:cintoffs+3,1]);
    if resize
        Krgb = du.math.normalizeK(Krgb, [1920 1080]);
        Krgb(1,1) = Krgb(1,1)* (480/640)./(1080/1920);
        Krgb(1,3) = Krgb(1,3)* (480/640)./(1080/1920);
        Krgb(1:2,3) = Krgb(1:2,3) + 1;
        Krgb = bsxfun(@times,Krgb,[320;240;1]);
    end
    
    
    [ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
    extr = typecast(b,'single');
    Rrgb = reshape(extr(1:9),[3 3])';
    Trgb = extr(10:12)';
    
    P = Krgb*[Rrgb Trgb];
    
    camera = struct('zMaxSubMM',hw.z2mm,'zK',hw.getIntrinsics);
end
frame = mergestruct(hw.getColorFrame,hw.getFrame(30));
z = rot90(frame.z,2);
verts = Validation.aux.imgToVertices(z,camera);
uv = P * [verts ones(size(verts,1),1)]';
u = (uv(1,:)./uv(3,:))';
v = (uv(2,:)./uv(3,:))';
Iw = du.math.imageWarp(double(frame.color),v,u);
V = zeros(prod(zRes),1);
mask = z>0;
V(mask) = Iw;
figure(2);
imshowpair(reshape(V,zRes),rot90(frame.i,2))
if 0
    corners = Validation.aux.findCheckerboard(rot90(frame.i,2));
    verCorners = Validation.aux.pointsToVertices(corners,z,camera);
    cornersRGB = Validation.aux.findCheckerboard(double(frame.color));
    
    uv = P * [verCorners ones(size(verCorners,1),1)]';
    u = (uv(1,:)./uv(3,:))';
    v = (uv(2,:)./uv(3,:))';
    figure(1);clf;
    imagesc(frame.color),colormap gray;
    hold on;
    plot(u,v,'r+',cornersRGB(:,1)-1,cornersRGB(:,2)-1,'ob')
    hold off
end