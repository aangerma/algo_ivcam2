function state =findLongRangeStateCal(calibParams,resolution)
        state1Res=calibParams.presets.long.state1.resolution;
        state2Res=calibParams.presets.long.state2.resolution; 
        switch mat2str(resolution)
            case mat2str(state1Res)
                state='state1';
            case mat2str(state2Res)
                state='state2'; 
            otherwise 
                state=nan; 
        end 
end 