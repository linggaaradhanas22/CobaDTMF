%% Parameter Configuration

% Testing system Parameter
Fs = 16000; % Sampling Frequency
duration = 0.020; % Duration for each tone in seconds
N = Fs * duration; % Number of samples
t = (0:N-1) / Fs; % Create a time vector

% DTMF Frequencies
frequencies = [697, 770, 852, 941, 1209, 1336, 1477, 1633];

% Calculate k for each frequency using floor (Excel INT function behavior)
k_values = floor(0.5 + (N * frequencies) / Fs);

% Calculate coefficients
coeffs = 2 * cos(2 * pi * k_values / N);

%% DTMF Sample Creation
x = zeros(1, length(t));
x(1) = 1; % Impulse function for generating tones

% Generate tones using filter function
y_signals = cell(1, length(frequencies));
for i = 1:length(frequencies)
    freq = frequencies(i);
    y_signals{i} = filter([0 sin(2 * pi * freq / Fs)], [1 -2 * cos(2 * pi * freq / Fs) 1], x);
end


%% Apply Windowing Function to Each Signal
window = hamming(length(t))'; % Create a Hamming window
for i = 1:length(y_signals)
    y_signals{i} = y_signals{i} .* window;
end

%% Compute Scaling Factors for Normalization
scaling_factors = zeros(1, length(coeffs));
for i = 1:length(frequencies)
    % Generate a unit amplitude sine wave at the target frequency
    test_signal = sin(2 * pi * frequencies(i) * t) .* window;
    
    % Compute the power using the Goertzel filter
    scaling_factors(i) = GoertzelFilter(test_signal, coeffs(i));
end

%% Apply Goertzel Filter and Normalize Power Responses
signal_names = {'x(n):697', 'x(n):770', 'x(n):852', 'x(n):941', 'x(n):1209', 'x(n):1336', 'x(n):1477', 'x(n):1633'};

for s = 1:length(y_signals)
    y_signal = y_signals{s};
    powers = zeros(1, length(coeffs));
    for i = 1:length(coeffs)
        raw_power = GoertzelFilter(y_signal, coeffs(i));
        powers(i) = raw_power / scaling_factors(i); % Normalize power
    end
    figure;
    stem(frequencies, powers, 'filled');
    xlabel('Frequency (Hz)');
    ylabel('Normalized Power');
    title(['Normalized Power Response of ', signal_names{s}]);
    grid on;
    
    % Set x-axis ticks to display only the DTMF frequencies
    xticks(frequencies);
    xlim([min(frequencies) - 50, max(frequencies) + 50]);

    % Set y-axis limits to [0, 1.5]
    ylim([0, 1.5]);
    
    % Add annotations for each data point
    for i = 1:length(frequencies)
        text(frequencies(i), powers(i), sprintf('%.2f', powers(i)), ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
            'FontSize', 8, 'FontWeight', 'bold');
    end
end
