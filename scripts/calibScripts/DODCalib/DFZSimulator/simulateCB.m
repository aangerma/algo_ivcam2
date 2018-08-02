function [rpt,cbxyz] = simulateCB(dist,regs,CBParams)
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


[cbx,cby] = meshgrid(linspace(-(CBParams.bsz(2)-1)/2*CBParams.size,(CBParams.bsz(2)-1)/2*CBParams.size,CBParams.bsz(2)),...
                     linspace(-(CBParams.bsz(1)-1)/2*CBParams.size,(CBParams.bsz(1)-1)/2*CBParams.size,CBParams.bsz(1)));
cbz = ones(size(cbx))*dist;
cbxyz = cat(3,cbx,cby,cbz);

% Calculate the range for each point (include the delay)
cbr = sqrt(sum(cbxyz.^2,3));
% get rtd from r
sing = cbxyz(:,:,1)./sqrt(cbxyz(:,:,1).^2+cbxyz(:,:,2).^2+cbxyz(:,:,3).^2);
C=2*cbr*regs.DEST.baseline.*sing - regs.DEST.baseline2;
rtd=cbr+sqrt(cbr.^2-C);
rtd=rtd+regs.DEST.txFRQpd(1);
% Calculate angx and angy
vec = reshape(cbxyz,[],3);
[angx,angy] = vec2ang(vec,regs);
rpt = cat(3,rtd,reshape(angx,size(rtd)),reshape(angy,size(rtd)));
end

