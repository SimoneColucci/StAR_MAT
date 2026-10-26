%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Generic Nelder-Mead Simplex Solver w/ self stateing problem   %
%                                                                %
% Author: Bret Dahme                            12/Oct/2016      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
%
% General form implementation of a downhill Amoeba optimization algorithm
% accepting a function input which describes fit, freeing the user from
% having to build the matrixes.  This method is best at finding local minima,
% and boundary conditions or inital conditions can change the result
% converged to.  If the performance function is not continuous and smooth, or
% has multiple local minima, the simplex method may not produce desirable
% results.  see simpleGA for those conditions.
%
% Simple boundary conditions can be handled with the lowBoundary and
% highBoundary optional inputs, which can be set to -INF or +INF for
% individual variables to disable bounding them.
% 
% Complex bondary conditions can be handled in the performance function by
% returning INF whenever the input variables fall outside of range, though
% an initial conditions array should be used if this strategy is selected.
%
% The performance function is a function the user must create that accepts
% the variables to be optimized as a vector, and produce a scaler float
% output ranking the quality of solution, where a lower number represent a
% better solution.  For example, the returned scaler could be the error
% between a dataset and a polynomial curve generated from the input vector
% [A B C D .... n].
%
% Additional variables can be passed to the performance function using the
% additionalData optional input.  This can be a struct or array of any
% variable type that is passed into the performance function durring each
% iteration.  The values are not modified between iterations by the simplex
% solver, and is an effective way to pass in large data sets to the
% performacne function.
%
%   Inputs:
%     performance_function - function handle describing the goodness of fit 
%         for the current set of variables.  The error function will accept
%         two inputs, one of which is a columnwise vector of the variables
%         that will be changed each iteration by the Simplex function.
%         The second is an optional input of any datatype that is defined by
%         the name-value pair 'additnalData', and will be constant for each
%         call of the performane function. The performance function must have
%         one scaler output such that a smaller output correlates to a better
%         solution.
% 
%     n_variable - number of variables being optized, which will be bassed to
%         the performance_function
% 
%     All inputs below this line are optional name-value pairs
%     ********************************************************
% 
% 	'tolerance' - the tolerance before it is considered that convergence is
%         met, measured as the std of the performance_function output over
%         the last n_varible iterations. Default value of 1x10^-8
% 
% 	'iteration' - the maximum number of iterations before convergence is
%         abborted.  Default value of 10,000
% 
%  	'lowBoundary' - a vector n_variable long representing the lower boundry
%         for each variable, non inclusive. Default value of -INF (unbounded)
% 
% 	'highBoundary' - a vector n_variable long representing the upper
%         boundry for each variable, non inclusive. Default value of -INF
%         (unbounded)
% 
%   'initial' - initial conditions to begin solving, must be in the form of
%         a 2d matrix sized [n_variable + 1, n_variable] representing
%         n_variable + 1 guesses at the actual answer.  Values chosen should
%         fall within the boundarys for each variable.  Any values that
%         produce a nan from the performance function will be ignored.  For
%         advanced use, it is possible to provide initial condionts for
%         only some variables and set the remaining values to nan to have
%         them auto filled. Default value is a matrix filled with random
%         numbers falling within lowBoundary and highBoundary.
% 
%   'plot' - true / false flag to determine if the convergence should be
%         plotted.  Defualt false
% 
% 	'seed' - seed for tha random number generator, passed to the function
%         rng.  Seeding the random number generator ensures results are
%         repeatable.  Reseading the random number generator inside of the
%         performance function will not cause errors to this process. Default
%         of 17, cuas i like that number
% 
% 	'additionalData' - optional input of any datatype that will be passed
%         to the performance function every call as the second input to the
%         performance function.  Will be constant for each call of the
%         performane function. Defautl is to not exist, and the performance
%         function will be called with only 1 input.  Defualt is []
%      
%
%   Outputs:
% 	argument - a row wise vector containing the arguments which converged
%         to a local minima
% 
% 	minima - the value of the local minima, output by the 
%         performance_function with the given arguments
% 
% 	iterationCount - the number of iterations when execution was ended.
%
%
% Example functions use:
% *************************************************************************
%
%   #1
%
% argument = Simplex( @MyPerformanceFunction, 4 )
%
%
%   #2
%
% [argument, minima] = Simplex( @MyFun, 4, 'lowBoundary', [0,0,0,0] );
%
%
%   #3
% 
% argument = Simplex( @CurveFitMyData, 4, 'lowBoundary', [0,0,0,0], 'additionalData',MyData);
%
% Example performance_function
% *************************************************************************
%
%   #1
%
% A function like this can be stored anywhere a typical matlab function is
% stored.  it can then be called using example function call example #1
%
%   function y = MyPerformanceFunction(x)
%
%       %Powell's Quadratic Function
%       y = (x(1)+10*x(2))^2 + 5*(x(3)-x(4))^2 + (x(2)-2*x(3))^4 + 10*(x(1)-x(4))^4;
%
%   end
%
%
%   #2
%
% Alternatively, you can declare the function in 1 line, and store it to a
% handle without the need to save the function to a file anywhere.  This is
% called an anonimuous function.  Note that there is some overhead involved
% with ananimous functions reducing performance adn would be used as seen
% in function call example #2
%
%   MyFun = @(x) (x(1)+10*x(2))^2 + 5*(x(3)-x(4))^2 + (x(2)-2*x(3))^4 + 10*(x(1)-x(4))^4;
%
%
%   #3
%
% Often this search method is being used to fit against a data set.  To
% avoid constantly loading and unloading the dataset, you can simply declare
% a nested function for performance_function.  A simplified example of this
% is seen below
% 
% 
%     function curveFitConstants = CurvefitSomeDataset( fileName )
% 
%     m = matfile( fileName );
%     data = m.data;
%     time = m.time
% 
%     curveFitConstants = Simplex( @MYFUN, 3 );
% 
% 
%     % the performance function is being declared as a nested function WITHIN
%     % function CurvefitSomeDataset.  This allows it to share the memory
%     % holding the variable data
% 
%         function fit_performance = MYFUN (fitParameter)
% 
%             % polyfit
%             a = fitParameter(1);
%             b = fitParameter(2);
%             c = fitParameter(3);
% 
%             fitted = time.^2*a + time*b + c;
% 
%             % A SMALLER NUMBER FOR FIT PEFORMANCE REPRESENTS A BETTER FIT
% 
%             fit_performance =  sum(( fitted - data )^2);
% 
%         end
% 
%     end
%
%
%   #4
% If you want to avoid using nested functions you can also pass the data
% you wnat to curve fit to into the performance function by using the
% 'additionalData' flag.  These two function could be stored in the same
% file or in seperate files so long as CurvefitSomeData has access to MYFUN
% So long as the additionalData is not being modified within the peformance
% function it will have similar performance to the nested function.
%
%
%     function curveFitConstants = CurvefitSomeDataset( fileName )
% 
%     m = matfile( fileName );
%     curveData.data = m.data;
%     curveData.time = m.time;
% 
%     curveFitConstants = Simplex( @MYFUN, 3, 'additionalData',curveData, 'lowBoundary', [0,0,0], 'highBoundary', [5,5,5] ); 
% 
%     end
% 
% 
%     function fit_performance = MYFUN (fitParameter,curveData)
% 
%     % the performance function is not nested
% 
%     % polyfit
%     a = fitParameter(1);
%     b = fitParameter(2);
%     c = fitParameter(3);
% 
%     fitted = curveData.time.^2*a + curveData.time*b + c;
% 
%     % A SMALLER NUMBER FOR FIT PEFORMANCE REPRESENTS A BETTER FIT
% 
%     fit_performance =  sum(abs( fitted - curveData.data ));
% 
%     end
%
% *************************************************************************

