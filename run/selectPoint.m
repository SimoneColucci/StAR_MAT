function [x_select, y_select] = selectPoint(x, y) 
    
    shg;

    waitforbuttonpress;
    point = get(gca, 'CurrentPoint'); 
    x_click = point(1,1);
    y_click = point(1,2);
    
    title('');
    
    if isempty(x_click)
        disp('No points selected');
        x_select = [];
        y_select = [];
    else
        x_val = 10^(x_click-6);
        y_val = 10^(y_click);
        
        % Snap to data
        distance = (x - x_val).^2 + (y - y_val).^2;
        [~, idx] = min(distance);
        
        x_select = x(idx);
        y_select = y(idx);
        
        fprintf('Selected point: x=%e, y=%e\n', x_select, y_select);
    end
end