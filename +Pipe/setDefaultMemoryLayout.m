function [ memoryLayout ] = setDefaultMemoryLayout(  )
    %set the memory layout to its initial state (after powerup)
    
    %init the stat engine memories
    statLayout = Pipe.STAT.initMem();
    memoryLayout = struct('STT1',statLayout,'STT2',statLayout);
   
    
end

