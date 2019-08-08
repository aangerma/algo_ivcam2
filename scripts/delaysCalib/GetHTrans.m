function hTrans = GetHTrans(im)

[~, dbg] = Validation.aux.edgeTrans(im);
hTrans = dbg.hTrans;
