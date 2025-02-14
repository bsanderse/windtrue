function S = perturbNURBS(t0,n,xu,c, pc,samples, randVec)
% This routine perturbs (using a uniform distribution) the control points 
% obtained from the baseline curves and generates perturbed smooth curvesin

% Input:
% 't' is the knot vector
% 'n' is the NURBS order: 2 for linear B-splines, 3 for Quadratic, so on. The polynomial degree of B-spline is n-1.
% 'c' control point vector
% 'pc' vector containing perturbation fraction for each control points
% 'xu' discrete query points
% 'samples' number of samples of 
% 'randVec' a samples-by-numel(c) matrix of random numbers

% Output:
% 'S' a samples-by-numel(xu) matrix where elements in each row corresponds to one sample 

t = [t0(1)*ones(1,n-1) t0 t0(end)*ones(1,n-1)]; % padded knot vector obtained by padding n-1 elements at front and end. 
j = 0: numel(t)- n - 1; % Index of B-spline from 0 = < j < numel(t)-n
S = zeros(samples,numel(xu));

for k = 1:samples
    for i = 1:numel(j)
        [y,xu] = bspline_basis(j(i),n,t,xu);
        % note: Delta in the Torque paper is pc(i)*randVec(k,i)
        S(k,:) = S(k,:) + (c(i)+ pc(i).*c(i)*(randVec(k,i)))*y;
    end
end