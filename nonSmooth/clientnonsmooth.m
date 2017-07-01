%smallestinconvexhull.m
%problem.egrad = grad
%grad suppose to have one variable.
%getGradient option 2 was changed.
%

function clientnonsmooth

    % Create the problem structure.
    manifold = obliquefactory(3,5);
    problem.M = manifold;
    
    cost = @(X) costFun(X);
    grad = @(M,X) newgradFun(M,X);

    % Define the problem cost function and its Euclidean gradient.
    problem.cost  = cost;
    problem.grad = grad;  
% % 
%      checkgradient(problem);
    
    %Set options
    options.linesearchVersion = 4;
    options.memory = 20;

    xCur = problem.M.rand();

    bfgsnonsmooth(problem, xCur, options);
    

%     bfgsIsometric(problem, xCur, options);
%    bfgsClean(problem, xCur, options);
%     %trustregions(problem, xCur, options);
%     options.maxiter = 20000;
%     steepestdescent(problem, xCur, options);
    
%     profile clear;
%     profile on;
% 
%     bfgsClean(problem,xCur,options);
% 
% 
%     profile off;
%     profile report

    % This can change, but should be indifferent for various
    % solvers.
    % Integrating costGrad and cost probably halves the time
        function val = costFun(X)
            Inner = X.'*X;
            Inner(1:size(Inner,1)+1:end) = -2;
%             Inner(eye(size(Inner,1))==1) = -2;
            val = max(Inner(:));
        end

    function u = newgradFun(M, X)
        discrepency = 1e-4;
        counter = 0;
        pairs = [];
        Inner = X.'*X;
        m = size(Inner, 1);
        Inner(1: m+1: end) = -2;
        %             Inner(eye(m)==1) = -2;
        [maxval,pos] = max(Inner(:));
        for row = 1: m
            for col = row+1:m
                if abs(Inner(row, col)-maxval) <= discrepency
                    counter = counter +1;
                    pairs{counter} = [row, col];
                end
            end
        end
        grads = cell(1, counter);
        for t = 1 : counter
            val = zeros(size(X));
            pair = pairs{t};
            Innerprod = X(:, pair(1)).'*X(:, pair(2));
            val(:, pair(1)) = X(:, pair(2)) - Innerprod*X(:,pair(1));
            val(:, pair(2)) = X(:, pair(1)) - Innerprod*X(:,pair(2));
            grads{t} = val;
        end
        [u_norm, coeffs, u] = smallestinconvexhull(M, X, grads);
        %             fprintf('counter = %d\n', counter);
    end
    
        function val = failedgradFun(X)
            discrepency = 1e-4;
            counter = 0;
            pairs = [];
            Inner = X.'*X;
            m = size(Inner, 1);
            Inner(1: m+1: end) = -2;
%             Inner(eye(m)==1) = -2;
            [maxval,pos] = max(Inner(:));
            for row = 1: m
                for col = row+1:m
                    if abs(Inner(row, col)-maxval) <= discrepency
                        counter = counter +1;
                        pairs{counter} = [row, col];
                    end
                end
            end
            val = zeros(size(X));
            for t = 1 : counter
                pair = pairs{t};
                val(:, pair(1)) = val(:, pair(1)) + X(:, pair(2));
                val(:, pair(2)) = val(:, pair(2)) + X(:, pair(1));
            end
            val = val/counter;
%             fprintf('counter = %d\n', counter);
        end
    
        function val = gradFun(X)
            Inner = X.'*X;
            m = size(Inner,1);
            Inner(1:m+1:end) = -2;
%             Inner(eye(m)==1) = -2;
            [maxval,pos] = max(Inner(:));
            i = mod(pos-1,m)+1;
            j = floor((pos-1)/m)+1;
            val = zeros(size(X));
            val(:,i) = X(:,j);
            val(:,j) = X(:,i);
        end
end
