% clf

[~, idx] = min(abs(x-15));

figure(5);
set(gcf,'color','w')
subplot(1,2,1)
% h3 = plot(X(:,idx), 0.001*pressure(:,idx), 'LineWidth', lw);
% h3 = plot(X(idx,:), 0.001*pressure(idx,:), 'LineWidth', lw);
% h3 = plot(X(idx,:), 0.001*pressure(:,idx), 'LineWidth', lw);
h3 = plot(1000*T(:,idx), 0.001*pressure(:,idx), 'LineWidth', lw);
grid on
xlabel('Time (ms)')
ylabel('Pressure (kPa)');

subplot(1,2,2)
% h4 = plot(X(:,idx), mach2ms*velocity(:,idx), 'LineWidth', lw);
h4 = plot(1000*T(:,idx), mach2ms*velocity(:,idx), 'LineWidth', lw);
hold on
% h4 = plot(1000*T(:,idx), mach2ms*velocity(idx,:), 'LineWidth', lw);
% h4 = plot(1000*T(idx,:), mach2ms*velocity(:,idx), 'LineWidth', lw);
% h4 = plot(1000*T(idx,:), mach2ms*velocity(idx,:), 'LineWidth', lw);
% h4 = plot(X(idx,:), mach2ms*velocity(idx,:), 'LineWidth', lw);
% h4 = plot(X(idx,:), mach2ms*velocity(:,idx), 'LineWidth', lw);
grid on
xlabel('Time (ms)')
ylabel('Velocity (m/s)');
savePlot('firstTimeStep_pandv_vs_t',figDir)