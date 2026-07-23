function ticks = getNiceTicks(dmin, dmax)
    % Handle pure zero matrices or totally flat data
    if dmin == dmax
        dmin = dmin - 1e-3; dmax = dmax + 1e-3;
    end
    
    % Target 3 intervals for exactly 4 ticks
    raw_step = (dmax - dmin) / 3;
    mag = 10^floor(log10(raw_step));
    val = raw_step / mag;
    
    % Defined "nice" stepping bases (including 2.2 for steps like 22)
    nice_bases = [1, 1.2, 1.5, 2, 2.2, 2.5, 3, 4, 5, 6, 7, 8, 9, 10]; 
    idx = find(nice_bases >= val, 1);
    
    while true
        step = nice_bases(idx) * mag;
        t_min = floor(dmin / step) * step;
        t_max = t_min + 3 * step;
        
        % If our boundaries safely encompass the data, stop searching
        if t_max >= dmax
            break;
        end
        
        % Otherwise, bump to the next nice multiplier
        idx = idx + 1;
        if idx > length(nice_bases)
            mag = mag * 10;
            idx = 1;
        end
    end
    
    ticks = linspace(t_min, t_max, 4);
end