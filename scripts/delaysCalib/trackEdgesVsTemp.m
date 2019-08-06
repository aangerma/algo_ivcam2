clear variables
clc

%%

pn = 'X:\Users\syaeli\Work\Tasks\Delays\ATC\';

x = Calibration.aux.GetFramesFromDir([pn, sprintf('thermal%d',1)], 1024, 768);
[res, dbg] = Validation.aux.edgeTrans(x);
figure
h = imagesc(dbg.hTrans);
set(gca, 'CLim', [0,30])
colorbar
for k = 1:508
    x = Calibration.aux.GetFramesFromDir([pn, sprintf('thermal%d',k)], 1024, 768);
    [res, dbg] = Validation.aux.edgeTrans(x);
    set(h, 'CData', dbg.hTrans);
    title(sprintf('thermal%d',k))
    F(k) = getframe(gcf);
end
