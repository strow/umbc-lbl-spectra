function z = y1(x0)

%bessel fcn of second kind, n = 1

ii = (x0 <  0);
x = abs(x0);

i8 = (x >= 8.0);
xbig = x(i8);
i8 = (x < 8.0);
xbig = x(i8);

y = x.*x;
ans1 =   x.*(-0.4900604943e13 + y.*(0.1275274390e13 ...
       + y.*(-0.5153438139e11 + y.*(0.7349264551e9  ...
       + y.*(-0.4237922726e7  + y*0.8511937935e4)))));
ans2 =      0.2499580570e14   + y.*(0.4244419664e12    ...
       + y.*(0.3733650367e10 + y.*(0.2245904002e8  ...
       + y.*(0.1020426050e6  + y.*(0.3549632885e3 + y)))));

z = ans1./ans2 + 0.636619772.*(j1(x).*log(x) - 1.0./x);
z(ii) = -z(ii); 