

## Input controls

The controls are broken into four sections: **(1) Radiance vs. FRPD controls**, **(2) Emitted Endmember 1**, **(3) Emitted Endmember 2**, and **(4) Background Endmember**.

***



### **(1) Radiance vs. FRPD controls**

This section provides controls for the calculation and plotting of spectral radiance (W m⁻² sr⁻¹ μm⁻¹) vs. FRPD (Wm⁻²). Most inputs are for the calculation of random spectral mixtures between two different emitted radiance endmembers (e.g., for smoldering and flaming temperatures) and a background endmember. The dashboard creates the specified number of samples as mixtures within temperature and fraction constraints using a Dirichlet distribution. Changing these inputs influences the fit of radiance-FRPD relationships.

***

### Wavelength

**Description:** Wavelength, in micrometers (μm), for all radiance and FRPD calculations. 

**Arguments:** Numeric text input

**Default value(s):** 4.07 

**Context:** Radiance calculations are all wavelength-dependent.

***

### Number of samples

**Description:** The number of points plotted in the Radiance vs. FRPD data space. 

**Arguments:** Numeric text input

**Default value(s):** 5000

**Context:** Extremely low fractional maximums may inhibit the drawing of sufficient samples. 

***

### **(2,3,4) Radiance Mixing Parameters: Emitted EM1, Emitted EM2, Background EM3**

Parameters under these subheadings control how spectral radiance is mixed according to Eq. 1 (see plot description for `Radiance vs. FRPD`). Users can control temperature ranges, fractions, and emissivities associated with emitted radiance EMs. Users may also control the magnitude of the background radiance endmember (W m⁻² sr⁻¹ μm⁻¹). Default input values represent emitted radiance from a smoldering (EM1) and flaming (EM2) endmemeber.

***

### EM1 & EM2: Temperature Range

**Description:** Minimum and maximum temperature in Kelvin (K) used to define the temperature distribution for each emitted radiance endmember.Each uniformly sampled temperature from within each range is then used to calculate spectral radiance according to Equation 1. 

**Arguments:** Dual numeric slider selection

**Default value(s):** 

* EM1: 500 - 850 K 
* EM2: 950 - 1450 K


***

### EM1 & EM2: Fraction Maximum

**Description:** The three fractions defined in Equation 1 are drawn from a Dirichlet distribution with alpha values (1, 1, 1), meaning each variable is equally weighted, and the sum of all fractions must equal 1. The maximum value defined by this parameter ensures that samples drawn from the Dirichlet distribution must meet or fall below the defined fraction maximum to be included in the output plot and in the calculation of model fit.  

**Arguments:** Numeric slider selection

**Default value(s):** 

* EM1: 0.5
* EM2: 0.25

**Context:** Extremely low fractional maximums may inhibit the drawing of sufficient samples. 

***
### EM1 & EM2: Emissivity Range, spectral

**Description:** Spectral emissivity used in the calculation of mixed spectral radiance (Eq. 1; see plot description for `Radiance vs. FRPD`). 

**Arguments:** Numeric slider selection

**Default value(s):** 
* EM1: 0.6 - 0.7
* EM2: 0.6 - 0.9

**Context:** Spectral emissivity values are uniformly sampled from within each range. If you want to assume the emitted endmembers are blackbodies, all-wave and spectral emissivity should both equal 1. 

***

### EM1 & EM2: Emissivity, all-wave

**Description:** All-wave emissivity used in the calculation of theoretical FRPD (Eq. 3; see plot description for `Radiance vs. FRPD`).

**Arguments:** Numeric slider selection

**Default value(s):** 
* EM1: 0.65
* EM2: 0.75

**Context:** If you assume the emitted endmembers are blackbodies, all-wave and spectral emissivity should both equal 1. 

***



### Background EM3: Background radiance

**Description:** Value in W m⁻² sr⁻¹ μm⁻¹ for the term $L(\lambda)_3$ in Eq. 1 (see plot description for `Radiance vs. FRPD`).

**Arguments:** Numeric text input

**Default value(s):** 0.0

**Context:** Background radiance to be included in the spectral mixtures (Eq. 1)