% This has been based on code samples supplied by Michael Jacob Mathew;
%   An Implementation of Nalder Mead Simplex
% 
% Reference: 
%   Lagarias, Jeffrey C., et al. "Convergence properties of the
%       Nelder--Mead simplex method in low dimensions." SIAM Journal on
%       Optimization 9.1 (1998): 112-147.

%-------------------------------------------------------------------------
%Bret Dahme - v1.0 2016-10-12
%Fisher Controls
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%Bret Dahme - v1.1 2017-10-07
%Fisher Controls
% Added a seed for the random number generator, and improved the inital
% condition generator by forcing it loop untill all answeres are valid, and
% will through and error if all initial conditions are invalid indicating
% bad boundry conditions.
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%Bret Dahme - v1.2 2019-08-07
%Fisher Controls
% Added the optional name-value input 'additionalData'
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%Bret Dahme - v1.2.1 2020-06-10
%Fisher Controls
% Cleaned up commenting for distribution, renamed function
%-------------------------------------------------------------------------
%}


function [argument, minima, iterationCount] = simplex(performance_function, n_variable, varargin)
%% Get mandatory and optional Inputs using inputParser;

[setting] = InputParser( performance_function, n_variable, varargin );

%% Initial Conditions & Constants

n = n_variable+1; % number of vertex
p = 1; %reflection coefficient
chi = 2; %expansion coefficient
gamma = 0.5; %contraction coefficient
sig = 0.5; %shrink coefficient

