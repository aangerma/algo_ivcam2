function [xCoeff, yCoeff, dXin_dDeriveBy, dYin_dDeriveBy] = calcSymDerivatives(deriveByVar)

V = sym('v',[4,1]);
Krgb = sym('krgb',[3,3]);
d = sym('d',[1,5]);
switch deriveByVar
    case 'A'
        A = sym('a',[3,4]);
    case 'Krgb'
        R = sym('r',[3,3]);
        T = sym('t',[3,1]);
        A = Krgb*[R T];
    case 'T'
        R = sym('r',[3,3]);
        T = sym('t',[3,1]);
        A = Krgb*[R T];
    case 'R'
        syms xAlpha yBeta zGamma
        Rx = [1 0 0; 0 cos(xAlpha) -sin(xAlpha); 0 sin(xAlpha) cos(xAlpha)];
        Ry = [cos(yBeta) 0 sin(yBeta); 0 1 0; -sin(yBeta) 0 cos(yBeta) ];
        Rz = [cos(zGamma) -sin(zGamma) 0; sin(zGamma) cos(zGamma) 0; 0 0 1];
        R = Rx*Ry*Rz;
        T = sym('t',[3,1]);
        A = Krgb*[R T];
    otherwise
        error('No such option!!!');
end
%%
f1 = A*V;
x_in = f1(1,1)/f1(3,1);
y_in = f1(2,1)/f1(3,1);

switch deriveByVar
    case 'A'
        dXin_dA = simplify([ diff(x_in,A(1,1)),diff(x_in,A(1,2)) , diff(x_in,A(1,3)),diff(x_in,A(1,4));...
            diff(x_in,A(2,1)) , diff(x_in,A(2,2)) , diff(x_in,A(2,3)), diff(x_in,A(2,4));...
            diff(x_in,A(3,1)) , diff(x_in,A(3,2)) , diff(x_in,A(3,3)) , diff(x_in,A(3,4))]);
        
        dYin_dA = simplify([ diff(y_in,A(1,1)),diff(y_in,A(1,2)) , diff(y_in,A(1,3)),diff(y_in,A(1,4));...
            diff(y_in,A(2,1)) , diff(y_in,A(2,2)) , diff(y_in,A(2,3)), diff(y_in,A(2,4));...
            diff(y_in,A(3,1)) , diff(y_in,A(3,2)) , diff(y_in,A(3,3)) , diff(y_in,A(3,4))]);
        
    case 'Krgb'
        dXin_dKrgb = simplify([ diff(x_in,Krgb(1,1)),diff(x_in,Krgb(1,2)) , diff(x_in,Krgb(1,3));...
            diff(x_in,Krgb(2,1)) , diff(x_in,Krgb(2,2)) , diff(x_in,Krgb(2,3));...
            diff(x_in,Krgb(3,1)) , diff(x_in,Krgb(3,2)) , diff(x_in,Krgb(3,3))]);
        
        dYin_dKrgb = simplify([ diff(y_in,Krgb(1,1)),diff(y_in,Krgb(1,2)) , diff(y_in,Krgb(1,3));...
            diff(y_in,Krgb(2,1)) , diff(y_in,Krgb(2,2)) , diff(y_in,Krgb(2,3));...
            diff(y_in,Krgb(3,1)) , diff(y_in,Krgb(3,2)) , diff(y_in,Krgb(3,3))]);
    case 'T'
        dXin_dT = simplify([ diff(x_in,T(1,1)),diff(x_in,T(2,1)) , diff(x_in,T(3,1))]);
        
        dYin_dT = simplify([ diff(y_in,T(1,1)),diff(y_in,T(2,1)) , diff(y_in,T(3,1))]);
        
    case 'R'
        [dXin_dxAlpha,dYin_dxAlpha] = dXYindRotAng(xAlpha, f1);
        [dXin_dyBeta,dYin_dyBeta] = dXYindRotAng(yBeta, f1);
        [dXin_dzGamma,dYin_dzGamma] = dXYindRotAng(zGamma, f1);        
    otherwise
        error('No such option!!!');
end


%%
syms x3 y3
x_out = x3*Krgb(1,1)+Krgb(1,3);
y_out = y3*Krgb(2,2)+Krgb(2,3);

dXout_dX3 = diff(x_out,x3);
dYout_dY3 = diff(y_out,y3);
%%
syms x2 y2 x1 y1
r2 = x1^2+y1^2;
x3 = x2+2*d(1,3)*x1*y1+d(1,4)*(r2+2*x1^2);
y3 = y2+2*d(1,4)*x1*y1+d(1,3)*(r2+2*y1^2);


dX3_dX1 = diff(x3,x1);
dY3_dY1 = diff(y3,y1);
dX3_dY1 = diff(x3,y1);
dY3_dX1 = diff(y3,x1);
% dX3_dX2 = diff(x3,x2);
% dY3_dY2 = diff(y3,y2);
%%
rc = 1+d(1,1)*r2+d(1,2)*r2^2+d(1,5)*r2^3;
x2 = x1*rc;
y2 = y1*rc;

