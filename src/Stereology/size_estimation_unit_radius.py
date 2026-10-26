from pysizeunfolder.algorithms import hybrid_icm_em
import numpy as np
from math import pi, sqrt


def gs_sphere(x):
    y = np.zeros(len(x))
    indices = x*x < pi
    y[indices] = x[indices]/(np.sqrt(1-x[indices]*x[indices]/pi))
    return y


def sphere_G(x):
    y = np.zeros(len(x))
    y[x >= sqrt(pi)] = 1
    x_ = x[x < sqrt(pi)]
    y[x < sqrt(pi)] = 1 - np.sqrt(1 - x_*x_/pi)
    return y


def de_bias_sphere(x_pts, estimate, G_cdf):
    n = len(x_pts)
    observed_x = np.linspace(0, 1, n)
    distances = np.zeros(n)
    Hb_probabilities = np.append(estimate[0], np.diff(estimate))

    FS_estimates = np.zeros((n, n))
    for i in range(n):
        kernel = G_cdf(x_pts[i] / x_pts)
        divisor = np.cumsum(np.flip(Hb_probabilities))
        divisor[divisor == 0.0] = 1.0
        FS_estimates[:, i] = np.flip(np.cumsum(np.flip(kernel * Hb_probabilities)) / divisor)

    for i in range(n):
        term1 = np.abs(observed_x - FS_estimates[i, :])[:(n - 1)]
        term2 = np.abs(observed_x[1:] - FS_estimates[i, :(n - 1)])
        distances[i] = 0.5 * np.dot(term1 + term2, np.diff(x_pts))

    trunc_ix = np.argmin(distances)
    temp_hb = np.copy(Hb_probabilities)
    temp_hb[:trunc_ix] = 0.0
    h_est = np.cumsum(temp_hb / x_pts)
    h_est = h_est / h_est[-1]
    return h_est


def estimate_size(observed_areas, debias=True,
                  tol=0.0001, stop_iterations=10):
    """
    A function for estimating the radii distribution CDF given a sample of observed section areas assuming spherical particles.
    The so-called length-biased size distribution CDF $H^b$ is estimated via nonparametric maximum likelihood.
    If 'debias' is set to true an additional step is performed and the estimate of $H^b$ is used to
    estimate the size distribution CDF. For details of the interpretation of these distributions and the estimation
    procedure see the paper: "Stereological determination of particle size distributions".

    NOTE: The given sample of section areas should not contain any duplicates. Within the model setting this
    is a probability zero event. In practice it may be the case that this does occur, especially when the
    measurement device used to obtain the data does not have a very high resolution. If this kind of data
    is presented to this function, a very small amount of noise is added to the data, to ensure unique values.
    This functionality is not extensively tested, you may manually add a negligible amount of noise to your data for
    more control.

    :param observed_areas: A sample of observed section areas, a numpy.ndarray of shape (n,) where n is the sample size.
    :param debias: A boolean, if True the size distribution is estimated, sometimes called number weighted size
        distribution. If False, the length-biased size distribution is estimated, may be interpreted as diameter
        weighted size distribution.
    :param tol: A double, the tolerance used for stopping the optimization procedure (maximum likelihood). If the
        largest change in probability mass between estimates of successive iterations is below 'tol' for
        'stop_iterations' successive iterations the algorithm is terminated.
    :param stop_iterations: An integer, indicating for how many iterations the optimization procedure should run such
        that the largest change in probability mass of the estimate compared to the previous estimate is below 'tol'.
    :return: Two numpy arrays: x_pts, y_pts. Both are a numpy.ndarray of shape (n,). These arrays represent a piece-wise
        constant distribution function. The CDF is constant on [x_pts[i],x_pts[i+1]). Here: [a,b) = {x: a <= x < b}.
        y_pts[i] is the CDF value in x_pts[i].
    """
    sqrt_sample = np.sqrt(observed_areas)
    n = len(sqrt_sample)
    rng = np.random.default_rng(0)
    sigma = np.std(sqrt_sample)

    if len(np.unique(sqrt_sample)) < n:
        print("Warning: input contains duplicate values, adding a small amount of noise.")
        sqrt_sample = np.abs(sqrt_sample + rng.normal(loc=0, scale=0.000001*sigma, size=n))
    sqrt_sample = np.sort(sqrt_sample)

    # compute matrix alpha_{i,j}
    mat = np.broadcast_to(sqrt_sample, (n, n))
    input_mat = mat.T / mat
    data_matrix = np.reshape(gs_sphere(input_mat.flatten()), (n, n)) / mat

    # Compute MLE
    est = hybrid_icm_em(data_matrix, tol=tol, stop_iterations=stop_iterations)

    # Perform debiasing step if required
    if debias:
        est = de_bias_sphere(sqrt_sample, est, sphere_G)

    return sqrt_sample, est