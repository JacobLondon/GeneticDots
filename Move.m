function result = Move(startx, starty, goalx, goaly, generations)
    % Simulates dots on a plane learning to approach a goal.
    
    rng('shuffle');
    figure;
    
% Settings ----------------------------------------------------------------    
    
    pop_size = 100;              % size of the population | Sizes 100-500
    num_keep = 10;               % number of population to keep every gen | Sizes 5-10
    max_step = 4;                % the largest movement possible per step | Sizes 3-10
    mutation_rate = 0.01;        % the percentage of directions that changes | Sizes: 0.01-0.0001
    
    % the size of the xy plane
    plane_size = 160;
    
% -------------------------------------------------------------------------

    % modifier to control how many steps the agents are allowed to take
    dist_modifier = 0.3;
    distance = int32(sqrt((goalx-startx)^2 + (goaly-starty)^2) * dist_modifier);
    route_counter = 1;
    num_directions = distance;   % num of moves per generation
    goalr = 1;                   % radius of the goal

    % this many times fewer points on the 3D plot
    dec_plot = 10;
    space_str = '                                            ';
    
    % help print the progress bar
    progress = 0;
    entered = 0;
    loading = '';
    
    % find error
    perfect = trapz([startx, goalx] , [starty, goaly]);
    
    % show user how much time to expect running
    timestamp_gens = generations / 200;
    if timestamp_gens <= 1
        timestamp_gens = 3;
    end
    
    % blueprint for agent with defaults
     agent.pos = [startx, starty];
     agent.fitness = 0;
     agent.is_dead = 0;
     agent.reached_goal = 0;
     agent.directions = [];
     agent.steps = 0;
     
     % build the default set of directions
     for a = 1:num_directions
         agent.directions = [agent.directions, [0; 0]];
     end
    
     % preallocate plotting memory
     current_index = 1;
     x = zeros(1, pop_size^2);
     y = zeros(1, pop_size^2);
     z = zeros(1, pop_size^2);
     best_x = [];
     best_y = [];
     best_route_start = [];
     best_route_end = [];
     
    % default population
    population(1:pop_size) = agent;
         
    % build the random population
    for current = 1:pop_size
        % create a random vector of xy step pairs
        for step = 1:num_directions
            xdir = rand;
            ydir = rand;
            population(current).directions(:, step) ...
                = [rand * max_step; rand * max_step];
            
            % negative option
            if xdir < 0.5
                population(current).directions(1, step) ...
                    = population(current).directions(1, step) .* -1;
            elseif ydir < 0.5
                population(current).directions(2, step) ...
                    = population(current).directions(2, step) .* -1;
            end
        end
    end
    
    % genetic algorithm
    for generation = 1:generations
        
        % run all steps for each agent
        simulate
        
        % add x and y indices
        for index = 1:pop_size
            x(current_index) = population(index).pos(1);
            y(current_index) = population(index).pos(2);
            z(current_index) = generation;
            current_index = current_index + 1;
        end
        
        % determine best
        fitness
        % select best and build a new generation of agents
        selection
        route_counter = route_counter + 1;
        
        % user display
        % start tic
        if generation == 1
           tic;
           
        % expected run time
        elseif generation == timestamp_gens
            time = toc;
            progress = 1;
            
            % show period or frequency
            if time/timestamp_gens > 1
                str = 's/iter';
                perfreq = time/timestamp_gens;
            else
                str = 'iter/s';
                perfreq = (time/timestamp_gens)^-1;
            end
            
            fprintf('%0.4f %s for %0.0f iterations. Estimated runtime: %0.2fs\n\n', ...
                    perfreq, str, generations, 1.5 * time * generations / timestamp_gens);
            fprintf('|0|%s|50|%s|100|\n', space_str, space_str)
        end
        
        % progress in percent
        if mod(generation, generations / 100) == 0
            if progress == 0
                loading = strcat(loading, '>');
                continue
            elseif entered == 0 && progress == 1
                fprintf('%s', loading);
                entered = 1;
            end
            
            if entered == 1
                fprintf('>');
            end
        end
    end
    
    % finish telling user about run time
    time = toc;
    fprintf('\n\nActual runtime: %0.4fs\n', time);
    
    % plot the agents and starting/ending positions
    plot3(x(1:dec_plot:pop_size*length(best_x)), ...
          y(1:dec_plot:pop_size*length(best_x)), ...
          z(1:dec_plot:pop_size*length(best_x)), 'co');
    hold on
    
    % plot starting point
    plot3(startx, starty, 0, 'g*');
    box on
    grid on
    view(-10, 20);
    
    % find goal(s) that the agents will end up in, 2 solutions
    syms x y
    solutions = sqrt((x-goalx)^2 - (y-goaly)^2) == 0;
    y_solns = solve(solutions, x);
    x_solns = solve(solutions, y);
    y_solns = double(subs(y_solns, y, goaly));
    x_solns = double(subs(x_solns, x, goalx));
    goal = [x_solns, y_solns];
    plot3(goal(:, 2), goal(:, 1), [0, 0], 'b*');
    
    % plot best movement
    best_x = [startx, best_x];
    best_y = [starty, best_y];
    plot3(best_x, best_y, 1:length(best_x), 'rs');
    plot3(best_x, best_y, 1:length(best_x), 'r'); 
    
    % percent error
    attempt = trapz(best_x, best_y);
    result = 100 * abs(perfect - attempt)/double(perfect);
    
    hold off
    xlabel('x axis');
    ylabel('y axis');
    zlabel('Generations');
    legend('Agent', 'Start', 'Goal', 'Best');
    title('Final Agent Position per Generation');
    
    % show end position per generation of best one
    figure;
    subplot(1, 2, 1);
    plot(best_x, best_y, 'rs');
    hold on
    plot(startx, starty, 'g*');
    plot(goal(:, 2), goal(:, 1), 'b*');
    
    % best fit graph
    warning('off', 'all');
    p = polyfit(best_x, best_y, 4);
    x1 = linspace(startx, goalx, 1000);
    y1 = polyval(p, x1);
    plot(x1, y1, 'b');
    plot(best_x, best_y, 'r');
    hold off
    xlabel('x axis');
    ylabel('y axis');
    title('Better Agent End Positions');
    legend('Best', 'Start', 'Goal', 'Best Fit');
    
    % show routing of best at start and finish
    route_s = [startx; starty];
    route_e = [startx; starty];
    selection
    best_route_end = population(1).directions;
    for pos = 1:length(best_route_start)
        route_s = [route_s, route_s(:, pos) + best_route_start(:, pos)];
        route_e = [route_e, route_e(:, pos) + best_route_end(:, pos)];
    end
    
    subplot(1, 2, 2);
    plot(route_s(1, :), route_s(2, :), 'bs');
    hold on
    plot(route_e(1, :), route_e(2, :), 'ro');
    plot(startx, starty, 'g*');
    plot(goal(:, 2), goal(:, 1), 'b*');
    plot(route_s(1, :), route_s(2, :), 'b');
    plot(route_e(1, :), route_e(2, :), 'r');
    hold off
    xlabel('x axis');
    ylabel('y axis');
    title('Agent Path');
    legend('Best of Gen 1', 'Best of Last Gen', 'Start', 'Goal');
    
