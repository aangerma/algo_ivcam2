xim = 0
% results in
tan(alpha) = (p2axb) = rangeL  + single(regs.FRMW.marginL) / single(regs.FRMW.xres-1)*(rangeR-rangeL) ;
%{ 
When x is 0 and marginL is 0 we get the min laser angle.
When x is 0 and marginL is not 0 we get an angle which is a linear cobination of the min and max angle.
%}

xim = imHsize-1;
% results in
tan(alpha) = (xim*p2axa+p2axb) = (rangeR-rangeL)/ single(regs.FRMW.xres-1)*(imHsize-1)+...
                    rangeL  + single(regs.FRMW.marginL) / single(regs.FRMW.xres-1)*(rangeR-rangeL) = ...
                    rangeL + single(regs.FRMW.xres-1-marginR) / single(regs.FRMW.xres-1)*(rangeR-rangeL);
%{ 
When x is imHsize-1 and marginR is 0 we get the max laser angle.atan(rangeR).
When x is imHsize-1 and marginR is not 0 we get an angle which is a linear cobination of the min and max angle.
%}

%{
The same goes for y axis. Bottom replaces Left and Top replaces Right.
%}
%{
Note: Left means negative x angle and Bottom means negative y angle.                     
%}
fw = Firmware;                    
regs = fw.get();
[angx,angy] = Calibration.aux.xy2angSF(0,0,regs,1); 
% Since 0,0 receives 2 negative angle, and rangeB and rangeL corresponds to
% a negative angx ang angy, we can say that [0,0] is the leftmost and
% bottom most pixel. 
% So - the bottom of the image is actually the top when using imagesc. (Row
% 0 is on top).

% Outside algo, the image is rotated by 180 degrees so it would be aligned
% so the real world.
% Therefore, pixel 0,0 should be addressed as [imHsize-1,imVsize-1] and get its angles.

% Before (And that should stay as gettrigo uses it):
p2axa = (rangeR-rangeL)/ single(regs.FRMW.xres-1);
p2axb = rangeL  + single(regs.FRMW.marginL) / single(regs.FRMW.xres-1)*(rangeR-rangeL) ;
p2aya = (rangeT-rangeB)/ single(regs.FRMW.yres-1);
p2ayb = rangeB  + single(regs.FRMW.marginB) / single(regs.FRMW.yres-1)*(rangeT-rangeB) ;

% After (And that should stay as gettrigo uses it):
% remember, range R is positive and rangeL is negative. 
p2axa = (rangeR-rangeL)/ single(regs.FRMW.xres-1);
p2axb = -rangeR  + single(regs.FRMW.marginR) / single(regs.FRMW.xres-1)*(rangeR-rangeL) ;
p2aya = -(rangeT-rangeB)/ single(regs.FRMW.yres-1);
p2ayb = rangeT  - single(regs.FRMW.marginT) / single(regs.FRMW.yres-1)*(rangeT-rangeB) ;

Kinv=[p2axa            0                   p2axb;
      0                p2aya               p2ayb;
      0                0                   1    ];

K=pinv(Kinv);
regsOut.CBUF.spare=typecast(K([1 4 7 2 5 8 3 6]),'uint32');

