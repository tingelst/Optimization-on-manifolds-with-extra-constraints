dim = 200;
A = randn(dim,dim);
A = A + A.';
cost = @(x) (x'*A*x);
grad = @(x) 2*A*x;

% cost = @(x) (1-x(1))^2+100*(x(2)-x(1)^2)^2;
% grad = @(x) [-2*(1-x(1))+200*(x(2)-x(1)^2)*(-2*x(1));200*(x(2)-x(1)^2)];
% 
% euclidean(cost,grad,dim)


% Create the problem structure.
manifold = spherefactory(dim);
problem.M = manifold;

% Define the problem cost function and its Euclidean gradient.
problem.cost  = cost;
problem.egrad = grad;

% Solve.
%[x, xcost, info, options] = trustregions(problem);
 
%disp(norm(grad(x)-x*(grad(x)'*x)))

bfgsManifold(problem);