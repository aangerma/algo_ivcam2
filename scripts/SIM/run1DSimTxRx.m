function [depth, sim_data] = run1DSimTxRx(sim_data)
%{
orig_code_length = 13;
target_code_length = orig_code_length*4;
orig_code = Codes.propCode(orig_code_length*2,1);
a = reshape(orig_code,2,[]);
orig_code = (a(1,:))';
unbalanced_code = false(target_code_length, 1);
for k = 0:orig_code_length - 1
    if ~orig_code(k+1)
        unbalanced_code(4*k+4) = true; % 0 --> 0001
    end
    
    if orig_code(k+1)
        unbalanced_code(4*k+3) = true; % 1 --> 0010
    end 
end
sim_data.laser.txSequence = unbalanced_code;
%}
model = struct('t',[0 sim_data.runTime],'r',[ sim_data.targetDist  sim_data.targetDist],'a',[ 1  1 ]);

[depth,~,~,~] = Simulator.runSim(model,sim_data);
end

