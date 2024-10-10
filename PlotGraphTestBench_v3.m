%% Parameter Configuration

% Testing system parameters
Fs = 16000;             % Sampling Frequency
duration = 0.020;       % Duration for each tone in seconds
N = Fs * duration;      % Number of samples
t = (0:N-1) / Fs;       % Time vector

% DTMF Frequencies
low_frequencies = [697, 770, 852, 941];
high_frequencies = [1209, 1336, 1477, 1633];
frequencies = [low_frequencies, high_frequencies];

% Calculate k for each frequency using floor (Excel INT function behavior)
k_values = floor(0.5 + (N * frequencies) / Fs);

% Calculate coefficients
coeffs = 2 * cos(2 * pi * k_values / N);

%% DTMF Digits and Their Corresponding Frequencies
dtmf_keys = {
    '1', 697, 1209;
    '2', 697, 1336;
    '3', 697, 1477;
    'A', 697, 1633;
    '4', 770, 1209;
    '5', 770, 1336;
    '6', 770, 1477;
    'B', 770, 1633;
    '7', 852, 1209;
    '8', 852, 1336;
    '9', 852, 1477;
    'C', 852, 1633;
    '*', 941, 1209;
    '0', 941, 1336;
    '#', 941, 1477;
    'D', 941, 1633;
};

%% Generate DTMF Signals
num_digits = size(dtmf_keys, 1);
dtmf_signals = cell(num_digits, 1);
for i = 1:num_digits
    row_freq = dtmf_keys{i, 2};
    col_freq = dtmf_keys{i, 3};
    % Generate DTMF tone by summing the row and column frequencies
    dtmf_signal = sin(2 * pi * row_freq * t) + sin(2 * pi * col_freq * t);
    dtmf_signals{i} = dtmf_signal;
end

%% Apply Windowing Function to Each Signal
window = hamming(length(t))'; % Create a Hamming window
for i = 1:num_digits
    dtmf_signals{i} = dtmf_signals{i} .* window;
end

%% Compute Scaling Factors for Normalization
% Since each signal now has two frequencies, we need to adjust scaling factors.
% We'll compute scaling factors for each frequency as before.

scaling_factors = zeros(length(frequencies), 1);
for i = 1:length(frequencies)
    % Generate a unit amplitude sine wave at the target frequency
    test_signal = sin(2 * pi * frequencies(i) * t).* window;

    % Compute the power using the Goertzel filter
    scaling_factors(i) = GoertzelFilter(test_signal, coeffs(i));
end

%% Apply Goertzel Filter and Normalize Power Responses
for i = 1:num_digits
    dtmf_signal = dtmf_signals{i};
    powers = zeros(length(frequencies), 1);
    for j = 1:length(coeffs)
        raw_power = GoertzelFilter(dtmf_signal, coeffs(j));
        powers(j) = raw_power / scaling_factors(j); % Normalize power
        % Alternative
        % powers(j) = GoertzelFilter(dtmf_signal, coeffs(j));
    end
    figure;
    stem(frequencies, powers, 'filled');
    xlabel('Frequency (Hz)');
    ylabel('Normalized Power');
    title(['Normalized Power Response for DTMF Digit ', dtmf_keys{i,1}]);
    grid on;
    
    % Set x-axis ticks to display only the DTMF frequencies
    xticks(frequencies);
    xlim([min(frequencies) - 50, max(frequencies) + 50]);

    % Set y-axis limits to [0, 1.5]
    ylim([0, 1.5]);
    
    % Add annotations for each data point
    for k = 1:length(frequencies)
        text(frequencies(k), powers(k), sprintf('%.2f', powers(k)), ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
            'FontSize', 8, 'FontWeight', 'bold');
    end
end
