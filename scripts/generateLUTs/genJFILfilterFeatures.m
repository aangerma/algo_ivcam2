function lutOut = genJFILfilterFeatures()



% format long g;


%% depth lut
is_energy_preserved = [];


d.mean3Filter = 1/9*ones(3,3); %mean 3*3
is_energy_preserved(end+1) = 1;

% d.gaussian3Filter = fspecial('gaussian',[3 3]); %lpf 3*3
d.gaussian3Filter = [...
    0.0113437365584951        0.0838195058022106        0.0113437365584951;
    0.0838195058022106         0.619347030557177        0.0838195058022106;
    0.0113437365584951        0.0838195058022106        0.0113437365584951];
is_energy_preserved(end+1) = 1;

% d.laplacian3Filter = fspecial('laplacian',); %2nd spatial derrivative
d.laplacian3Filter = [...
    0.166666666666667         0.666666666666667         0.166666666666667;
    0.666666666666667         -3.33333333333333         0.666666666666667;
    0.166666666666667         0.666666666666667         0.166666666666667];
is_energy_preserved(end+1) = 0;

% d.gaussian5Filter = fspecial('gaussian',[5 5]); %lpf 5*5
d.gaussian5Filter = [...
    6.96247818879907e-08      2.80886417542669e-05      0.000207548549665044      2.80886417542669e-05      6.96247818879907e-08;
    2.80886417542669e-05        0.0113317668537736        0.0837310609825358        0.0113317668537736      2.80886417542669e-05;
    0.000207548549665044        0.0837310609825358          0.61869350682294        0.0837310609825358      0.000207548549665044;
    2.80886417542669e-05        0.0113317668537736        0.0837310609825358        0.0113317668537736      2.80886417542669e-05;
    6.96247818879907e-08      2.80886417542669e-05      0.000207548549665044      2.80886417542669e-05      6.96247818879907e-08];
is_energy_preserved(end+1) = 1;

d.mean5Filter = 1/25*ones(5,5); %mean 5*5
is_energy_preserved(end+1) = 1;

% d.log5Filter = fspecial('log',[5 5]); %laplacian of gaussian 5*5
d.log5Filter = [...
    0.0447924002742017        0.0468064275066824        0.0564067640816177        0.0468064275066824        0.0447924002742017;
    0.0468064275066824         0.316746449790941         0.714632533160662         0.316746449790941        0.0468064275066824;
    0.0564067640816177         0.714632533160662         -4.90476400928315         0.714632533160662        0.0564067640816177;
    0.0468064275066824         0.316746449790941         0.714632533160662         0.316746449790941        0.0468064275066824;
    0.0447924002742017        0.0468064275066824        0.0564067640816177        0.0468064275066824        0.0447924002742017];
is_energy_preserved(end+1) = 0;

%d.divy3Filter = fspecial('prewitt')
d.divy3Filter = [...
    0.5  0.5   0.5   0.5 0.5;
    1    1     1     1   1;
    0    0     0     0   0;
    -1   -1    -1    -1  -1;
    -0.5 -0.5  -0.5 -0.5 -0.5];
is_energy_preserved(end+1) = 0;

%d.divy3Filter = fspecial('prewitt').'
d.divx3Filter = [...
    0.5    1     0    -1  -0.5;
    0.5    1     0    -1  -0.5;
    0.5    1     0    -1  -0.5;
    0.5    1     0    -1  -0.5;
    0.5    1     0    -1  -0.5];
is_energy_preserved(end+1) = 0;

lutOut1 = build_lut(d,is_energy_preserved,'d');

%% ir lut
is_energy_preserved = [];


ir.mean3Filter = 1/9*ones(3,3); %mean
is_energy_preserved(end+1) = 1;

% i.laplacian3Filter = fspecial('laplacian'); %2nd spatial derrivative
ir.laplacian3Filter = [...
    0.166666666666667         0.666666666666667         0.166666666666667;
    0.666666666666667         -3.33333333333333         0.666666666666667;
    0.166666666666667         0.666666666666667         0.166666666666667];
is_energy_preserved(end+1) = 0;

lutOut2 = build_lut(ir,is_energy_preserved,'i');
lutOut = [lutOut1 lutOut2];
end



function lutOut = build_lut(s,is_energy_preserved,type)
convWsize = [5 5];

names = fieldnames(s);
% out = [];
lut = [];
%this is how the weights are in the LUT (in HEX)
%[w11 w21 w31 w41;
% w51 w12 w22 w32;
% w42 w52 w13 w23;
% w33 w43 w53 w14;
% ...
% w55 0   0   0  ; ...
%and the next filter concatenated
for j=1:length(names)
    s.(names{j}) = round(s.(names{j})/sum(vec(abs(s.(names{j}))))*127);
    s.(names{j}) = padarray(   s.(names{j}) , (convWsize-size(s.(names{j})))/2    );
    if(is_energy_preserved(j))
        s.(names{j})(3,3) = s.(names{j})(3,3) + 127 - sum(vec(s.(names{j})));
    else
        s.(names{j})(3,3) = s.(names{j})(3,3) + 0   - sum(vec(s.(names{j})));
    end
    
    lut = [lut;vec(s.(names{j})); 0; 0; 0];
    
    %     fours = reshape([vec(s.(names{j})); 0;0;0],4,[]);
    %     out = [...
    %         out;
    %         [dec2hexS(int8(fours(1,:)), 2) dec2hexS(int8(fours(2,:)), 2) dec2hexS(int8(fours(3,:)), 2) dec2hexS(int8(fours(4,:)), 2)]   ]; %saved as 8 bit each (signed)
end

% fileID = fopen(['../../tables/JFIL' type 'Features.lut'],'w');
%
% for j = 1:size(out,1)
%     fprintf(fileID,'%s\n',out(j,:));
% end
%
% fclose(fileID);
lutOut.lut = int8(lut);
lutOut.name = ['JFIL' type 'Features'];

end