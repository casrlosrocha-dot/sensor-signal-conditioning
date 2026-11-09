% =========================================================================
% SIMULACIÓN DINÁMICA DE ACONDICIONAMIENTO DE LVDT (LEYENDAS EN NEGRO)
% =========================================================================
clear; clc; close all;

%% 1. Parámetros del Sistema y Sensores
f_exc = 2500;             % Frecuencia de excitación del LVDT (2.5 kHz)
w_exc = 2*pi*f_exc;
V_exc_rms = 3;            % Excitación de 3 Vrms
V_exc_p = V_exc_rms * sqrt(2); % ~4.2426 Vp

S = 40e-3;                % Sensibilidad: 40 mV/V/mm = 0.040 V/V/mm
f_m = 5;                  % Frecuencia del movimiento mecánico (5 Hz)
w_m = 2*pi*f_m;
x_max = 4;                % Amplitud de desplazamiento (+/- 4 mm)

% Tiempo de simulación
fs = 100000;              % Frecuencia de muestreo (100 kHz)
dt = 1/fs;
t = 0:dt:0.6;             % 0.6 segundos

%% 2. Generación de Señales
% a) Desplazamiento mecánico real x(t) en mm
x_real = x_max * sin(w_m * t);

% b) Señal de Excitación V_ref(t)
V_ref = V_exc_p * sin(w_exc * t);

% c) Señal Diferencial del Secundario V_dif(t)
V_dif = (S * V_exc_p) .* x_real .* sin(w_exc * t);

% d) Demodulación Síncrona con el AD633 (División por 10)
V_demod = (V_dif .* V_ref) / 10;

%% 3. Filtrado Pasa Bajas (Transformada Bilineal)
R1 = 11e3; R2 = 11e3;
C1 = 220e-9; C2 = 100e-9;

a2 = R1 * R2 * C1 * C2;
a1 = (R1 + R2) * C2;
a0 = 1;

K = 2 / dt;
b0_c = 1;

A_denom = a2*K^2 + a1*K + a0;
b = [b0_c, 2*b0_c, b0_c] / A_denom;
a = [A_denom, 2*a0 - 2*a2*K^2, a2*K^2 - a1*K + a0] / A_denom;

V_filtrada = filter(b, a, V_demod);

%% 4. Reconstrucción del Desplazamiento
K_factor = (S * (V_exc_p^2)) / 20; 
x_rec = V_filtrada / K_factor;

%% 5. Cálculo del Retardo
fc = 1 / (2*pi*sqrt(R1*R2*C1*C2));
w5 = 2*pi*f_m;
H_5Hz = 1 / (1 - a2*(w5^2) + 1i*a1*w5);
fase_deg = abs(angle(H_5Hz) * 180 / pi);
retardo_tiempo = (fase_deg / 360) * (1/f_m);

fprintf('=== RESULTADOS DEL ANÁLISIS EN MATLAB ===\n');
fprintf('Frecuencia de corte del filtro (fc): %.2f Hz\n', fc);
fprintf('Desfasaje del filtro a 5 Hz: %.2f grados\n', fase_deg);
fprintf('Retardo de tiempo introducido: %.2f ms\n', retardo_tiempo * 1000);

%% 6. Gráficas con Leyendas en Negro y Texto Blanco
fig = figure('Color', [1 1 1]); % Fondo blanco de la figura

% --- SUBPLOT 1 ---
ax1 = subplot(3,1,1);
plot(t*1000, V_ref, 'Color', [0 0.7 0], 'LineWidth', 1.2); hold on;
plot(t*1000, V_dif, 'b', 'LineWidth', 1.5);
title('Señales de Alta Frecuencia (2.5 kHz)', 'Color', 'k', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Tiempo (ms)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
lgd1 = legend('Excitación V_{ref}', 'Salida Secundario V_{dif}');
set(lgd1, 'TextColor', 'w', 'Color', 'k', 'EdgeColor', 'k'); % Fondo negro, letras blancas
xlim([0 40]); grid on;
set(ax1, 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.4 0.4 0.4], 'FontWeight', 'bold');

% --- SUBPLOT 2 ---
ax2 = subplot(3,1,2);
plot(t*1000, V_demod, 'r', 'LineWidth', 0.8); hold on;
plot(t*1000, V_filtrada, 'k', 'LineWidth', 2);
title('Demodulación Síncrona y Salida del Filtro LPF', 'Color', 'k', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Tiempo (ms)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
lgd2 = legend('Señal Demodulada (AD633)', 'Señal Filtrada (LM358)');
set(lgd2, 'TextColor', 'w', 'Color', 'k', 'EdgeColor', 'k'); % Fondo negro, letras blancas
xlim([0 200]); grid on;
set(ax2, 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.4 0.4 0.4], 'FontWeight', 'bold');

% --- SUBPLOT 3 ---
ax3 = subplot(3,1,3);
plot(t*1000, x_real, 'b--', 'LineWidth', 2); hold on;
plot(t*1000, x_rec, 'r', 'LineWidth', 2);
title('Desplazamiento Real vs. Reconstruido (Análisis de Retardo)', 'Color', 'k', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Tiempo (ms)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Desplazamiento (mm)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
lgd3 = legend('x Real (\pm4 mm @ 5Hz)', 'x Reconstruido');
set(lgd3, 'TextColor', 'w', 'Color', 'k', 'EdgeColor', 'k'); % Fondo negro, letras blancas
xlim([0 300]); grid on;
set(ax3, 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.4 0.4 0.4], 'FontWeight', 'bold');