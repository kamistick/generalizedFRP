
#### **Spectral mixing**

The `FRPD vs. Radiance` plot displays a user-defined data space where spectral radiance is mixed according to:

$$L(\lambda, T)_m = L(\lambda, T_1) f_1 \varepsilon_{1, \lambda} + L(\lambda, T_2) f_2 \varepsilon_{2, \lambda} + L(\lambda)_3 f_3  \tag{Eq. 1}$$

Where $L(\lambda, T)_m$ is total mixed radiance ($W m^{-2} sr^{-1} \mu m^{-1}$), $L(\lambda)_3$ is background radiance and $f_x$ is the fractional contribution of the $x$th EM. For $x$ in $[1, 2]$, $L(\lambda, T)_x$ is emitted radiance for the $x$th endmember (EM) and $\varepsilon_{x, \lambda}$ is spectral emissivity for the $x$th EM. The emitted radiance EMs are calculated using Planck's equation:

$$L(\lambda, T) = \frac{C_1}{\lambda^5 (exp(\frac{C2}{\lambda T})-1)} \tag{Eq. 2}$$

Where $\lambda$ is wavelength in $m$, $T$ is temperature in $K$, $C_1 = 1.191 \times 10^{-16} W m^{-2} sr^{-1}$ and $C_2 = 1.439 \times 10^{-2} mK$.

Variables in Equation 1 are set based on controls to the left, where the default parameters treat the first endmember as characterizing smoldering combustion and the second endmember as characterizing flaming combustion.

The points in `FRPD vs. Radiance` have a viridis color scheme where
<span style='background-color: #FDE725; color: black; padding: 2px 4px; border-radius: 3px;'>
yellow
</span> 
 indicates a high point density and 
<span style='background-color: #440154; color: white; padding: 2px 4px; border-radius: 3px;'>
purple
</span> 
 indicates a low point density.
***


#### **Fire radiative power density (FRPD) calculation**

True FRPD ($W/m^2$) is calculated according to:

$$FRPD = \sigma f_1 \varepsilon_{1, aw} T_{1}^4 + \sigma f_{2} \varepsilon_{2, aw} T_{2}^4 \tag{Eq. 3}$$

Where $\sigma$ is Stefan Boltzmann's constant ($W m^{-2}K^{-4}$), $f_{x}$ is the fractional contribution of the $x$th emitted endmemder, $\varepsilon_{x, aw}$ is all-wave emissivity associated with the $x$th emitted endmemder, and $T_{x}$ is temperature of the $x$th emitted endmemder ($K$).

Temperature ranges and all-wave emissivity are set in the controls to the left.

***


#### **Modeling FRPD**

Two fits are displayed: `Theoretical Fit (Wooster et al. (2003))` and `Empirical Fit: FRPD = aL^b`. For the `Theoretical Fit` FRPD is calculated according to the method first proposed by Wooster et al. (2003):

$$FRPD = \frac{L_{diff} \sigma}{\alpha} \tag{Eq. 4}$$

Where $\sigma$ is Stefan Boltzmann's constant ($W m^{-2}K^{-4}$), $L_{diff}$ is spectral radiance (Eq. 1) from which background radiance is subtracted, and coefficient $\alpha$ is calculated by approximating Planck's equation over a range of temperatures (600 to 1300 K, with a step of 10 K) using the relationship:

$$L = \alpha T^4 \tag{Eq. 5}$$

This method was originally developed for fire radiative power (FRP) which is related to FRPD such that $FRPD = FRP \times A$, where FRP (W) accounts for an area $A$ ($m^2$) over which the FRPD is being measured.

The `Empirical Fit: FRPD = aL^b` fit is calculated according to:

$$FRPD = a L_{m}^b \tag{Eq. 6}$$

Where coefficients $a$ and $b$ are fit using nonlinear least squares regression, $L_m$ is mixed spectral radiance (Eq. 1) and $FRPD$ is true FRPD (Eq. 3).

nRMSE values shown on the `FRPD vs. Radiance` plot indicate the RMSE of each model calculated with respect to FRPD values of the mixed radiance data points, normalized using mean FRPD.

***