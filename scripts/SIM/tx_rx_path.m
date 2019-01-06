param_file_path = 'D:\data\simulatorParams\defult_params\params_860SKU1_indoor.xml';
sim_data = xml2structWrapper(param_file_path); % Simulation parameters

if sim_data.laser.codeLength ~= 52
    error('The code length does not fit');
end
tx_sq = Codes.propCode(26,1);
sim_data.laser.txSequence = create_52_code_from_26(tx_sq);

% laser


%---------------------------------------------------------------------------------------------------
% Functions:
function [new_code] = create_52_code_from_26(code_26)
new_code = false(52,1);
for k = 0:length(code_26)-1
    if tx_sq(k+1,1)
        new_code(2*k+1,1) = true;
        new_code(2*k+2,1) = true;
    else
        new_code(2*k+1,1) = false;
        new_code(2*k+2,1) = false;
    end
end
end