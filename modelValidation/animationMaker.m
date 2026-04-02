% clf;

% anim1 = 4;
% anim2 = 1;

%% Make an animation of the models over time and distance (separately)
animFnVsT = append(figDir,'/',prefixStr,'modelAnimationVsT.gif');
animFnVsX = append(figDir,'/',prefixStr,'modelAnimationVsX.gif');
delayTime = 0.1;            % Time between frames (seconds)

if anim1 == 1
figure(2);
set(gcf,'color','w')
subplot(1,2,1)
% h1 = plot(T(1,:), pressure(1,:), 'LineWidth', lw);
h1 = plot(1000*T(:,1), 0.001*pressure(:,1), 'LineWidth', lw);
grid on
xlabel('Time (ms)')
ylabel('Pressure (kPa)');

subplot(1,2,2)
% h2 = plot(T(1,:), velocity(1,:), 'LineWidth', lw);
h2 = plot(1000*T(:,1), mach2ms*velocity(:,1), 'LineWidth', lw);
grid on
xlabel('Time (ms)')
ylabel('Velocity (m/s)');
end

if anim2 == 1
figure(3);
set(gcf,'color','w')
subplot(1,2,1)
h3 = plot(X(1,:), 0.001*pressure(1,:), 'LineWidth', lw);
grid on
xlabel('Distance (m)')
ylabel('Pressure (kPa)');

subplot(1,2,2)
h4 = plot(X(1,:), mach2ms*velocity(1,:), 'LineWidth', lw);
grid on
xlabel('Distance (m)')
ylabel('Velocity (m/s)');
end

for k = 1:N
    % Update the data
    if anim1 == 1
        % set(h1, 'YData', pressure(k,:));
        set(h1, 'XData', 1000*T(:,k), 'YData', 0.001*pressure(:,k));
        set(h2, 'XData', 1000*T(:,k), 'YData', mach2ms*velocity(:,k));
    
        % vs T
        figure(2)
        sgtitle(sprintf('d = %.3f m', X(1,k)));
    
        drawnow;
        frame = getframe(gcf);
        im = frame2im(frame);
        [A, map] = rgb2ind(im, 256);
        subplot(1,2,1)
        xlim([1000*min(tspan) 1000*max(tspan)])
        
        subplot(1,2,2)
        xlim([1000*min(tspan) 1000*max(tspan)])
    
        if k == 1
            imwrite(A, map, animFnVsT, 'gif', ...
                'LoopCount', Inf, 'DelayTime', delayTime);
        else
            imwrite(A, map, animFnVsT, 'gif', ...
                'WriteMode', 'append', 'DelayTime', delayTime);
        end
    end

    % Update the data
    if anim2 == 1
        % set(h3, 'YData', pressure(k,:));
        set(h3, 'XData', X(k,:), 'YData', 0.001*pressure(k,:));
        set(h4, 'XData', X(k,:), 'YData', mach2ms*velocity(k,:));
    
        % vs X
        figure(3)
        sgtitle(sprintf('t = %.3f ms', 1000*T(k,1)));
    
        drawnow;
        frame = getframe(gcf);
        im = frame2im(frame);
        [A, map] = rgb2ind(im, 256);
        subplot(1,2,1)
        xlim([min(x) max(x)])
        
        subplot(1,2,2)
        xlim([min(x) max(x)])
    
        if k == 1
            imwrite(A, map, animFnVsX, 'gif', ...
                'LoopCount', Inf, 'DelayTime', delayTime);
        else
            imwrite(A, map, animFnVsX, 'gif', ...
                'WriteMode', 'append', 'DelayTime', delayTime);
        end
    end
    % pause(1);
end