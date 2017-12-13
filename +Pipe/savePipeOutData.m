function savePipeOutData(pipeOutData,baseDir,outputFn)
    if(~exist('outputFn','var'))
        [baseDir,outputFn,ext]=fileparts(baseDir);
        outputFn = [outputFn ,'.' ext];
    end

    
    
    towrite.bini     = (pipeOutData.iImg);
    towrite.binr     = (pipeOutData.rImg);
    towrite.binz     = (getZ4bin(pipeOutData.zImg));
    towrite.binv     = (pipeOutData.vImg);
    towrite.binc     = (pipeOutData.cImg);
    towrite.binvi    = pipeOutData;
    towrite.stl.xImg = (pipeOutData.vImg(:,:,1));
    towrite.stl.yImg = (pipeOutData.vImg(:,:,2));
    towrite.stl.zImg = (pipeOutData.vImg(:,:,3));
    towrite.stl.iImg = (pipeOutData.iImg);
    
    
    extenstions = fieldnames(towrite);
    for idx = 1:length(extenstions)
        curExt = extenstions{idx};
        filetosave = fullfile(baseDir,sprintf('%s.%s',outputFn,curExt));
        io.writeBin(filetosave,towrite.(curExt),'type',curExt);
    end
   
    [m,zimg] = planeFit(towrite.stl.xImg,towrite.stl.yImg,towrite.stl.zImg);
    zlims =prctile_(zimg(:),[10 90]);
    zimgN = min(1,max(0,(zimg-zlims(1))/diff(zlims)));
    cm = uint32([909522229   909522486   909522486   859059509   774910258   606546476   353967393    84413456    16908803    50463233   117835012   185207048   252579084   303108112   320017170   336860180   336860180   303174419   235868177   168496141   134744329   101123847   101058054   101058054   101058054   134678278   202050057   303042317   404165907   538844186   673588258   825175339   993605172  1178812478  1364085577  1566201684  1768317792  1953591148  2155706999  2324202882  2492632973  2661063063  2812650400  2964237482  3115824563  3267411387  3402155716  3536899788  3671643860  3806387932  3941132004  4075876076  4193842932  4278058235  4294967294  4278124287  4244438525  4193975291  4160289017  4126602999  4109759989  4126536948  4143379957  4193843447   791489578   892547632   993605686  1094729277  1212564803  1347308618  1498895442  1633639771  1717920866  1802135912  1869507948  1936879984  2004252020  2071624056  2138996092  2206368128  2273740164  2357889416  2442104461  2526385042  2593757335  2661129371  2728501407  2779030691  2829559718  2880088489  2913774763  2947526318  2997989552  3031675826  3065361844  3099047862  3132733880  3149642426  3183262908  3200105917  3200171710  3217014719  3217014719  3217014719  3217014719  3200237503  3200171710  3183394494  3183328701  3166485693  3149708476  3149642683  3132799675  3116022458  3115956665  3115956665  3149576889  3216882876  3301097920  3385378501  3469593802  3553808847  3654801109  3739081690  3840139744  3957975270  4092719085  4227463157  2425195143  2627311251  2846270368  3065229228  3284122809  3503081926  3688486611  3772833501  3789677025  3789677025  3755991264  3722370783  3688684765  3654933210  3621247192  3587561174  3553875156  3537032147  3537031890  3537031890  3503411665  3469725648  3419196878  3368667851  3301295815  3233923779  3166551743  3082336698  2998121654  2913906609  2812914347  2728633766  2627575712  2526517658  2425459604  2324401550  2223343496  2139128195  2054913150  1987541113  1920103541  1852797041  1785425005  1718052969  1667523941  1600151906  1549622879  1499028059  1431721816  1364349780  1296977744  1229605708  1128613448  1027489858   926431547   842216501   758001713   690629420   623257384   555885348   488513312   404298268   320083479   235868434]);
    cm=double(reshape(typecast(cm,'uint8'),256,3))/255;
    zimgRGB = gray2colormap(zimgN,cm);
    limstxt =str2img(sprintf('L/H image: %.2f/%.2f L/H global: %.2f/%.2f',minmax(zimgN)+abs(m(4)),minmax(zimg)+abs(m(4))));
    limstxt=cat(3,limstxt,limstxt,limstxt);
    n= min(size(limstxt,2),size(zimgRGB,2));
    if(size(limstxt,1)+1<=size(zimgRGB,1))
        zimgRGB(3:size(limstxt,1)+2,3:n+2,:)=limstxt(:,1:n,:);
    end
    imwrite(uint8(zimgRGB*255),fullfile(baseDir,sprintf('%s_depth.png',outputFn)));
    
    imwrite(uint8(towrite.bini),fullfile(baseDir,sprintf('%s_ir.png',outputFn)));
    
end

function z4bin=getZ4bin(zImg)
outRes = [960 1280];
    if(diff(size(zImg))<0)
        zImg = zImg';
    end
    if(any(size(zImg)>outRes))
        z4bin = zImg(1:min(size(zImg,1),outRes(1)),1:min(size(zImg,2),outRes(2)));
    else
        z4bin = zImg;
    end
    pdTL = floor((outRes-size(z4bin))/2);
    z4bin = pad_array(z4bin,pdTL,0,'pre');
    z4bin = pad_array(z4bin,outRes-size(z4bin),0,'post');
   
    z4bin=uint16(z4bin);
    z4bin=z4bin';
end