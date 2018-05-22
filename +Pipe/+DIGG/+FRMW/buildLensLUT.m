function [autogenRegs,autogenLuts] = buildLensLUT(regs,luts)
shift = double(regs.DIGG.bitshift);
N = 32;%LUT size
toint32 = @(x) int32(x*2^shift);
if(regs.DIGG.undistBypass)
    xLUT=uint32(0:N*N-1);
    yLUT=uint32(N*N:2*N*N-1);
    fx = (N-1)/double(regs.GNRL.imgHsize-1);
    fy = (N-1)/double(regs.GNRL.imgVsize-1);
    x0=int32(0);
    y0=int32(0);
    x1=int32(regs.GNRL.imgHsize-1);
    y1=int32(regs.GNRL.imgVsize-1);
    
else
    
    %
    %{
     <-----distortionW---------->
(0,0)__      				  __
     \ \                     / /  ^
      \ \___________________/ /   |
      |                       |   |
      |   +---------------+   |   |
      |   |               |   |   |
      |   |  displacement |   | distortionH
      |   |     map       |   |   |
      |   |               |   |   |
      |   +---------------+   |   |
      /  ___________________  \   |
     /__/                   \__\  v
    %}
    
    %% caluculate total pixel area effected by undistort
    
    % % %     limang = bsxfun(@times,[1 1;-1 1;1 -1;-1 -1;0 1;0 -1],[ 2047 2047] );
    % % %     [limx,limy] = Pipe.DIGG.ang2xy(limang(:,1),limang(:,2),regs,Logger(),[]);
    % % %
    % % %     limx = double(limx)./(2^shift);
    % % %     limy = double(limy)./(2^shift);
    % % %     [x0,x1]=minmax(limx);
    % % %     [y0,y1]=minmax(limy);
    % % %     x0=floor(x0)-1;
    % % %     y0=floor(y0)-1;
    % % %     x1=ceil(x1)+1;
    % % %     y1=ceil(y1)+1;
    % % %
    % MARGINS ARE FIXED TO +-p%
    wh=double([regs.GNRL.imgHsize regs.GNRL.imgVsize]);
    pmargin = 0.1;
    x0 = -ceil(wh(1)*pmargin);
    x1 =  ceil(wh(1)*(1+pmargin));
    y0 = -ceil(wh(2)*pmargin);
    y1 =  ceil(wh(2)*(1+pmargin));
    
    
    distortionH=y1-y0;
    distortionW=x1-x0;
    fx = (N-1)/distortionW;
    fy = (N-1)/distortionH;
    if(~isfield(luts,'FRMW') || ~isfield(luts.FRMW,'undistModel') || all(luts.FRMW.undistModel==0))
        xDisplacment=zeros(32,'single');
        yDisplacment=zeros(32,'single');
    else
        xylut = typecast(luts.FRMW.undistModel,'single');
        xDisplacment = reshape(xylut(1:2:end),32,32);
        yDisplacment = reshape(xylut(2:2:end),32,32);
        
    end
    %% renormalize
    xDisplacment=xDisplacment*wh(1);
    yDisplacment=yDisplacment*wh(2);
    %%   build output ditortion grid
    [odgy,odgx]=ndgrid(linspace(y0,y1,N),linspace(x0,x1,N));
    %% build input distortion grid
    %     [idgy,idgx]=ndgrid(linspace(0,wh(2)-1,N),linspace(0,wh(1)-1,N));
%     idgy=odgy;idgx=odgx;
%     %% build output distotion grid
%     xLUT=idgx+interp2(idgx,idgy,xDisplacment,odgx,odgy,'spline');
%     yLUT=idgy+interp2(idgx,idgy,yDisplacment,odgx,odgy,'spline');
      xLUT=odgx+xDisplacment;
      yLUT=odgy+yDisplacment;
      yLUT=min(y1,max(y0,yLUT));
      xLUT=min(x1,max(x0,xLUT));
    
end

%%

autogenRegs.DIGG.xShiftIn  = toint32(0);
autogenRegs.DIGG.yShiftIn  = toint32(0);
autogenRegs.DIGG.xScaleIn  = toint32(1);
autogenRegs.DIGG.yScaleIn  = toint32(1);
autogenRegs.DIGG.xShiftOut = toint32(0);
autogenRegs.DIGG.yShiftOut = toint32(0);
autogenRegs.DIGG.xScaleOut = toint32(1);
autogenRegs.DIGG.yScaleOut = toint32(1);

