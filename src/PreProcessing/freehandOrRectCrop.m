function [croppedImage, maskArea, mask, rect] = freehandOrRectCrop(imagePath, savePath, prevMask, prevRect)
    % Read the image
    originalImage = imread(imagePath);
    [~, ~, numberOfColorChannels] = size(originalImage);

    % Convert to grayscale if necessary
    if numberOfColorChannels > 1
        fprintf('Original image file has %d color channels. Converting to grayscale...\n', numberOfColorChannels);
        grayImage = rgb2gray(originalImage);
    else
        grayImage = originalImage;
    end

    % If there is a previous crop, ask the user whether to reuse it
    reusePrevious = false;
    if ~isempty(prevMask) && ~isempty(prevRect)
        choice = questdlg('Apply previous crop or select new?', ...
                          'Crop Selection', 'New Crop', 'Use Previous', 'New Crop');

        if strcmp(choice, 'Use Previous')
            reusePrevious = true;
        end
    end

    if reusePrevious
        % Apply the previous crop
        fprintf('Applying previous crop...\n');

        % Crop the image using the previous bounding box on grayscale image
        croppedImage = imcrop(grayImage, prevRect);
        maskCropped = imcrop(prevMask, prevRect);
        
        % Ensure the mask is applied correctly
        if isempty(maskCropped)
            maskArea = 0;
        else
            maskArea = sum(maskCropped(:));
        end

        if numberOfColorChannels > 1
            whiteBackground = uint8(255 * ones(size(croppedImage)));
            maskCropped = uint8(repmat(maskCropped, [1, 1, numberOfColorChannels]));
            croppedImage = croppedImage .* maskCropped + whiteBackground .* uint8(~maskCropped);
        else
            croppedImage = croppedImage .* uint8(maskCropped) + uint8(~maskCropped) * 255;
        end

        mask = prevMask;
        rect = prevRect;

    else
        % Display the grayscale image for cropping
        close all; % Close any previous figures
        figure, imshow(grayImage, 'InitialMagnification', 'fit');
        title('Select area using Freehand or Rectangle. Double cick on image when finished.');

        % Ask the user to choose cropping method
        cropMethod = questdlg('Choose cropping method:', 'Cropping Mode', 'Freehand', 'Rectangle', 'Freehand');

        if strcmp(cropMethod, 'Freehand')
            h = drawfreehand();
        else
            h = drawrectangle();
        end

        % Wait for user confirmation
        wait(h);

        % If no selection is made, return empty
        if isempty(h.Position)
            disp('No selection made. Exiting function.');
            croppedImage = [];
            maskArea = [];
            mask = [];
            rect = [];
            return;
        end

        % Create binary mask from selection
        mask = createMask(h);
        
        % Calculate area inside the mask (in pixels²)
        maskArea = sum(mask(:));

        % Get cropping rectangle
        [rowIdx, colIdx] = find(mask);
        xmin = min(colIdx);
        xmax = max(colIdx);
        ymin = min(rowIdx);
        ymax = max(rowIdx);
        rect = [xmin, ymin, xmax - xmin, ymax - ymin];

        % Crop the grayscale image using the bounding box
        croppedImage = imcrop(grayImage, rect);
        maskCropped = imcrop(mask, rect);

        % Ensure the mask is applied correctly
        if numberOfColorChannels > 1
            whiteBackground = uint8(255 * ones(size(croppedImage)));
            maskCropped = uint8(repmat(maskCropped, [1, 1, numberOfColorChannels]));
            croppedImage = croppedImage .* maskCropped + whiteBackground .* uint8(~maskCropped);
        else
            croppedImage = croppedImage .* uint8(maskCropped) + uint8(~maskCropped) * 255;
        end
    end

    % Display cropped image
    close all; % Close previous figure
    figure, imshow(croppedImage, 'InitialMagnification', 'fit');
    title('Cropped Image with White Background');

    % Save if a path is provided
    if nargin > 1 && ~isempty(savePath)
        if ~isa(croppedImage, 'uint8')
            croppedImage = im2uint8(croppedImage);
        end
        % Ensure the savePath ends with .jpg
        [folder, name, ~] = fileparts(savePath);
        savePath = fullfile(folder, [name, '.jpg']);
        imwrite(croppedImage, savePath, 'jpg', 'Quality', 100);
        fprintf('Cropped image saved to: %s\n', savePath);
    end
end

