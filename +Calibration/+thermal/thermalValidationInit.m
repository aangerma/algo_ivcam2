function thermalValidationInit(hw,runParams)
hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass'); 
hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');
confScriptFldr = fullfile(runParams.outputFolder,'AlgoInternal','confAsDC.txt');
hw.runScript(confScriptFldr);
hw.shadowUpdate;
end