function [depth, p] = run1DSimTxRx(target_dist,code_length, comparator_freq, time_smpl)
% Define default parameters
num_inputs = nargin();
if  num_inputs < 4
    time_smpl = struct('isTimeLength', true, 'value', 2000);%[nSec] or number of code repetitions
    if num_inputs < 3
        comparator_freq = 8; %[GHz]
        if num_inputs < 2
            code_length = 52;
            if num_inputs < 1
                target_dist = 1000; %[mm]
            end
        end
    end
end

p = xml2structWrapper('D:\data\simulatorParams\params_860SKU1_indoor_Maya.xml'); % Simulation parameters
p.laser.txSequence = Codes.propCode(code_length,1);
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
p.laser.txSequence = unbalanced_code;
%}

p.verbose = false;

p.Comparator.frequency = comparator_freq;

if time_smpl.isTimeLength
    p.runTime = time_smpl.value; 
else
    p.runTime = (length(p.laser.txSequence)/p.laser.frequency)*time_smpl.value;
end

model = struct('t',[0 p.runTime],'r',[ target_dist  target_dist],'a',[ 1  1 ]);

[depth,~,~,~] = Simulator.runSim(model,p);
end

