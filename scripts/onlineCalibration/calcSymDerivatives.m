syms X Y Z
A = sym('A',[3,4]);
Krgb = sym('Krgb',[3,3]);
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

x1 = (x_in-Krgb(1,3))/Krgb(1,1);
y1 = (y_in-Krgb(2,3))/Krgb(2,2);

r_2 = x1^2+y1^2;
rc = 1+d(1,1)*r_2+d(1,2)*r_2^2+d(1,5)*r_2^3;
x2 = x1*rc;
y2 = y1*rc;
x3 = x2+2*d(1,3)*x1*y1+d(1,4)*(r_2+2*x1^2);
y3 = y2+2*d(1,4)*x1*y1+d(1,3)*(r_2+2*y1^2);

x_out = x3*Krgb(1,1)+Krgb(1,3);
y_out = y3*Krgb(2,2)+Krgb(2,3);

% dXout_dXin = diff(x_out,x_in);