% functions --------------------------------------------------------------
    
    % make a new vector of mutated best agents
    function selection
        new_pop(1:num_keep) = agent;
        
        % find the best
        best = population(1);
        for keep = 1:num_keep
            spot = 1;
            for current = 1:pop_size
                
                % get best and record index
                if population(current).fitness > best.fitness
                    best = population(current);
                    spot = current;
                    
                    % record the best's end generation movement
                    if keep == 1
                        best_x = [best_x, best.pos(1)];
                        best_y = [best_y, best.pos(2)];
                        
                        % get routing of best agent at start/finish
                        if route_counter == 1
                            best_route_start = best.directions;
                        end
                    end
                end
            end
            
            
            % replace with a blank agent and keep best
            new_pop(keep) = best;
            population(spot) = agent;
        end
        
        % keep the best in each generation
        for keep = 1:num_keep
            population(keep) = new_pop(keep);
        end
        
        % fill the population with children from the best
        for current = num_keep+1:pop_size
            
            % parents randomly picked from best
            parent1 = new_pop(randi([1, length(new_pop)], 1, 1));
            parent2 = new_pop(randi([1, length(new_pop)], 1, 1));
            
            % make a new child based on best and crossover
            child = agent;
            spot = randi([1, num_directions], 1, 1);
            child.directions = [parent1.directions(:, 1:spot), ...
                parent2.directions(:, spot:num_directions)];
            
            population(current) = child;
            
            % reset traits but keep directions
            population(current).pos = [startx, starty];
            population(current).fitness = 0;
            population(current).is_dead = 0;
            population(current).reached_goal = 0;
            population(current).steps = 0;
        end
        
        % mutate all but the best (keep the best so improvement occurs)
        for current = num_keep+1:pop_size
           population(current) = mutate(population(current));
        end
        
    end

    % assign fitnesses
    function fitness
        
        % traverse all agents
        for current = 1:pop_size
            
            % if reached goal
            if population(current).reached_goal == 1
                
                % assign fitness based on the fewest steps taken
                population(current).fitness ...
                    = 10000 / (population(current).steps ^ 2);
                
            % didn't reach goal, but just distance from goal
            else
                distance_to_goal = sqrt((population(current).pos(1) - goalx) ^ 2 ...
                    + (population(current).pos(2) - goaly) ^ 2);
                
                % assign fitness based on least distance to goal
                population(current).fitness = 500 / distance_to_goal ^ 2;
            end
        end
    end

    % simulate the generation
    function simulate
        done = allDead;
        current_dir = 1;
        
        % while simulation isn't over
        while done == 0
            
            % force exit when there are no more steps left
            if current_dir > num_directions
               break 
            end
            
            % step everyone one at a time
            for current = 1:pop_size
                
                % if the current one isn't dead
                if population(current).is_dead == 0
                    
                    % step once
                    population(current).steps = population(current).steps + 1;
                  
                    % step by new direction
                    population(current).pos = population(current).pos ...
                        + population(current).directions(:, current_dir)';
                    
                    % check if out of bounds, if so it dies
                    if population(current).pos(1) < 0 ...
                         || population(current).pos(1) > plane_size ...
                         || population(current).pos(2) < 0 ...
                         || population(current).pos(2) > plane_size
                     
                        population(current).is_dead = 1;
                        
                    % reached goal, it dies
                    elseif sqrt((population(current).pos(1) - goalx)^2 ...
                            + (population(current).pos(2) - goaly)^2) < goalr
                        population(current).is_dead = 1;        % it dies
                        population(current).reached_goal = 1;   % reached the goal
                    end
                    
                    % the last move is done, so the agent dies
                    if current_dir == num_directions
                        population(current).is_dead = 1;
                    end
                end
            end
            
            % check for end of simulation
            done = allDead;
            current_dir = current_dir + 1;
        end
    end

    % determine if any in the population is alive still
    function done = allDead
       for current = 1:pop_size
           
           if population(current).is_dead == 0
               done = 0;
               break
           else
               done = 1;
           end
       end
    end

    % make random changes to directions
    function mutated_one = mutate(mutated_one)
        for step = 1:num_directions
            
            % new angles set randomly to new agents
            if rand < mutation_rate
                xdir = rand;
                ydir = rand;
                mutated_one.directions(:, step) ...
                    = [rand * max_step; rand * max_step];
                
                % negative option
                if xdir < 0.5
                    population(current).directions(1, step) ...
                        = population(current).directions(1, step) .* -1;
                elseif ydir < 0.5
                    population(current).directions(2, step) ...
                        = population(current).directions(2, step) .* -1;
                end
            end
        end
    end
end
