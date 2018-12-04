function [cor_dec] = runCoarseCorr(cma, regs, luts)

downSamplingR = 2 ^ double(regs.DCOR.decRatio);
cma_dec = reshape(cma, downSamplingR, double(regs.GNRL.tmplLength)/downSamplingR, regs.GNRL.imgVsize, regs.GNRL.imgHsize);
cma_dec = permute(sum(uint32(cma_dec),1, 'native'),[2 3 4 1]);

uint82uint4 = @(v) vec([bitand(v(:),uint8(15)) bitshift(v(:),-4)]');
mem2tbl = @(v) reshape(flipud(reshape(uint82uint4 (typecast(v,'uint8')),8,[])),[],64);
tmplC = mem2tbl (luts.DCOR.tmpltCrse);

nC = double(regs.DCOR.coarseTmplLength);
kerC = tmplC(256-nC+1:256,:);
kerC =flipud(kerC);%ASIC ALIGNMENT

cor_dec = Utils.correlator(uint16(cma_dec), kerC(:,1));
end

