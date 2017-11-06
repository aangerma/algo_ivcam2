function regName = sprivConvertBlockNameId2regName(s)
regName = strcat(s.algoBlock,s.algoName,iff(isnan(s.subReg),'',sprintf('_%03d',s.subReg)));
end