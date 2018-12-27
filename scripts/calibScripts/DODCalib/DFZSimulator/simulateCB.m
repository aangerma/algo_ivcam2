function [rpt,cbxyz] = simulateCB(dist,yRot,regs,CBParams,noiseStdAng,noiseStdR)
% SimulateSB receives:
% 1. Distance from board in mm
% 2. The DFZ parameters
% 3. CB parameters (optional)

% Returns the rpt (r,angx,angy) of the points

% Creates the CB in space
if ~exist('CBParams','var')
    CBParams.size = 30;
    CBParams.bsz = [9,13];
end
if ~exist('fe','var')
    fe = [0:90;0:90]';
end

[cbx,cby] = meshgrid(linspace(-(CBParams.bsz(2)-1)/2*CBParams.size,(CBParams.bsz(2)-1)/2*CBParams.size,CBParams.bsz(2)),...
                     linspace(-(CBParams.bsz(1)-1)/2*CBParams.size,(CBParams.bsz(1)-1)/2*CBParams.size,CBParams.bsz(1)));
cbxz = [reshape(cbx,[],1),zeros(prod(CBParams.bsz),1)];
rotmat = [cosd(yRot),sind(yRot);-sind(yRot),cosd(yRot)];
cbxz = cbxz*rotmat;
cbxyz = cat(3,reshape(cbxz(:,1),CBParams.bsz),cby,reshape(cbxz(:,2),CBParams.bsz));
cbxyz(:,:,3) = cbxyz(:,:,3)+dist;

% cbxyz = cbxyz + randn(size(cbxyz))*noiseStd;

figure,plot3(cbxyz(:,:,1),cbxyz(:,:,2),cbxyz(:,:,3),'r*')
% Calculate the range for each point (include the delay)
cbr = sqrt(sum(cbxyz.^2,3));
% get rtd from r
sing = cbxyz(:,:,1)./cbr;
C=2*cbr*regs.DEST.baseline.*sing - regs.DEST.baseline2;
rtd=cbr+sqrt(cbr.^2-C);
rtd=rtd+regs.DEST.txFRQpd(1);
% Calculate angx and angy
vec = reshape(cbxyz,[],3);
% vec = applyExpander(vec,fliplr(fe));
[angx,angy] = vec2ang(vec,regs);
rpt = cat(3,rtd+ randn(size(rtd))*noiseStdR,reshape(angx,size(rtd))+ randn(size(rtd))*noiseStdAng,reshape(angy,size(rtd))+ randn(size(rtd))*noiseStdAng);
end

