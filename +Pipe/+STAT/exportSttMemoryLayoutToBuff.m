function [IconMem,HistMem, IntegralImMem] = exportSttMemoryLayoutToBuff(sttMemoryLayout)
    %exportSttMemoryLayoutToBuff export the matlab strruct into byte array of memory
    
    %concatenate icons
    IconMem = cell2mat(sttMemoryLayout.Icons(:));
    
    %concatenate integral image icons
    IntegralImMem = cell2mat(sttMemoryLayout.IntegralImage(:));
    
    %interleave lines of historgrams
    HistMem = {zeros(48,256),zeros(48,256)};
    s={sttMemoryLayout.TemporalHists sttMemoryLayout.SpatialHists};
   
   for i=1:2 %temporal/spatial           for k=1:4 % icon1...icon4            for j=1:12 %hist1..hist12                  HistMem{i}((k-1)*12+j,:) = s{i}{k}(j,:);            end        end    end

end