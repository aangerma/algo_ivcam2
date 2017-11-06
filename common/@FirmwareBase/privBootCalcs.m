function privBootCalcs(obj)

[regs,luts] = obj.privGetNocalcs();
autogenRegs = struct();
autogenLuts = struct();


[regs,autogenRegs] = generalRegisters(regs,autogenRegs);
if (isa(obj.m_bootCalcsFunction, 'function_handle'))
    [regs,autogenRegs,autogenLuts] = obj.m_bootCalcsFunction(regs,luts,autogenRegs,autogenLuts);
end
regs;%#ok
obj.setRegs(autogenRegs,'autogen');
obj.setLut(autogenLuts);

assert(all(cellfun(@(x) ischar(x),{obj.m_registers.value})),'all register values should be strings!');

assert(all([obj.m_registers.autogen]~=-1),sprintf('all autogen regsiters should get a value (%s)',obj.m_registers(find([obj.m_registers.autogen]==-1,1)).regName));

for i=1:length(obj.m_registers)
    if(strcmp(obj.m_registers(i).type,'single') && obj.m_registers(i).base~='f' && obj.m_registers(i).base~='h')
        error('boot cals error in %s: floating point registers should be initilized with floating point data(%s)',obj.m_registers(i).algoBlock,obj.m_registers(i).regName);
    end
end
end

function [regs,autogenRegs] = generalRegisters(regs,autogenRegs)
autogenRegs.GNRL.tmplLength = uint16(double(regs.GNRL.codeLength)*double(regs.GNRL.sampleRate));
autogenRegs.GNRL.zNorm = single(bitshift(1,regs.GNRL.zMaxSubMMExp));
regs = FirmwareBase.mergeRegs(regs,autogenRegs);
end