% generate initial conditions for the solver
vertex = InitiateSimplex(n,setting);

% optionally generate a plot of how the process converged
if setting.plot
    convergenceTrace = nan(setting.iteration,1);
end

%%  chug-a-lug
% starting point to get into the while loop
ii = 1;
convergence = setting.tolerance * 10;
while(convergence >= setting.tolerance && ii <= setting.iteration)
    %% Sort based on performance
    ii = ii+1;
    vertex = Sort(vertex);
    centroid = Centroid(vertex,n,setting);
    
    if setting.plot
        convergenceTrace(ii)=vertex(1).value;
    end
    
    %% Reflect
    % Reflect the worst vertex through the centroid of the remaining vertex
    % If the reflected vertex value is between the best and next-to-worst
    % vertex, replace the worst vertex with the reflected vertex
    
    Reflect.coord = (1+p).*centroid.coord - p.*vertex(n).coord;
    Reflect.value = PerformanceFunctionCaller(Reflect,setting);
    
    if(vertex(1).value <= Reflect.value && Reflect.value < vertex(n-1).value)
        vertex(n)=Reflect;
        
    elseif(Reflect.value < vertex(1).value)
        %% Expand
        % If the reflected vertex is better than then extend the reflected
        % vertex further past the centroid. Replace the worst solution with the
        % the better or the reflected or expanded.
        
        Expand.coord = (1-chi).*centroid.coord+chi.*Reflect.coord;
        Expand.value = PerformanceFunctionCaller(Expand,setting);
        
        if(Expand.value < Reflect.value)
            vertex(n) = Expand;
        else
            vertex(n) = Reflect;
        end
        
    elseif(vertex(n-1).value <= Reflect.value)
        %% Contract
        % The reflected vertex is worse than the next-to-worst vertex.
        % Contract the worst solution to a location between itself and the
        % reflection.
        
        ContractOut.coord = (1-gamma).*centroid.coord + gamma.*Reflect.coord; %Contract Outside
        ContractOut.value = PerformanceFunctionCaller(ContractOut,setting);
        
        ContractIn.coord = (1-gamma).*centroid.coord + gamma.*vertex(n).coord;  %Contract Inside
        ContractIn.value= PerformanceFunctionCaller(ContractIn,setting);
        
        if(vertex(n-1).value <= Reflect.value && Reflect.value < vertex(n).value && ContractOut.value <= Reflect.value)
            vertex(n) = ContractOut;
            
        elseif(vertex(n).value <= Reflect.value && ContractIn.value < vertex(n).value) %Contract Inside
            vertex(n) = ContractIn;
        end
        
    else
        %% Shrink
        % Shrink the simplex towards the best vertex.  This improves
        % convergence if the solution is non-smooth
        
        for jj=2:n
            vertex(jj).coord = (1-sig).*vertex(1).coord + sig.*vertex(jj).coord;
            vertex(jj).value = PerformanceFunctionCaller(vertex(jj),setting);
        end
    end
    
    convergence = Convergence(vertex);
