% Spatially calibrate your image and then make distance or area measurements.
function px2m = spatialCalibration(imagePath)

    % Read the image
    originalImage = imread(imagePath);

    % Open a figure with the image
    figureHandle = figure;
    imshow(originalImage,'InitialMagnification', 'fit');
    axis on;
    set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);

    % Set the title with instructions
    title('Calibration: Left-click to set the first endpoint of a line. Right-click or double-left-click to set the second endpoint.');

    % Attempt calibration
    [success, px2m] = Calibrate(figureHandle);
    
    % Keep retrying if unsuccessful
    while ~success
        [success, px2m] = Calibrate(figureHandle);
    end

    % Close figure after successful calibration
    close(figureHandle);
end

%=====================================================================
function [success, px2m] = Calibrate(figureHandle)
    try
        success = false;

        % Get two points from user
        [~, ~, ~, xi, yi] = improfile(1000);
        
        % Ensure two points were selected
        if numel(xi) < 2 || numel(yi) < 2
            title('Error: Select two points.');
            pause(2);
            return;
        end

        % Compute pixel distance
        distanceInPixels = sqrt((xi(2) - xi(1))^2 + (yi(2) - yi(1))^2);

        % Plot the line
        hold on;
        plot(xi, yi, 'y-', 'LineWidth', 2);

        % Ask user for real-world distance and units via a dialog box
        answer = inputdlg({'Enter real-world units (micron, mm, m):', 'Enter distance in those units:'}, ...
                          'Calibration Input', [1 50], {'micron', '100'});
        
        if isempty(answer)
            title('Error: Calibration canceled.');
            pause(2);
            return;
        end

        % Store user inputs
        calibration.units = strtrim(answer{1});
        calibration.distanceInUnits = str2double(answer{2});

        % Validate numerical input
        if isnan(calibration.distanceInUnits) || calibration.distanceInUnits <= 0
            title('Error: Invalid distance.');
            pause(2);
            return;
        end

        % Calculate pixels-to-units ratio
        calibration.distancePerPixel = calibration.distanceInUnits / distanceInPixels;

        % Convert to meters
        switch lower(calibration.units)
            case 'micron'
                px2m = calibration.distancePerPixel * 1e-6;
            case 'mm'
                px2m = calibration.distancePerPixel * 1e-3;
            case 'm'
                px2m = calibration.distancePerPixel;
            otherwise
                px2m = [];
                title('Error: Invalid unit.');
                pause(2);
                return;
        end

        % Update title to show results
        title(sprintf('Calibration Successful: %.2f pixels = %.6f %s', ...
            distanceInPixels, calibration.distanceInUnits, calibration.units));
        
        success = true;

    catch
        title('Error: Calibration failed.');
        pause(2);
    end
end
