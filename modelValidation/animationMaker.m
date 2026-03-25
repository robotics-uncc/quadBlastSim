clf;

anim1 = 0;
anim2 = 1;

%% Make an animation of the models over time and distance (separately)
animFnVsT = append(figDir,'/modelAnimationVsT.gif');
animFnVsX = append(figDir,'/modelAnimationVsX.gif');
delayTime = 0.3;            % Time between frames (seconds)

if anim1 == 1
figure(2);
set(gcf,'color','w')
subplot(1,2,1)
h1 = plot(T(1,:), pressure(1,:), 'LineWidth', lw);
grid on
xlabel('Time (sec)')
ylabel('Pressure (Pa)');

subplot(1,2,2)
h2 = plot(T(1,:), velocity(1,:), 'LineWidth', lw);
grid on
xlabel('Time (sec)')
ylabel('Velocity (m/s)');
end

if anim2 == 1
figure(3);
set(gcf,'color','w')
subplot(1,2,1)
h3 = plot(X(1,:), pressure(1,:), 'LineWidth', lw);
grid on
xlabel('Distance (m)')
ylabel('Pressure (Pa)');

subplot(1,2,2)
h4 = plot(X(1,:), velocity(1,:), 'LineWidth', lw);
grid on
xlabel('Distance (m)')
ylabel('Velocity (m/s)');
end

for k = 1:N
    % Update the data
    if anim1 == 1
    set(h1, 'YData', pressure(k,:));
    set(h2, 'YData', velocity(k,:));

    % vs T
    figure(2)
    sgtitle(sprintf('d = %f', X(k,k)));

    drawnow;
    frame = getframe(gcf);
    im = frame2im(frame);
    [A, map] = rgb2ind(im, 256);

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
    set(h3, 'YData', pressure(k,:));
    set(h4, 'YData', velocity(k,:));

    % vs X
    figure(3)
    sgtitle(sprintf('t = %f', T(k,k)));

    drawnow;
    frame = getframe(gcf);
    im = frame2im(frame);
    [A, map] = rgb2ind(im, 256);

    if k == 1
        imwrite(A, map, animFnVsX, 'gif', ...
            'LoopCount', Inf, 'DelayTime', delayTime);
    else
        imwrite(A, map, animFnVsX, 'gif', ...
            'WriteMode', 'append', 'DelayTime', delayTime);
    end
    end
    % pause
end