autogenRegs.DIGG.undistFx = uint32(toint32(fx));
autogenRegs.DIGG.undistFy = uint32(toint32(fy));
autogenRegs.DIGG.undistX0 = toint32(x0);
autogenRegs.DIGG.undistY0 = toint32(y0);

data=vec([xLUT(:) yLUT(:)]');
memordr=typecast(uint32(hex2dec(['00020001';'000A0009';'00120011';'001A0019';'00220021';'002A0029';'00320031';'003A0039';'01020101';'010A0109';'01120111';'011A0119';'01220121';'012A0129';'01320131';'013A0139';'02020201';'020A0209';'02120211';'021A0219';'02220221';'022A0229';'02320231';'023A0239';'03020301';'030A0309';'03120311';'031A0319';'03220321';'032A0329';'03320331';'033A0339';'04020401';'040A0409';'04120411';'041A0419';'04220421';'042A0429';'04320431';'043A0439';'05020501';'050A0509';'05120511';'051A0519';'05220521';'052A0529';'05320531';'053A0539';'06020601';'060A0609';'06120611';'061A0619';'06220621';'062A0629';'06320631';'063A0639';'07020701';'070A0709';'07120711';'071A0719';'07220721';'072A0729';'07320731';'073A0739';'00040003';'000C000B';'00140013';'001C001B';'00240023';'002C002B';'00340033';'003C003B';'01040103';'010C010B';'01140113';'011C011B';'01240123';'012C012B';'01340133';'013C013B';'02040203';'020C020B';'02140213';'021C021B';'02240223';'022C022B';'02340233';'023C023B';'03040303';'030C030B';'03140313';'031C031B';'03240323';'032C032B';'03340333';'033C033B';'04040403';'040C040B';'04140413';'041C041B';'04240423';'042C042B';'04340433';'043C043B';'05040503';'050C050B';'05140513';'051C051B';'05240523';'052C052B';'05340533';'053C053B';'06040603';'060C060B';'06140613';'061C061B';'06240623';'062C062B';'06340633';'063C063B';'07040703';'070C070B';'07140713';'071C071B';'07240723';'072C072B';'07340733';'073C073B';'00060005';'000E000D';'00160015';'001E001D';'00260025';'002E002D';'00360035';'003E003D';'01060105';'010E010D';'01160115';'011E011D';'01260125';'012E012D';'01360135';'013E013D';'02060205';'020E020D';'02160215';'021E021D';'02260225';'022E022D';'02360235';'023E023D';'03060305';'030E030D';'03160315';'031E031D';'03260325';'032E032D';'03360335';'033E033D';'04060405';'040E040D';'04160415';'041E041D';'04260425';'042E042D';'04360435';'043E043D';'05060505';'050E050D';'05160515';'051E051D';'05260525';'052E052D';'05360535';'053E053D';'06060605';'060E060D';'06160615';'061E061D';'06260625';'062E062D';'06360635';'063E063D';'07060705';'070E070D';'07160715';'071E071D';'07260725';'072E072D';'07360735';'073E073D';'00080007';'0010000F';'00180017';'0020001F';'00280027';'0030002F';'00380037';'0040003F';'01080107';'0110010F';'01180117';'0120011F';'01280127';'0130012F';'01380137';'0140013F';'02080207';'0210020F';'02180217';'0220021F';'02280227';'0230022F';'02380237';'0240023F';'03080307';'0310030F';'03180317';'0320031F';'03280327';'0330032F';'03380337';'0340033F';'04080407';'0410040F';'04180417';'0420041F';'04280427';'0430042F';'04380437';'0440043F';'05080507';'0510050F';'05180517';'0520051F';'05280527';'0530052F';'05380537';'0540053F';'06080607';'0610060F';'06180617';'0620061F';'06280627';'0630062F';'06380637';'0640063F';'07080707';'0710070F';'07180717';'0720071F';'07280727';'0730072F';'07380737';'0740073F';'00420041';'004A0049';'00520051';'005A0059';'00620061';'006A0069';'00720071';'007A0079';'01420141';'014A0149';'01520151';'015A0159';'01620161';'016A0169';'01720171';'017A0179';'02420241';'024A0249';'02520251';'025A0259';'02620261';'026A0269';'02720271';'027A0279';'03420341';'034A0349';'03520351';'035A0359';'03620361';'036A0369';'03720371';'037A0379';'04420441';'044A0449';'04520451';'045A0459';'04620461';'046A0469';'04720471';'047A0479';'05420541';'054A0549';'05520551';'055A0559';'05620561';'056A0569';'05720571';'057A0579';'06420641';'064A0649';'06520651';'065A0659';'06620661';'066A0669';'06720671';'067A0679';'07420741';'074A0749';'07520751';'075A0759';'07620761';'076A0769';'07720771';'077A0779';'00440043';'004C004B';'00540053';'005C005B';'00640063';'006C006B';'00740073';'007C007B';'01440143';'014C014B';'01540153';'015C015B';'01640163';'016C016B';'01740173';'017C017B';'02440243';'024C024B';'02540253';'025C025B';'02640263';'026C026B';'02740273';'027C027B';'03440343';'034C034B';'03540353';'035C035B';'03640363';'036C036B';'03740373';'037C037B';'04440443';'044C044B';'04540453';'045C045B';'04640463';'046C046B';'04740473';'047C047B';'05440543';'054C054B';'05540553';'055C055B';'05640563';'056C056B';'05740573';'057C057B';'06440643';'064C064B';'06540653';'065C065B';'06640663';'066C066B';'06740673';'067C067B';'07440743';'074C074B';'07540753';'075C075B';'07640763';'076C076B';'07740773';'077C077B';'00460045';'004E004D';'00560055';'005E005D';'00660065';'006E006D';'00760075';'007E007D';'01460145';'014E014D';'01560155';'015E015D';'01660165';'016E016D';'01760175';'017E017D';'02460245';'024E024D';'02560255';'025E025D';'02660265';'026E026D';'02760275';'027E027D';'03460345';'034E034D';'03560355';'035E035D';'03660365';'036E036D';'03760375';'037E037D';'04460445';'044E044D';'04560455';'045E045D';'04660465';'046E046D';'04760475';'047E047D';'05460545';'054E054D';'05560555';'055E055D';'05660565';'056E056D';'05760575';'057E057D';'06460645';'064E064D';'06560655';'065E065D';'06660665';'066E066D';'06760675';'067E067D';'07460745';'074E074D';'07560755';'075E075D';'07660765';'076E076D';'07760775';'077E077D';'00480047';'0050004F';'00580057';'0060005F';'00680067';'0070006F';'00780077';'0080007F';'01480147';'0150014F';'01580157';'0160015F';'01680167';'0170016F';'01780177';'0180017F';'02480247';'0250024F';'02580257';'0260025F';'02680267';'0270026F';'02780277';'0280027F';'03480347';'0350034F';'03580357';'0360035F';'03680367';'0370036F';'03780377';'0380037F';'04480447';'0450044F';'04580457';'0460045F';'04680467';'0470046F';'04780477';'0480047F';'05480547';'0550054F';'05580557';'0560055F';'05680567';'0570056F';'05780577';'0580057F';'06480647';'0650064F';'06580657';'0660065F';'06680667';'0670066F';'06780677';'0680067F';'07480747';'0750074F';'07580757';'0760075F';'07680767';'0770076F';'07780777';'0780077F';'00820081';'008A0089';'00920091';'009A0099';'00A200A1';'00AA00A9';'00B200B1';'00BA00B9';'01820181';'018A0189';'01920191';'019A0199';'01A201A1';'01AA01A9';'01B201B1';'01BA01B9';'02820281';'028A0289';'02920291';'029A0299';'02A202A1';'02AA02A9';'02B202B1';'02BA02B9';'03820381';'038A0389';'03920391';'039A0399';'03A203A1';'03AA03A9';'03B203B1';'03BA03B9';'04820481';'048A0489';'04920491';'049A0499';'04A204A1';'04AA04A9';'04B204B1';'04BA04B9';'05820581';'058A0589';'05920591';'059A0599';'05A205A1';'05AA05A9';'05B205B1';'05BA05B9';'06820681';'068A0689';'06920691';'069A0699';'06A206A1';'06AA06A9';'06B206B1';'06BA06B9';'07820781';'078A0789';'07920791';'079A0799';'07A207A1';'07AA07A9';'07B207B1';'07BA07B9';'00840083';'008C008B';'00940093';'009C009B';'00A400A3';'00AC00AB';'00B400B3';'00BC00BB';'01840183';'018C018B';'01940193';'019C019B';'01A401A3';'01AC01AB';'01B401B3';'01BC01BB';'02840283';'028C028B';'02940293';'029C029B';'02A402A3';'02AC02AB';'02B402B3';'02BC02BB';'03840383';'038C038B';'03940393';'039C039B';'03A403A3';'03AC03AB';'03B403B3';'03BC03BB';'04840483';'048C048B';'04940493';'049C049B';'04A404A3';'04AC04AB';'04B404B3';'04BC04BB';'05840583';'058C058B';'05940593';'059C059B';'05A405A3';'05AC05AB';'05B405B3';'05BC05BB';'06840683';'068C068B';'06940693';'069C069B';'06A406A3';'06AC06AB';'06B406B3';'06BC06BB';'07840783';'078C078B';'07940793';'079C079B';'07A407A3';'07AC07AB';'07B407B3';'07BC07BB';'00860085';'008E008D';'00960095';'009E009D';'00A600A5';'00AE00AD';'00B600B5';'00BE00BD';'01860185';'018E018D';'01960195';'019E019D';'01A601A5';'01AE01AD';'01B601B5';'01BE01BD';'02860285';'028E028D';'02960295';'029E029D';'02A602A5';'02AE02AD';'02B602B5';'02BE02BD';'03860385';'038E038D';'03960395';'039E039D';'03A603A5';'03AE03AD';'03B603B5';'03BE03BD';'04860485';'048E048D';'04960495';'049E049D';'04A604A5';'04AE04AD';'04B604B5';'04BE04BD';'05860585';'058E058D';'05960595';'059E059D';'05A605A5';'05AE05AD';'05B605B5';'05BE05BD';'06860685';'068E068D';'06960695';'069E069D';'06A606A5';'06AE06AD';'06B606B5';'06BE06BD';'07860785';'078E078D';'07960795';'079E079D';'07A607A5';'07AE07AD';'07B607B5';'07BE07BD';'00880087';'0090008F';'00980097';'00A0009F';'00A800A7';'00B000AF';'00B800B7';'00C000BF';'01880187';'0190018F';'01980197';'01A0019F';'01A801A7';'01B001AF';'01B801B7';'01C001BF';'02880287';'0290028F';'02980297';'02A0029F';'02A802A7';'02B002AF';'02B802B7';'02C002BF';'03880387';'0390038F';'03980397';'03A0039F';'03A803A7';'03B003AF';'03B803B7';'03C003BF';'04880487';'0490048F';'04980497';'04A0049F';'04A804A7';'04B004AF';'04B804B7';'04C004BF';'05880587';'0590058F';'05980597';'05A0059F';'05A805A7';'05B005AF';'05B805B7';'05C005BF';'06880687';'0690068F';'06980697';'06A0069F';'06A806A7';'06B006AF';'06B806B7';'06C006BF';'07880787';'0790078F';'07980797';'07A0079F';'07A807A7';'07B007AF';'07B807B7';'07C007BF';'00C200C1';'00CA00C9';'00D200D1';'00DA00D9';'00E200E1';'00EA00E9';'00F200F1';'00FA00F9';'01C201C1';'01CA01C9';'01D201D1';'01DA01D9';'01E201E1';'01EA01E9';'01F201F1';'01FA01F9';'02C202C1';'02CA02C9';'02D202D1';'02DA02D9';'02E202E1';'02EA02E9';'02F202F1';'02FA02F9';'03C203C1';'03CA03C9';'03D203D1';'03DA03D9';'03E203E1';'03EA03E9';'03F203F1';'03FA03F9';'04C204C1';'04CA04C9';'04D204D1';'04DA04D9';'04E204E1';'04EA04E9';'04F204F1';'04FA04F9';'05C205C1';'05CA05C9';'05D205D1';'05DA05D9';'05E205E1';'05EA05E9';'05F205F1';'05FA05F9';'06C206C1';'06CA06C9';'06D206D1';'06DA06D9';'06E206E1';'06EA06E9';'06F206F1';'06FA06F9';'07C207C1';'07CA07C9';'07D207D1';'07DA07D9';'07E207E1';'07EA07E9';'07F207F1';'07FA07F9';'00C400C3';'00CC00CB';'00D400D3';'00DC00DB';'00E400E3';'00EC00EB';'00F400F3';'00FC00FB';'01C401C3';'01CC01CB';'01D401D3';'01DC01DB';'01E401E3';'01EC01EB';'01F401F3';'01FC01FB';'02C402C3';'02CC02CB';'02D402D3';'02DC02DB';'02E402E3';'02EC02EB';'02F402F3';'02FC02FB';'03C403C3';'03CC03CB';'03D403D3';'03DC03DB';'03E403E3';'03EC03EB';'03F403F3';'03FC03FB';'04C404C3';'04CC04CB';'04D404D3';'04DC04DB';'04E404E3';'04EC04EB';'04F404F3';'04FC04FB';'05C405C3';'05CC05CB';'05D405D3';'05DC05DB';'05E405E3';'05EC05EB';'05F405F3';'05FC05FB';'06C406C3';'06CC06CB';'06D406D3';'06DC06DB';'06E406E3';'06EC06EB';'06F406F3';'06FC06FB';'07C407C3';'07CC07CB';'07D407D3';'07DC07DB';'07E407E3';'07EC07EB';'07F407F3';'07FC07FB';'00C600C5';'00CE00CD';'00D600D5';'00DE00DD';'00E600E5';'00EE00ED';'00F600F5';'00FE00FD';'01C601C5';'01CE01CD';'01D601D5';'01DE01DD';'01E601E5';'01EE01ED';'01F601F5';'01FE01FD';'02C602C5';'02CE02CD';'02D602D5';'02DE02DD';'02E602E5';'02EE02ED';'02F602F5';'02FE02FD';'03C603C5';'03CE03CD';'03D603D5';'03DE03DD';'03E603E5';'03EE03ED';'03F603F5';'03FE03FD';'04C604C5';'04CE04CD';'04D604D5';'04DE04DD';'04E604E5';'04EE04ED';'04F604F5';'04FE04FD';'05C605C5';'05CE05CD';'05D605D5';'05DE05DD';'05E605E5';'05EE05ED';'05F605F5';'05FE05FD';'06C606C5';'06CE06CD';'06D606D5';'06DE06DD';'06E606E5';'06EE06ED';'06F606F5';'06FE06FD';'07C607C5';'07CE07CD';'07D607D5';'07DE07DD';'07E607E5';'07EE07ED';'07F607F5';'07FE07FD';'00C800C7';'00D000CF';'00D800D7';'00E000DF';'00E800E7';'00F000EF';'00F800F7';'010000FF';'01C801C7';'01D001CF';'01D801D7';'01E001DF';'01E801E7';'01F001EF';'01F801F7';'020001FF';'02C802C7';'02D002CF';'02D802D7';'02E002DF';'02E802E7';'02F002EF';'02F802F7';'030002FF';'03C803C7';'03D003CF';'03D803D7';'03E003DF';'03E803E7';'03F003EF';'03F803F7';'040003FF';'04C804C7';'04D004CF';'04D804D7';'04E004DF';'04E804E7';'04F004EF';'04F804F7';'050004FF';'05C805C7';'05D005CF';'05D805D7';'05E005DF';'05E805E7';'05F005EF';'05F805F7';'060005FF';'06C806C7';'06D006CF';'06D806D7';'06E006DF';'06E806E7';'06F006EF';'06F806F7';'070006FF';'07C807C7';'07D007CF';'07D807D7';'07E007DF';'07E807E7';'07F007EF';'07F807F7';'080007FF'])),'uint16');
autogenLuts.DIGG.undistModel = toint32(data(memordr));
% autogenLuts.DIGG.undistModel = toint32(data);



%{
 memordr=zeros(1024,2,'uint16');
 xordr=reshape(1:2:2048,32,32);yordr=reshape(2:2:2048,32,32);
     for i=1:16
         [yy,xx]=ind2sub([4 4],i);
         memordr((i-1)*64+(1:64),:)=[vec(xordr(s+yy-1,s+xx-1)) vec(yordr(s+yy-1,s+xx-1))];
     end
memordr=vec(memordr');
memordInv=uint16(arrayfun(@(i) find(memordr==i,1),1:2048));
mat2str(dec2hex(typecast(memordr,'uint32'),8))
mat2str(dec2hex(typecast(memordInv,'uint32'),8))
%}


%%
%check that LUT covers the entire range
lx = x0:x1;
ly = y0:y1;
[yold,xold]=ndgrid(ly,lx);
yold=bitshift(int64(yold),15);
xold=bitshift(int64(xold),15);
% xold=2047;yold=2047;
X = int32(bitshift(int64(xold).*int64(autogenRegs.DIGG.xScaleIn),-15)) + autogenRegs.DIGG.xShiftIn;
Y = int32(bitshift(int64(yold).*int64(autogenRegs.DIGG.yScaleIn),-15)) + autogenRegs.DIGG.yShiftIn;

XX = int64(X) - int64(autogenRegs.DIGG.undistX0);
YY = int64(Y) - int64(autogenRegs.DIGG.undistY0);
xaddr = bitshift(XX*int64(autogenRegs.DIGG.undistFx),-15);
yaddr = bitshift(YY*int64(autogenRegs.DIGG.undistFy),-15);
assert(all(xaddr(:)>=0 & xaddr(:)<=bitshift(32,shift)-1));
assert(all(yaddr(:)>=0 & yaddr(:)<=bitshift(32,shift)-1));

end
