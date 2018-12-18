function [ results,dbg  ] = validateDSM( hw,fprintff )
    results = [];
    dbg = [];
    [angxRawZO,angyRawZO,restFailed] = Calibration.aux.zeroOrderAngles(hw);
    dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
    dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
    dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
    dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');
    
    
    dbg.angxRawZO = angxRawZO;
    dbg.angyRawZO = angyRawZO;
    dbg.restFailed = restFailed;
    dbg.dsmXscale = dsmXscale;
    dbg.dsmYscale = dsmYscale;
    dbg.dsmXoffset = dsmXoffset;
    dbg.dsmYoffset = dsmYoffset;

    angx0 = inf;
    angy0 = inf;
    if restFailed
        fprintff('Failed to aquire DSM rest angles.\n');
    else
        angx0 = (angxRawZO+dsmXoffset)*dsmXscale-2047;
        angy0 = (angyRawZO+dsmYoffset)*dsmYscale-2047;
        fprintff('Mirror rest angles in DSM units: [%2.2g,%2.2g].\n',angx0,angy0);
    end
    results.MirrorRestAngX = angx0;
    results.MirrorRestAngY = angy0;
end
