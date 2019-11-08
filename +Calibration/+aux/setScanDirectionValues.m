function [  ] = setScanDirectionValues( hw,addresses2write, values2write )

for i = 1:numel(addresses2write)
    cmdStr = sprintf('mwd %s %s',addresses2write{i}, values2write{i});
    hw.cmd( cmdStr );
end
projectorShadowUpdate(hw);

end


function projectorShadowUpdate(hw)
hw.cmd('mwd a00d01ec a00d01f0 1  					              // Shadow Update');
end