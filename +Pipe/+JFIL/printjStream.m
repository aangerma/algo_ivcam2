function printjStream(lgr,jStream)
%         lgrImgPixIndx=min(lgrImgPixIndx,length(jStream.depth));
%         lgr.print2file('Valid pixels: %.2f\n',nnz(jStream.conf)/numel(jStream.conf)*100);
%         lgr.print2file('\tPixel #%7d: ',lgrImgPixIndx);
%         lgr.print2file('z =  0x%4x / ',jStream.depth(lgrImgPixIndx));
%         lgr.print2file('i =   0x%3x / ',jStream.ir(lgrImgPixIndx));
%         lgr.print2file('c =     0x%1x\n',jStream.conf(lgrImgPixIndx));

        lgr.print2file('\tImage mean:     ');
        lgr.print2file('z = %7.2f / ',mean(jStream.depth(:)));
        lgr.print2file('i = %7.2f / ',mean(jStream.ir(:)));
        lgr.print2file('c = %7.2f\n',mean(jStream.conf(:)));

        lgr.print2file('\tImage std:      ');
        lgr.print2file('z = %7.2f / ',std(double(jStream.depth(:))));
        lgr.print2file('i = %7.2f / ',std(double(jStream.ir(:))));
        lgr.print2file('c = %7.2f\n',std(double(jStream.conf(:))));
        
        

end