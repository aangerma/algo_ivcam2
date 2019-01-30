function [feTable] = feVec2Mat(regs,luts)
if ~regs.FRMW.fovExpanderValid
    feTable = [];
    return;
end
feLut = typecast(luts.FRMW.fovExpander,'single');
feTable = reshape(feLut,length(feLut)*0.5,2);
end

