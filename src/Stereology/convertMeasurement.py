def convertMeasurement(myMeasurement_path):
    # convert 2D observed area in 3D diameters, assuming spherical shape
    # save 3D reconstructed diameter as .mat file 

    from size_estimation_unit_radius import estimate_size
    import numpy as np
    import pandas as pd
    from pathlib import Path
    from scipy.io import savemat

    full_path = Path(myMeasurement_path).expanduser()
    if not full_path.exists():
        raise FileNotFoundError(f"File {full_path} does not exist")

    myMeasurement_data = pd.read_csv(str(full_path))
    diam_array = myMeasurement_data['EquivDiameter'].to_numpy()
    diam_2D = np.unique(diam_array)
    sample = (diam_2D**2)*1./4.*np.pi

    # Estimate the underlying size distribution CDF using the sample of observed section areas
    xcdf_est, ycdf_est = estimate_size(sample,debias=False) 

    # For plotting with the matplotlib step function, we need to add some additional points
    xcdf_est = np.append(np.append(0, xcdf_est), 1.05*xcdf_est[-1])
    ycdf_est = np.append(np.append(0, ycdf_est), 1)

   # Calculate Probability
    yp_est = np.diff(ycdf_est) # estimated probability
    ntot = len(diam_2D) 
    n_per_bin = np.round(yp_est * ntot).astype(int)  # number of particles per each bin according to the estimated probability
    radius_3D = np.repeat(xcdf_est[1:], n_per_bin)   # sampling from the the estimated distribution

    # Saving mat file
    diam_3D = radius_3D*2. 
    diam_3D_save = diam_3D.reshape(-1,1)
    data_to_save = {
        'bubbleTable': {
            'EquivDiameter': diam_3D_save
        }
    }
    
    input_path = Path(myMeasurement_path)
    filename_stem = input_path.stem
    suffix_number = filename_stem[-3:]
    new_filename = input_path.parent / f"measurementsStereoTable_{suffix_number}.mat"

    savemat(new_filename,data_to_save)

    # Convert radius in diameter
    xxcdf_est = xcdf_est*2.

    return diam_2D, diam_3D, xxcdf_est, ycdf_est

