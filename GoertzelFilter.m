function [power] = GoertzelFilter(x, coeff)
    % GoertzelFilter - Applies the Goertzel algorithm to a signal x
    % Inputs:
    %   x     : Input signal (ADC samples)
    %   coeff : Goertzel filter coefficient
    % Output:
    %   power : Calculated power (magnitude squared) of the Goertzel output

    N = length(x); % Get the number of samples
    
    % Initialize the state variables Q0, Q1, and Q2
    Q0 = 0;
    Q1 = 0;
    Q2 = 0;

    % Loop through the input signal x
    for n = 1:N
        % Compute Q0 based on the Goertzel algorithm equation
        Q0 (:) = (coeff * Q1) - Q2 + x(n);

        % Update the state variables
        Q2 (:) = Q1;
        Q1 (:) = Q0;
    end

    % Compute the final power (magnitude squared) based on Q1 and Q2 at the last sample
    power = Q1^2 + Q2^2 - (coeff * Q1 * Q2); % Normalize by N^2
end

