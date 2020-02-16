function [symVarVal] = calcValFromSym(symVarIn,subsParams)
varsInSym = symvar(symVarIn);
symVarOut = symVarIn;
f1 = subsParams.rgbPmat*subsParams.V';
x_in = f1(1,:)./f1(3,:);
y_in = f1(2,:)./f1(3,:);

x1Val = (x_in-subsParams.Krgb(1,3))/subsParams.Krgb(1,1);
y1Val = (y_in-subsParams.Krgb(2,3))/subsParams.Krgb(2,2);

for k = 1:numel(varsInSym)
    switch  char(varsInSym(k))
        case 'Rc'
            r2 = x1Val.^2+y1Val.^2;
            RcVal = 1+subsParams.d(1,1)*r2+subsParams.d(1,2)*r2.^2+subsParams.d(1,5)*r2.^3;
            symVarOut = subs(symVarOut,varsInSym(k),RcVal);
        case 'V'
            symVarOut = subs(symVarOut,varsInSym(k),subsParams.V');
        case 'x1'
            symVarOut = subs(symVarOut,varsInSym(k),x1Val);
        case 'y1'
            symVarOut = subs(symVarOut,varsInSym(k),y1Val);
        case {'a1_1', 'a1_2', 'a1_3', 'a1_4', 'a2_1', 'a2_2', 'a2_3', 'a2_4', 'a3_1', 'a3_2', 'a3_3', 'a3_4'}
            splittedTemp = strsplit(char(varsInSym(k)),'a');
            splittedTemp = strsplit(splittedTemp{end},'_');
            symVarOut = subs(symVarOut,varsInSym(k),subsParams.rgbPmat(str2double(splittedTemp{1}),str2double(splittedTemp{2})));
        case {'krgb1_1', 'krgb1_2', 'krgb1_3', 'krgb2_1', 'krgb2_2', 'krgb2_3', 'krgb3_1', 'krgb3_2', 'krgb3_3'}
            splittedTemp = strsplit(char(varsInSym(k)),'krgb');
            splittedTemp = strsplit(splittedTemp{end},'_');
            symVarOut = subs(symVarOut,varsInSym(k),subsParams.rgbPmat(str2double(splittedTemp{1}),str2double(splittedTemp{2})));
        case {'d1', 'd2', 'd3', 'd4', 'd5'}
            splittedTemp = strsplit(char(varsInSym(k)),'d');
            symVarOut = subs(symVarOut,varsInSym(k),subsParams.d(str2double(splittedTemp{end})));
        otherwise
            error(['No such sym named ' char(varsInSym(k))]);
    end
end
symVarVal = double(symVarOut);
end