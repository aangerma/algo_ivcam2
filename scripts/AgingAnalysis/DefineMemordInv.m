memordInv = typecast(uint32(hex2dec(['00020001';'00820081';'01020101';'01820181';'00040003';'00840083';'01040103';'01840183';'00060005';'00860085';'01060105';'01860185';'00080007';'00880087';'01080107';'01880187';...
                                     '000A0009';'008A0089';'010A0109';'018A0189';'000C000B';'008C008B';'010C010B';'018C018B';'000E000D';'008E008D';'010E010D';'018E018D';'0010000F';'0090008F';'0110010F';'0190018F';...
                                     '02020201';'02820281';'03020301';'03820381';'02040203';'02840283';'03040303';'03840383';'02060205';'02860285';'03060305';'03860385';'02080207';'02880287';'03080307';'03880387';...
                                     '020A0209';'028A0289';'030A0309';'038A0389';'020C020B';'028C028B';'030C030B';'038C038B';'020E020D';'028E028D';'030E030D';'038E038D';'0210020F';'0290028F';'0310030F';'0390038F';...
                                     '04020401';'04820481';'05020501';'05820581';'04040403';'04840483';'05040503';'05840583';'04060405';'04860485';'05060505';'05860585';'04080407';'04880487';'05080507';'05880587';...
                                     '040A0409';'048A0489';'050A0509';'058A0589';'040C040B';'048C048B';'050C050B';'058C058B';'040E040D';'048E048D';'050E050D';'058E058D';'0410040F';'0490048F';'0510050F';'0590058F';...
                                     '06020601';'06820681';'07020701';'07820781';'06040603';'06840683';'07040703';'07840783';'06060605';'06860685';'07060705';'07860785';'06080607';'06880687';'07080707';'07880787';...
                                     '060A0609';'068A0689';'070A0709';'078A0789';'060C060B';'068C068B';'070C070B';'078C078B';'060E060D';'068E068D';'070E070D';'078E078D';'0610060F';'0690068F';'0710070F';'0790078F';...
                                     '00120011';'00920091';'01120111';'01920191';'00140013';'00940093';'01140113';'01940193';'00160015';'00960095';'01160115';'01960195';'00180017';'00980097';'01180117';'01980197';...
                                     '001A0019';'009A0099';'011A0119';'019A0199';'001C001B';'009C009B';'011C011B';'019C019B';'001E001D';'009E009D';'011E011D';'019E019D';'0020001F';'00A0009F';'0120011F';'01A0019F';...
                                     '02120211';'02920291';'03120311';'03920391';'02140213';'02940293';'03140313';'03940393';'02160215';'02960295';'03160315';'03960395';'02180217';'02980297';'03180317';'03980397';...
                                     '021A0219';'029A0299';'031A0319';'039A0399';'021C021B';'029C029B';'031C031B';'039C039B';'021E021D';'029E029D';'031E031D';'039E039D';'0220021F';'02A0029F';'0320031F';'03A0039F';...
                                     '04120411';'04920491';'05120511';'05920591';'04140413';'04940493';'05140513';'05940593';'04160415';'04960495';'05160515';'05960595';'04180417';'04980497';'05180517';'05980597';...
                                     '041A0419';'049A0499';'051A0519';'059A0599';'041C041B';'049C049B';'051C051B';'059C059B';'041E041D';'049E049D';'051E051D';'059E059D';'0420041F';'04A0049F';'0520051F';'05A0059F';...
                                     '06120611';'06920691';'07120711';'07920791';'06140613';'06940693';'07140713';'07940793';'06160615';'06960695';'07160715';'07960795';'06180617';'06980697';'07180717';'07980797';...
                                     '061A0619';'069A0699';'071A0719';'079A0799';'061C061B';'069C069B';'071C071B';'079C079B';'061E061D';'069E069D';'071E071D';'079E079D';'0620061F';'06A0069F';'0720071F';'07A0079F';...
                                     '00220021';'00A200A1';'01220121';'01A201A1';'00240023';'00A400A3';'01240123';'01A401A3';'00260025';'00A600A5';'01260125';'01A601A5';'00280027';'00A800A7';'01280127';'01A801A7';...
                                     '002A0029';'00AA00A9';'012A0129';'01AA01A9';'002C002B';'00AC00AB';'012C012B';'01AC01AB';'002E002D';'00AE00AD';'012E012D';'01AE01AD';'0030002F';'00B000AF';'0130012F';'01B001AF';...
                                     '02220221';'02A202A1';'03220321';'03A203A1';'02240223';'02A402A3';'03240323';'03A403A3';'02260225';'02A602A5';'03260325';'03A603A5';'02280227';'02A802A7';'03280327';'03A803A7';...
                                     '022A0229';'02AA02A9';'032A0329';'03AA03A9';'022C022B';'02AC02AB';'032C032B';'03AC03AB';'022E022D';'02AE02AD';'032E032D';'03AE03AD';'0230022F';'02B002AF';'0330032F';'03B003AF';...
                                     '04220421';'04A204A1';'05220521';'05A205A1';'04240423';'04A404A3';'05240523';'05A405A3';'04260425';'04A604A5';'05260525';'05A605A5';'04280427';'04A804A7';'05280527';'05A805A7';...
                                     '042A0429';'04AA04A9';'052A0529';'05AA05A9';'042C042B';'04AC04AB';'052C052B';'05AC05AB';'042E042D';'04AE04AD';'052E052D';'05AE05AD';'0430042F';'04B004AF';'0530052F';'05B005AF';...
                                     '06220621';'06A206A1';'07220721';'07A207A1';'06240623';'06A406A3';'07240723';'07A407A3';'06260625';'06A606A5';'07260725';'07A607A5';'06280627';'06A806A7';'07280727';'07A807A7';...
                                     '062A0629';'06AA06A9';'072A0729';'07AA07A9';'062C062B';'06AC06AB';'072C072B';'07AC07AB';'062E062D';'06AE06AD';'072E072D';'07AE07AD';'0630062F';'06B006AF';'0730072F';'07B007AF';...
                                     '00320031';'00B200B1';'01320131';'01B201B1';'00340033';'00B400B3';'01340133';'01B401B3';'00360035';'00B600B5';'01360135';'01B601B5';'00380037';'00B800B7';'01380137';'01B801B7';...
                                     '003A0039';'00BA00B9';'013A0139';'01BA01B9';'003C003B';'00BC00BB';'013C013B';'01BC01BB';'003E003D';'00BE00BD';'013E013D';'01BE01BD';'0040003F';'00C000BF';'0140013F';'01C001BF';...
                                     '02320231';'02B202B1';'03320331';'03B203B1';'02340233';'02B402B3';'03340333';'03B403B3';'02360235';'02B602B5';'03360335';'03B603B5';'02380237';'02B802B7';'03380337';'03B803B7';...
                                     '023A0239';'02BA02B9';'033A0339';'03BA03B9';'023C023B';'02BC02BB';'033C033B';'03BC03BB';'023E023D';'02BE02BD';'033E033D';'03BE03BD';'0240023F';'02C002BF';'0340033F';'03C003BF';...
                                     '04320431';'04B204B1';'05320531';'05B205B1';'04340433';'04B404B3';'05340533';'05B405B3';'04360435';'04B604B5';'05360535';'05B605B5';'04380437';'04B804B7';'05380537';'05B805B7';...
                                     '043A0439';'04BA04B9';'053A0539';'05BA05B9';'043C043B';'04BC04BB';'053C053B';'05BC05BB';'043E043D';'04BE04BD';'053E053D';'05BE05BD';'0440043F';'04C004BF';'0540053F';'05C005BF';...
                                     '06320631';'06B206B1';'07320731';'07B207B1';'06340633';'06B406B3';'07340733';'07B407B3';'06360635';'06B606B5';'07360735';'07B607B5';'06380637';'06B806B7';'07380737';'07B807B7';...
                                     '063A0639';'06BA06B9';'073A0739';'07BA07B9';'063C063B';'06BC06BB';'073C073B';'07BC07BB';'063E063D';'06BE06BD';'073E073D';'07BE07BD';'0640063F';'06C006BF';'0740073F';'07C007BF';...
                                     '00420041';'00C200C1';'01420141';'01C201C1';'00440043';'00C400C3';'01440143';'01C401C3';'00460045';'00C600C5';'01460145';'01C601C5';'00480047';'00C800C7';'01480147';'01C801C7';...
                                     '004A0049';'00CA00C9';'014A0149';'01CA01C9';'004C004B';'00CC00CB';'014C014B';'01CC01CB';'004E004D';'00CE00CD';'014E014D';'01CE01CD';'0050004F';'00D000CF';'0150014F';'01D001CF';...
                                     '02420241';'02C202C1';'03420341';'03C203C1';'02440243';'02C402C3';'03440343';'03C403C3';'02460245';'02C602C5';'03460345';'03C603C5';'02480247';'02C802C7';'03480347';'03C803C7';...
                                     '024A0249';'02CA02C9';'034A0349';'03CA03C9';'024C024B';'02CC02CB';'034C034B';'03CC03CB';'024E024D';'02CE02CD';'034E034D';'03CE03CD';'0250024F';'02D002CF';'0350034F';'03D003CF';...
                                     '04420441';'04C204C1';'05420541';'05C205C1';'04440443';'04C404C3';'05440543';'05C405C3';'04460445';'04C604C5';'05460545';'05C605C5';'04480447';'04C804C7';'05480547';'05C805C7';...
                                     '044A0449';'04CA04C9';'054A0549';'05CA05C9';'044C044B';'04CC04CB';'054C054B';'05CC05CB';'044E044D';'04CE04CD';'054E054D';'05CE05CD';'0450044F';'04D004CF';'0550054F';'05D005CF';...
                                     '06420641';'06C206C1';'07420741';'07C207C1';'06440643';'06C406C3';'07440743';'07C407C3';'06460645';'06C606C5';'07460745';'07C607C5';'06480647';'06C806C7';'07480747';'07C807C7';...
                                     '064A0649';'06CA06C9';'074A0749';'07CA07C9';'064C064B';'06CC06CB';'074C074B';'07CC07CB';'064E064D';'06CE06CD';'074E074D';'07CE07CD';'0650064F';'06D006CF';'0750074F';'07D007CF';...
                                     '00520051';'00D200D1';'01520151';'01D201D1';'00540053';'00D400D3';'01540153';'01D401D3';'00560055';'00D600D5';'01560155';'01D601D5';'00580057';'00D800D7';'01580157';'01D801D7';...
                                     '005A0059';'00DA00D9';'015A0159';'01DA01D9';'005C005B';'00DC00DB';'015C015B';'01DC01DB';'005E005D';'00DE00DD';'015E015D';'01DE01DD';'0060005F';'00E000DF';'0160015F';'01E001DF';...
                                     '02520251';'02D202D1';'03520351';'03D203D1';'02540253';'02D402D3';'03540353';'03D403D3';'02560255';'02D602D5';'03560355';'03D603D5';'02580257';'02D802D7';'03580357';'03D803D7';...
                                     '025A0259';'02DA02D9';'035A0359';'03DA03D9';'025C025B';'02DC02DB';'035C035B';'03DC03DB';'025E025D';'02DE02DD';'035E035D';'03DE03DD';'0260025F';'02E002DF';'0360035F';'03E003DF';...
                                     '04520451';'04D204D1';'05520551';'05D205D1';'04540453';'04D404D3';'05540553';'05D405D3';'04560455';'04D604D5';'05560555';'05D605D5';'04580457';'04D804D7';'05580557';'05D805D7';...
                                     '045A0459';'04DA04D9';'055A0559';'05DA05D9';'045C045B';'04DC04DB';'055C055B';'05DC05DB';'045E045D';'04DE04DD';'055E055D';'05DE05DD';'0460045F';'04E004DF';'0560055F';'05E005DF';...
                                     '06520651';'06D206D1';'07520751';'07D207D1';'06540653';'06D406D3';'07540753';'07D407D3';'06560655';'06D606D5';'07560755';'07D607D5';'06580657';'06D806D7';'07580757';'07D807D7';...
                                     '065A0659';'06DA06D9';'075A0759';'07DA07D9';'065C065B';'06DC06DB';'075C075B';'07DC07DB';'065E065D';'06DE06DD';'075E075D';'07DE07DD';'0660065F';'06E006DF';'0760075F';'07E007DF';...
                                     '00620061';'00E200E1';'01620161';'01E201E1';'00640063';'00E400E3';'01640163';'01E401E3';'00660065';'00E600E5';'01660165';'01E601E5';'00680067';'00E800E7';'01680167';'01E801E7';...
                                     '006A0069';'00EA00E9';'016A0169';'01EA01E9';'006C006B';'00EC00EB';'016C016B';'01EC01EB';'006E006D';'00EE00ED';'016E016D';'01EE01ED';'0070006F';'00F000EF';'0170016F';'01F001EF';...
                                     '02620261';'02E202E1';'03620361';'03E203E1';'02640263';'02E402E3';'03640363';'03E403E3';'02660265';'02E602E5';'03660365';'03E603E5';'02680267';'02E802E7';'03680367';'03E803E7';...
                                     '026A0269';'02EA02E9';'036A0369';'03EA03E9';'026C026B';'02EC02EB';'036C036B';'03EC03EB';'026E026D';'02EE02ED';'036E036D';'03EE03ED';'0270026F';'02F002EF';'0370036F';'03F003EF';...
                                     '04620461';'04E204E1';'05620561';'05E205E1';'04640463';'04E404E3';'05640563';'05E405E3';'04660465';'04E604E5';'05660565';'05E605E5';'04680467';'04E804E7';'05680567';'05E805E7';...
                                     '046A0469';'04EA04E9';'056A0569';'05EA05E9';'046C046B';'04EC04EB';'056C056B';'05EC05EB';'046E046D';'04EE04ED';'056E056D';'05EE05ED';'0470046F';'04F004EF';'0570056F';'05F005EF';...
                                     '06620661';'06E206E1';'07620761';'07E207E1';'06640663';'06E406E3';'07640763';'07E407E3';'06660665';'06E606E5';'07660765';'07E607E5';'06680667';'06E806E7';'07680767';'07E807E7';...
                                     '066A0669';'06EA06E9';'076A0769';'07EA07E9';'066C066B';'06EC06EB';'076C076B';'07EC07EB';'066E066D';'06EE06ED';'076E076D';'07EE07ED';'0670066F';'06F006EF';'0770076F';'07F007EF';...
                                     '00720071';'00F200F1';'01720171';'01F201F1';'00740073';'00F400F3';'01740173';'01F401F3';'00760075';'00F600F5';'01760175';'01F601F5';'00780077';'00F800F7';'01780177';'01F801F7';...
                                     '007A0079';'00FA00F9';'017A0179';'01FA01F9';'007C007B';'00FC00FB';'017C017B';'01FC01FB';'007E007D';'00FE00FD';'017E017D';'01FE01FD';'0080007F';'010000FF';'0180017F';'020001FF';...
                                     '02720271';'02F202F1';'03720371';'03F203F1';'02740273';'02F402F3';'03740373';'03F403F3';'02760275';'02F602F5';'03760375';'03F603F5';'02780277';'02F802F7';'03780377';'03F803F7';...
                                     '027A0279';'02FA02F9';'037A0379';'03FA03F9';'027C027B';'02FC02FB';'037C037B';'03FC03FB';'027E027D';'02FE02FD';'037E037D';'03FE03FD';'0280027F';'030002FF';'0380037F';'040003FF';...
                                     '04720471';'04F204F1';'05720571';'05F205F1';'04740473';'04F404F3';'05740573';'05F405F3';'04760475';'04F604F5';'05760575';'05F605F5';'04780477';'04F804F7';'05780577';'05F805F7';...
                                     '047A0479';'04FA04F9';'057A0579';'05FA05F9';'047C047B';'04FC04FB';'057C057B';'05FC05FB';'047E047D';'04FE04FD';'057E057D';'05FE05FD';'0480047F';'050004FF';'0580057F';'060005FF';...
                                     '06720671';'06F206F1';'07720771';'07F207F1';'06740673';'06F406F3';'07740773';'07F407F3';'06760675';'06F606F5';'07760775';'07F607F5';'06780677';'06F806F7';'07780777';'07F807F7';...
                                     '067A0679';'06FA06F9';'077A0779';'07FA07F9';'067C067B';'06FC06FB';'077C077B';'07FC07FB';'067E067D';'06FE06FD';'077E077D';'07FE07FD';'0680067F';'070006FF';'0780077F';'080007FF'])),'uint16');
save('memordInv.mat','memordInv')