function [Tcam,ftcam] = create_tcam_in(imSize,RegsTcamOutFormat,RegsALSPixelSel,fals)
    %CREATE_TCAM_IN Summary of this function goes here
    %   Detailed explanation goes here
    Tcam = zeros(imSize);
    bitImage = [];
    ftcam = [];
    switch RegsTcamOutFormat
        case {0} %RGB565, RGB555
            R = randi(2^5-1,imSize);
            G = randi(2^6-1,imSize);
            B = randi(2^5-1,imSize);
            ftcam = uint32(B+bitshift(G,5)+bitshift(R,11));
            
            Tcam = 2*R+4*G+B;
        case 1 %RGB888
            R = randi(2^8-1,imSize);
            G = randi(2^8-1,imSize);
            B = randi(2^8-1,imSize);
            Tcam =  bitshift(2*R+4*G+B,-2);
            ftcam = uint32(B+bitshift(G,8)+bitshift(R,16));
        case {2,3} %YUV422
            YUV1 = randi(2^8-1,imSize);
            YUV2 = randi(2^8-1,imSize);
            ftcam = uint32(YUV1+bitshift(YUV2,8));
            
            if RegsTcamOutFormat==3
                Tcam = YUV2;
            else
                Tcam = YUV1;
            end
            
            bitImage = zeros(imSize(1),2*imSize(2));
            bitImage(:,1:2:end) = YUV1;
            bitImage(:,2:2:end) = YUV2;
        case {4,7} %RAW 10
            Tcam = randi(2^10-1,imSize);
            ftcam = uint32(Tcam);
            
            bitImage = Tcam;
        case {5,6}
            Tcam = randi(2^8-1,imSize);
            ftcam = uint32(Tcam);
            
            bitImage = Tcam;
    end
    if fals > 0
        fprintf(fals,'%08x\n',Pipe.STAT.sum_quads(bitImage,RegsALSPixelSel));
    end
end

