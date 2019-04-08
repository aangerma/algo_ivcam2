function [] = turnFilters(hw, on)

bypass = ~on;

hw.setReg('RASTbiltBypass'     ,bypass);
hw.setReg('JFILbilt1bypass'    ,bypass);
hw.setReg('JFILbilt2bypass'    ,bypass);
hw.setReg('JFILbilt3bypass'    ,bypass);
hw.setReg('JFILbiltIRbypass'   ,bypass);
hw.setReg('JFILgeomBypass'     ,bypass);
hw.shadowUpdate();

end

