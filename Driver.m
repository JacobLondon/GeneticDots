% This file is the runnable file.
clc; clear; close all;

% start and goal coordinates
start = [10, 10];
goal = [150, 100];
num_gens = 400;

control = @(generations) ...
    Move(start(1), start(2), goal(1), goal(2), generations);

% enter number of generations to run
error = control(num_gens);
fprintf('%0.2f%% error\n', error);

