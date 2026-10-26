def stereology(myMeasurement_path):

    from convertMeasurement import convertMeasurement
    import matplotlib.pyplot as plt
    import numpy as np
    from scipy.interpolate import PchipInterpolator
    from pathlib import Path

    diam_2D, diam_3D, xcdf_est, ycdf_est = convertMeasurement(myMeasurement_path)

    # Plotting

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # plot probability
    nbin = 20
    ax1.hist(diam_2D, bins=nbin,alpha=0.5, label="2D", color="tab:blue", edgecolor='blue')
    ax1.hist(diam_3D, bins=nbin,alpha=0.5, label="3D", color="tab:red", edgecolor='red')
    ax1.set_xlabel("Diameter (m)")
    ax1.set_ylabel("Frequency")
    ax1.legend()
    ax1.grid(axis='y', alpha=0.3)

    # plot cdf
    diam_2D = np.sort(diam_2D)
    cdf_2D = np.linspace(0, 1, len(diam_2D))
    ax2.step(diam_2D, cdf_2D, where="post", c="tab:blue", label="2D")
    ax2.step(xcdf_est, ycdf_est, where="post", c="tab:red", label="3Dstereo")
    ax2.set_xlabel("Diameter (m)")
    ax2.set_ylabel("CDF")
    ax2.legend(loc="lower right")
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    
    # Save in the input file directory 
    input_path = Path(myMeasurement_path) 
    suffix_number = input_path.stem[-3:] 
    figure_path = ( input_path.parent / f"Stereology_{suffix_number}.png" ) 
    fig.savefig( figure_path, dpi=300, bbox_inches="tight" ) 
    plt.close(fig)

    return diam_3D
