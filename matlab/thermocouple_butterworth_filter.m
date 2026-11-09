%% BLOQUE 1 - PUNTOS 3 Y 4: Acondicionamiento y Filtrado del Termopar
% Versión SIN Signal Processing Toolbox (coeficientes calculados a mano)
clear; clc; close all;

%% 1. Parámetros de la simulación
fs = 2000;                  % Frecuencia de muestreo (Hz)
Ts = 1/fs;                  % Periodo de muestreo (s)
t  = 0:Ts:2;                % Vector de tiempo (2 segundos)

%% 2. Generación de las señales
% Tensión del termopar (aprox 850 °C -> 35.3 mV DC)
V_termopar = 0.0353 * ones(size(t));

% Ruido de modo común inducido por las resistencias del horno
V_ruido_60Hz = 2 * sin(2*pi*60*t);        % 2 V pico a 60 Hz

% Ruido blanco (interferencia aleatoria)
V_ruido_blanco = 0.1 * randn(size(t));

% Señal total cruda (lo que mediría el sistema antes de filtrar)
V_total = V_termopar + V_ruido_60Hz + V_ruido_blanco;

%% 3. Diseño MANUAL del filtro Butterworth de 2do orden
% Prototipo analógico:  H(s) = 1 / (s^2 + sqrt(2)*s + 1)
% Se discretiza con la transformada bilinear:  s = (2/T)*(z-1)/(z+1)
% con pre-distorsión de frecuencia:  K = tan(pi*fc/fs)

fc = 5;                              % Frecuencia de corte (Hz)
K  = tan(pi*fc/fs);                  % Pre-distorsión
norm_factor = 1 + sqrt(2)*K + K^2;   % Factor de normalización

% Coeficientes del numerador b y denominador a de H(z)
b = [K^2,  2*K^2,  K^2] / norm_factor;
a = [1,  2*(K^2 - 1)/norm_factor,  (1 - sqrt(2)*K + K^2)/norm_factor];

% Verificación: ganancia en DC debe ser 1 (0 dB)
fprintf('Ganancia en DC del filtro: %.4f (debe ser ~1)\n', sum(b)/sum(a));
fprintf('Coeficientes b: [%.6e, %.6e, %.6e]\n', b);
fprintf('Coeficientes a: [%.6f, %.6f, %.6f]\n', a);

%% 4. Aplicar el filtro (filter es función BASE de MATLAB, sí funciona)
V_filtrada = filter(b, a, V_total);

%% 5. Gráfica 1: señal antes y después del filtrado
figure('Name','Filtrado del Termopar','Position',[100 100 900 650]);

subplot(2,1,1);
plot(t, V_total, 'Color', [0.6 0.6 0.6]); hold on;
plot(t, V_termopar, 'b--', 'LineWidth', 1.5);
title('ANTES del filtro: señal del termopar + ruido 60 Hz (2 V) + ruido blanco');
xlabel('Tiempo (s)'); ylabel('Tensión (V)');
legend('Señal cruda', 'Valor real del termopar (35.3 mV)');
grid on; ylim([-2.5 2.5]);

subplot(2,1,2);
plot(t, V_filtrada, 'r', 'LineWidth', 2); hold on;
plot(t, V_termopar, 'b--', 'LineWidth', 1.5);
title(sprintf('DESPUÉS del filtro Butterworth 2do orden (f_c = %d Hz)', fc));
xlabel('Tiempo (s)'); ylabel('Tensión (V)');
legend('Señal recuperada (hacia el ADC)', 'Valor real (35.3 mV)');
grid on; ylim([0 0.05]);

%% 6. Gráfica 2: respuesta en frecuencia (verificación manual, sin toolbox)
f  = logspace(-1, 3, 1000);          % De 0.1 Hz a 1000 Hz
w  = 2*pi*f/fs;                      % Frecuencia digital normalizada
z  = exp(1j*w);                      % z = e^(jw)
Hz = (b(1)*z.^2 + b(2)*z + b(3)) ./ (z.^2 + a(2)*z + a(3));

figure('Name','Respuesta en Frecuencia');
semilogx(f, 20*log10(abs(Hz)), 'b', 'LineWidth', 2); hold on;
xline(fc, 'r--', 'f_c = 5 Hz (-3 dB)');
xline(60, 'k--', 'Ruido 60 Hz');
yline(-3, 'g:', '-3 dB');
title('Respuesta en frecuencia del filtro H(z)');
xlabel('Frecuencia (Hz)'); ylabel('Magnitud (dB)');
grid on; xlim([0.1 1000]);

% Atenuación exacta a 60 Hz
atenuacion_60Hz = 20*log10(abs(interp1(f, Hz, 60)));
fprintf('Atenuación del filtro a 60 Hz: %.2f dB\n', atenuacion_60Hz);
