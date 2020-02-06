syms X Y Z

A = sym('a',[3,4]);
Krgb = sym('krgb',[3,3]);
d = sym('d',[1,5]);
%%

V = [X;Y;Z;1];
f1 = A*V;
x_in = f1(1,1)/f1(3,1);
y_in = f1(2,1)/f1(3,1);

dXin_dA = simplify([ diff(x_in,A(1,1)),diff(x_in,A(1,2)) , diff(x_in,A(1,3)),diff(x_in,A(1,4));...
            diff(x_in,A(2,1)) , diff(x_in,A(2,2)) , diff(x_in,A(2,3)), diff(x_in,A(2,4));...
            diff(x_in,A(3,1)) , diff(x_in,A(3,2)) , diff(x_in,A(3,3)) , diff(x_in,A(3,4))]);

dYin_dA = simplify([ diff(y_in,A(1,1)),diff(y_in,A(1,2)) , diff(y_in,A(1,3)),diff(y_in,A(1,4));...
            diff(y_in,A(2,1)) , diff(y_in,A(2,2)) , diff(y_in,A(2,3)), diff(y_in,A(2,4));...
            diff(y_in,A(3,1)) , diff(y_in,A(3,2)) , diff(y_in,A(3,3)) , diff(y_in,A(3,4))]);

%%
syms x3 y3
x_out = x3*Krgb(1,1)+Krgb(1,3);
y_out = y3*Krgb(2,2)+Krgb(2,3);

dXout_dX3 = diff(x_out,x3);
dYout_dY3 = diff(y_out,y3);
%%
syms x2 y2 x1 y1
r_2 = x1^2+y1^2;
x3 = x2+2*d(1,3)*x1*y1+d(1,4)*(r_2+2*x1^2);
y3 = y2+2*d(1,4)*x1*y1+d(1,3)*(r_2+2*y1^2);


dX3_dX1 = diff(x3,x1);
dY3_dY1 = diff(y3,y1);
dX3_dY1 = diff(x3,y1);
dY3_dX1 = diff(y3,x1);
% dX3_dX2 = diff(x3,x2);
% dY3_dY2 = diff(y3,y2);
%%
rc = 1+d(1,1)*r_2+d(1,2)*r_2^2+d(1,5)*r_2^3;
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

dXout_dXin = subs(dXout_dXin, 1+d(1,1)*r_2+d(1,2)*r_2^2+d(1,5)*r_2^3,Rc);
dYout_dYin = subs(dYout_dYin, 1+d(1,1)*r_2+d(1,2)*r_2^2+d(1,5)*r_2^3,Rc);
dXout_dYin = subs(dXout_dYin, 1+d(1,1)*r_2+d(1,2)*r_2^2+d(1,5)*r_2^3,Rc);
dYout_dXin = subs(dYout_dXin, 1+d(1,1)*r_2+d(1,2)*r_2^2+d(1,5)*r_2^3,Rc);

xCoeff = simplify(dXout_dXin*dXin_dA + dXout_dYin*dYin_dA);
ycoeff = simplify(dYout_dXin*dXin_dA + dYout_dYin*dYin_dA);