dX2_dX1 = diff(x2,x1);
dY2_dY1 = diff(y2,y1);
dX2_dY1 = diff(x2,y1);
dY2_dX1 = diff(y2,x1);
%%
syms x_in y_in

x1 = (x_in-Krgb(1,3))/Krgb(1,1);
y1 = (y_in-Krgb(2,3))/Krgb(2,2);

dX1_dXin = diff(x1,x_in);
dY1_dYin = diff(y1,y_in);
%%
syms Rc

dXout_dXin = dXout_dX3*(dX3_dX1+dX2_dX1)*dX1_dXin;
dYout_dYin = dYout_dY3*(dY3_dY1+dY2_dY1)*dY1_dYin;

dXout_dYin = dXout_dX3*(dX3_dY1+dX2_dY1)*dY1_dYin;
dYout_dXin = dYout_dY3*(dY3_dX1+dY2_dX1)*dX1_dXin;

dXout_dXin = subs(dXout_dXin, 1+d(1,1)*r2+d(1,2)*r2^2+d(1,5)*r2^3,Rc);
dYout_dYin = subs(dYout_dYin, 1+d(1,1)*r2+d(1,2)*r2^2+d(1,5)*r2^3,Rc);
dXout_dYin = subs(dXout_dYin, 1+d(1,1)*r2+d(1,2)*r2^2+d(1,5)*r2^3,Rc);
dYout_dXin = subs(dYout_dXin, 1+d(1,1)*r2+d(1,2)*r2^2+d(1,5)*r2^3,Rc);
%%
switch deriveByVar
    case 'A'
        xCoeff = simplify(dXout_dXin.*dXin_dA + dXout_dYin.*dYin_dA);
        yCoeff = simplify(dYout_dXin.*dXin_dA + dYout_dYin.*dYin_dA);
        dXin_dDeriveBy = dXin_dA;
        dYin_dDeriveBy = dYin_dA;
    case 'Krgb'
        xCoeff = simplify(dXout_dXin.*dXin_dKrgb + dXout_dYin.*dYin_dKrgb);
        yCoeff = simplify(dYout_dXin.*dXin_dKrgb + dYout_dYin.*dYin_dKrgb);
        dXin_dDeriveBy = dXin_dKrgb;
        dYin_dDeriveBy = dYin_dKrgb;
    case 'T'
        xCoeff = simplify(dXout_dXin.*dXin_dT + dXout_dYin.*dYin_dT);
        yCoeff = simplify(dYout_dXin.*dXin_dT + dYout_dYin.*dYin_dT);
        dXin_dDeriveBy = dXin_dT;
        dYin_dDeriveBy = dYin_dT;
    case 'R'
        xCoeff.xAlpha = simplify(dXout_dXin.*dXin_dxAlpha + dXout_dYin.*dYin_dxAlpha);
        yCoeff.xAlpha = simplify(dYout_dXin.*dXin_dxAlpha + dYout_dYin.*dYin_dxAlpha);
        dXin_dDeriveBy.xAlpha = dXin_dxAlpha;
        dYin_dDeriveBy.xAlpha = dYin_dxAlpha;
        
        xCoeff.yBeta = simplify(dXout_dXin.*dXin_dyBeta + dXout_dYin.*dYin_dyBeta);
        yCoeff.yBeta = simplify(dYout_dXin.*dXin_dyBeta + dYout_dYin.*dYin_dyBeta);
        dXin_dDeriveBy.yBeta = dXin_dxAlpha;
        dYin_dDeriveBy.yBeta = dYin_dxAlpha;
        
        xCoeff.zGamma = simplify(dXout_dXin.*dXin_dzGamma + dXout_dYin.*dYin_dzGamma);
        yCoeff.zGamma = simplify(dYout_dXin.*dXin_dzGamma + dYout_dYin.*dYin_dzGamma);
        dXin_dDeriveBy.zGamma = dXin_dxAlpha;
        dYin_dDeriveBy.zGamma = dYin_dxAlpha;
    otherwise
        error('No such option!!!');
end

end

function [dXin_drotAng,dYin_drotAng] = dXYindRotAng(rotAng, ptVec)
dptVecX_drotAng = diff(ptVec(1,1),rotAng);
dptVecz_drotAng = diff(ptVec(3,1),rotAng);
dXin_drotAng = (dptVecX_drotAng*ptVec(3,1)-dptVecz_drotAng*ptVec(1,1))/ptVec(3,1)^2;
dptVecY_drotAng = diff(ptVec(2,1),rotAng);
dYin_drotAng = (dptVecY_drotAng*ptVec(3,1)-dptVecz_drotAng*ptVec(2,1))/ptVec(3,1)^2;
end