end

% collect outputs after sorting to ensure index 1 is the desired solution
vertex = Sort(vertex);
argument = vertex(1).coord;
minima = vertex(1).value;
iterationCount = ii;

%% make pretties
if setting.plot
    figure();
    % shift up to make log plot work avoiding zeroes
    semilogy(convergenceTrace - min(convergenceTrace) + setting.tolerance );
    xlabel('iterations');
    ylabel( ['performance index - min performance ', num2str(min(convergenceTrace))] );
    title(['Performance Vs ', num2str(ii), ' Iterations']);
    grid on;
end

end


function [setting] = InputParser( performance_function, n_variable, nameValuePair )
%% Wrapper function for handeling user inputs and some error checking

% fill the parcer with the list of variables and their requirements
p = FillInputParser(n_variable);


% where the parcing actualy happens
p.parse( performance_function, n_variable, nameValuePair{:} );

% error checking and formatting that doesn't fit within the parcer
setting = ProcessInputParser( p );

end


function p = FillInputParser(n_variable)
%% Fill the inputParser with all information to get the required,
% optional, and optional name-value pairs.  Also determines default vaulues
% for anything not set, and determines basic error checking of any inputs.

p = inputParser;

%% Mandatory inputs
argName = 'performance_function';
validation = @(x) validateattributes( x, {'function_handle'}, {'scalar'} );
p.addRequired( argName, validation );

argName = 'n_variable';
validation = @(x) validateattributes( x, {'numeric'}, {'scalar','positive',} );
p.addRequired( argName, validation );

%% Optional inputs

% no optional inputs

%% name-value pairs
argName = 'tolerance';
default = 1*10^-8; % default tolerance for convergence
validation = @(x) validateattributes( x, {'numeric'}, {'scalar','positive'} );
p.addParameter( argName, default, validation );

argName = 'iteration';
default = 10000; % default maximum number of iterations
validation = @(x) validateattributes( x, {'numeric'}, {'scalar','positive'} );
p.addParameter( argName, default, validation );

argName = 'lowBoundary';
default = ones(n_variable,1) * -inf; % unbounded
validation = @(x) validateattributes( x, {'numeric'}, {'vector','numel',n_variable} );
p.addParameter( argName, default, validation );

argName = 'highBoundary';
default = ones(n_variable,1) * inf; % unbounded
validation = @(x) validateattributes( x, {'numeric'}, {'vector','numel',n_variable} );
p.addParameter( argName, default, validation );

argName = 'plot';
default = false; % do not plot
validation = @(x) validateattributes( x, {'logical','numeric'}, {'scalar'} );
p.addParameter( argName, default, validation );

argName = 'initial';
default = nan(n_variable+1,n_variable); % random input conditions will be filled in later
validation = @(x) validateattributes( x, {'numeric'}, {'size',[n_variable+1,n_variable]} );
p.addParameter( argName, default, validation );

argName = 'seed';
default = 17; % default seed for the random number generator
validation = @(x) validateattributes( x, {'numeric'}, {'scalar','positive'} );
p.addParameter( argName, default, validation );

argName = 'additionalData';
default = []; % default is empty array if no additional data is passed in
% no validation
p.addParameter( argName, default );

end


function setting = ProcessInputParser( p )
%% Fill setting struct with inputs taking the priority of: name-value pairs,
% setting struct which was passed in, and then the default

setting = p.Results;

% any additional formatting requirements

% iteration limit must be an int
setting.iteration = ceil(setting.iteration);

end


function performance = PerformanceFunctionCaller(vertex,setting) %Write your function in matrix form
%% Call the performance_function after applying boundry conditions
% The performance function must be arranged such that a lower number
% represents a better fit.  Positive, negative, zero, and non-finite
% numbers are acceptable.

