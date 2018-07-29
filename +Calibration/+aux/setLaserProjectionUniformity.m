function setLaserProjectionUniformity(hw,uniformProjection)
if(uniformProjection) %non-safe
%     [~,val]=hw.cmd('irb e2 0a 01');
%     newval=uint8(round((double(val(1))/63*150+150)/300*255));
%     hw.cmd(sprintf('iwb e2 08 01 %02x',newval));
     hw.cmd('iwb e2 08 01 ff');
     hw.cmd('iwb e2 03 01 13');% internal modulation (from register)
else
    hw.cmd('iwb e2 03 01 93');% extrnal modulation (from MA mod-sign)
end

end