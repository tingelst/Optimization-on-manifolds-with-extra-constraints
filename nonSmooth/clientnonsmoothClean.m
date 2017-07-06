function clientnonsmoothClean

    d = 3;
    n = 8;
    % Create the problem structure.
    manifold = obliquefactory(d,n);
    problem.M = manifold;

    discrepency = 1e-4;
    
    cost = @(X) costFun(X);
    subgrad = @(X) subgradFun(manifold, X, discrepency);
    gradFunc = @(X) gradFun(X);
    subgradAlt = @(X, discre) subgradFun(manifold, X, discre);

    % Define the problem cost function and its Euclidean gradient.
    problem.cost  = cost;
    problem.grad = subgrad;
    problem.gradAlt = subgradAlt;
    problem.reallygrad = gradFunc;

%     checkgradient(problem);

    %Set options
    options.memory = 20;

    xCur = problem.M.rand();

    profile clear;
    profile on;

    [stats, X]  = bfgsnonsmoothClean(problem, xCur, options);

    figure
    h = logspace(-15, 1, 501);
    vals = zeros(1, 501);
    for iter = 1:501
        vals(1,iter) = problem.M.norm(X, subgradFun(problem.M, X, h(iter)));
    end
    loglog(h, vals)

%     discrepency = discrepency/10;
%     subgrad = @(X) subgradFun(manifold, X, discrepency);
%     problem.grad = subgrad;
%     [stats, X]  = bfgsnonsmoothClean(problem, X, options);
%     figure
%     h = logspace(-15, 1, 501);
%     vals = zeros(1, 501);
%     for iter = 1:501
%         vals(1,iter) = problem.M.norm(X, subgradFun(problem.M, X, h(iter)));
%     end
%     loglog(h, vals)
% 
%     discrepency = discrepency/10;
%     subgrad = @(X) subgradFun(manifold, X, discrepency);
%     problem.grad = subgrad;
%     [stats, X]  = bfgsnonsmoothClean(problem, X, options);
%     figure
%     h = logspace(-15, 1, 501);
%     vals = zeros(1, 501);
%     for iter = 1:501
%         vals(1,iter) = problem.M.norm(X, subgradFun(problem.M, X, h(iter)));
%     end
%     loglog(h, vals)
% 
%     discrepency = discrepency/10;
%     subgrad = @(X) subgradFun(manifold, X, discrepency);
%     problem.grad = subgrad;
%     [stats, X]  = bfgsnonsmoothClean(problem, X, options);
%     figure
%     h = logspace(-15, 1, 501);
%     vals = zeros(1, 501);
%     for iter = 1:501
%         vals(1,iter) = problem.M.norm(X, subgradFun(problem.M, X, h(iter)));
%     end
%     loglog(h, vals)


    profile off;
    profile report

    displaystats(stats)
    drawsphere(X, d);


    function val = costFun(X)
        Inner = X.'*X;
        Inner(1:size(Inner,1)+1:end) = -2;
        val = max(Inner(:));
    end

    function u = subgradFun(M, X, discrepency)
        if (~exist('discrepency', 'var'))
            discrepency = 1e-5;
        end
        counter = 0;
        pairs = [];
        Inner = X.'*X;
        m = size(Inner, 1);
        Inner(1: m+1: end) = -2;
        [maxval,pos] = max(Inner(:));
        pairs = zeros(m*m, 2);
        for row = 1: m
            for col = row+1:m
                if abs(Inner(row, col)-maxval) <= discrepency
                    counter = counter +1;
                    pairs(counter, :) = [row, col];
                end
            end
        end
        grads = cell(1, counter);
        for iterator = 1 : counter
            val = zeros(size(X));
            pair = pairs(iterator, :);
            Innerprod = X(:, pair(1, 1)).'*X(:, pair(1, 2));
            val(:, pair(1, 1)) = X(:, pair(1, 2)) - Innerprod*X(:,pair(1, 1));
            val(:, pair(1, 2)) = X(:, pair(1, 1)) - Innerprod*X(:,pair(1, 2));
            grads{iterator} = val;
        end
        [u_norm, coeffs, u] = smallestinconvexhull(M, X, grads);
    end

    function val = gradFun(X)
        Inner = X.'*X;
        m = size(Inner,1);
        Inner(1:m+1:end) = -2;
        [maxval,pos] = max(Inner(:));
        i = mod(pos-1,m)+1;
        j = floor((pos-1)/m)+1;
        val = zeros(size(X));
        val(:,i) = X(:,j);
        val(:,j) = X(:,i);
    end

    function drawsphere(X, dim)
        maxdot = costFun(X);
        
        if dim == 3
            figure;
            % Plot the sphere
            [sphere_x, sphere_y, sphere_z] = sphere(50);
            handle = surf(sphere_x, sphere_y, sphere_z);
            set(handle, 'FaceColor', [152,186,220]/255);
            set(handle, 'FaceAlpha', .5);
            set(handle, 'EdgeColor', [152,186,220]/255);
            set(handle, 'EdgeAlpha', .5);
            daspect([1 1 1]);
            box off;
            axis off;
            hold on;
            % Add the chosen points
            Y = 1.02*X;
            plot3(Y(1, :), Y(2, :), Y(3, :), 'r.', 'MarkerSize', 25);
            % And connect the points which are at minimal distance,
            % within some tolerance.
            min_distance = real(acos(maxdot));
            connected = real(acos(X.'*X)) <= 1.20*min_distance;
            [Ic, Jc] = find(triu(connected, 1));
            for k = 1 : length(Ic)
                vertex1 = Ic(k); vertex2 = Jc(k);
                plot3(Y(1, [vertex1 vertex2]), Y(2, [vertex1 vertex2]), Y(3, [vertex1 vertex2]), 'k-');
            end
            hold off;
        end
    end

    function displaystats(stats)
        figure;
        
        subplot(2,2,1)
        semilogy(stats.gradnorms, '.-');
        xlabel('Iter');
        ylabel('GradNorms');
        
        titletest = sprintf('Time: %f', stats.time);
        title(titletest);
        
        subplot(2,2,2)
        plot(stats.alphas, '.-');
        xlabel('Iter');
        ylabel('Alphas');
        
        subplot(2,2,3)
        semilogy(stats.stepsizes, '.-');
        xlabel('Iter');
        ylabel('stepsizes');
        
        subplot(2,2,4)
        semilogy(stats.costs, '.-');
        xlabel('Iter');
        ylabel('costs');
    end
end
