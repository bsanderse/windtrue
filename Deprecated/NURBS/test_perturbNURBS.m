% This routine computes perturbed samples obtained from perturbing control
% points of baseline curve

close all
clearvars
clc

x = [1.5 15.42 32.25 52.75 63]/63; % locations of known values of curve (e.g. locations where values of chord or twist are sampled)
S = [3.28 4.62 3.70 2.55 1.37]; % known function values at x
t0 = [0 1/3 2/3 1]; % Original knot vectors 
n = 3; % NURBS order: 2 for linear B-splines, 3 for Quadratic, so on. The polynomial degree of B-spline is n-1.

c = getControlPoints(x,S,t0,n); % control points for NURB curve

t = [t0(1)*ones(1,n-1) t0 t0(end)*ones(1,n-1)]; % Padded knot vector obtained by padding n-1 elements at front and end. 
j = 0: numel(t)- n-1; % Index of B-spline from 0 =< j < numel(t) - n

plot(x,c,'marker','o','linewidth',2) % plot control points
hold on
plot(x,S,'marker','x','markersize',8,'linestyle','none','linewidth',2) % plot sampled points
xu  = linspace(x(1), x(end), 100); % discrete query points. Interpolation is performed at these points.
Sxu = zeros(1,numel(xu)); % 'Sxu' is the func tion values of NURB curve interpolated at xu

for i = 1:numel(j)
    [y,xu] = bspline_basis(j(i),n,t,xu);
    Sxu = Sxu + c(i)*y;
end

plot(xu,Sxu,'linewidth',2,'color','r')
samples=10;
pc = 0.1*ones(numel(j),1); % Amount of purturbation for each control points, for example, 0.1 corresponds to plus-minus 5% of perturbation.
randVec = rand(samples,numel(j)) - 0.5; % Uniform distribution between [-0.5,0.5]
S = perturbNURBS(t0,n,xu,c, pc,samples, randVec);
plot(xu,S','color','k','linestyle','--','HandleVisibility','off')
plot(xu,S(1,:),'color','k','linestyle','--')
legend('control points','sampled data', 'NURB curve','random samples')
hold off