% If the performance function is not continuous or not smooth, the simplex
% method may nto produce desirable results.

% apply limits
if sum(vertex.coord >= setting.highBoundary(:)') || sum(vertex.coord <= setting.lowBoundary(:)')
    performance = inf;
    return;
end

% call the function using 1 or two inputs depending on if additionalData is
% emtpy
if isempty(setting.additionalData)
    % call performance function with 1 input
    performance = setting.performance_function( vertex.coord);
else
    % call performance function with 2 input
    performance = setting.performance_function( vertex.coord, setting.additionalData);
end

% make sure the function output is correctly formatted
if (length(performance)~=1) || ~isnumeric(performance)
     error('simpleSimples:performance_function','The performance function must always output a single numeric value: ''%s''\n',char(setting.performance_function));
end

end


function vertex = InitiateSimplex(n,setting)
%% Create initial conditions which fall between the boundary conditions
% becuase of the potential for complex boundary conditions, it's possible
% to get randomly generated boundary conditions which are all inf.  if this
% happens an error is thrown advising to supply a valid sead.  If some
% values are inf, random initial conditions are filled in untill no initial
% conditions are inf.  will attemp up to the maximum iteration count to
% find all non-inf solutions.  If still unsuccessfull, it will throw a
% warning and continue.

% kick off the random number generator
rng(setting.seed);

% loop till all initial values are non-inf
value = inf(n,1);
vertex(1:n) = struct();
jj = 0;
while sum( value~=inf ) ~= n && jj < setting.iteration
    jj = jj + 1;
    
    for ii = 1:n
        % start with a random array
        vertex(ii).coord = [rand(n-1,1) .* (setting.highBoundary(:) - setting.lowBoundary(:)) + setting.lowBoundary(:)]';
        
        % push over any initial conditions given
        for jj = 1:(n-1)
            if ~isnan(setting.initial(ii,jj))
                vertex(ii).coord(jj) = setting.initial( ii, jj);
            end
        end
        
        % fill in the values for all inital guesses
        vertex(ii).value = PerformanceFunctionCaller(vertex(ii),setting);
        value(ii) = vertex(ii).value;
        
        % if value is good, push coord over to the initial settings
        for jj = 1:(n-1)
            if vertex(ii).value ~= inf
                setting.initial(ii, jj) = vertex(ii).coord(jj);
            else
                % the seed falls outside of boundary conditions
                setting.initial(ii, jj) = nan;
            end
        end
    end
    
    % if all initial conditions are inf, you could have bad boundry
    % conditions.  supply a seed to ensure this is not the case
    if sum( value~=inf ) == 0
        error('simpleSimples:InitialSimplex','The initial conditions provided no valid results.  Consider provideing initial conditions');
    end
    
    if jj == setting.iteration
        warning('simpleSimples:InitialSimplex','The initial conditions provided solutions with invalid results, and attempts to remove all invalid results were unsuccessfull.  Consider provideing initial conditions to improve performance.  Solver will continue.');
    end
    
end

end


function vertex = Sort(vertex)
%% sort vertices into ascending order based on .value
    [~,index] = sort([vertex.value]);
    vertex = vertex(index);
    
end


function centroid = Centroid(vertices,n,setting)
%% Compute the vector average of all points except the hightest error; i.e.,
% the center of the "face" of the simplex across from the high point.
% We will subsequently explore along the ray from the high point through
% that center.
    
    Sum=zeros(1,(n-1));
    for i=1:n-1 % array is already sorted, last element has highest error
        Sum=Sum+vertices(i).coord;
    end
    centroid.coord=Sum./(n-1);
    centroid.value=PerformanceFunctionCaller(centroid,setting);
    
end


function[convergence] = Convergence(vertices)
% convergence is based on the standard deviation of the last n points which
% had finite values.  If any vertices have non-finite values then
% convergence will not be reached.
    
    convergence=std([vertices.value],1);
    
    % handle INF vallues in the vallue array
    if isnan(convergence)
        convergence = inf;
    end
    
end
