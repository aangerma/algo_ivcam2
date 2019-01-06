function [corrSegment] = runFineCorr(cma, regs, luts, corrOffset)
nF = double(regs.GNRL.tmplLength);
uint82uint4 = @(v) vec([bitand(v(:),uint8(15)) bitshift(v(:),-4)]');
mem2tbl = @(v) reshape(flipud(reshape(uint82uint4 (typecast(v,'uint8')),8,[])),[],64);
tmplF = mem2tbl (luts.DCOR.tmpltFine);
tmplF  = circshift(tmplF ,[-nF+16,16]);
tmplF = reshape(tmplF,2048,32);
kerF = tmplF(1024-nF+1:1024,:);
kerF = flipud(kerF);%ASIC ALIGNMENT

downSamplingR = 2 ^ double(regs.DCOR.decRatio);

%calc correlation segment
corrSegment = Utils.correlator(uint16(cma), kerF, uint32(0), uint16(corrOffset)*uint16(downSamplingR), regs.DCOR.fineCorrRange);

%correlation segment size is always 33
n = 16-regs.DCOR.fineCorrRange;
zp = uint32(zeros(n,regs.GNRL.imgVsize,regs.GNRL.imgHsize));
corrSegment = [zp;corrSegment;zp];
end

