;+
; NAME:
;   EXOFASTv2
;
; PURPOSE: 
;   Simultaneously fits RV and/or transit data for multiple
;   planets, transits, RV sources. Please cite Eastman et al., 2013
;   (http://adsabs.harvard.edu/abs/2013PASP..125...83E) if you make
;   use of this routine in your research. Please report errors or bugs
;   to jason.eastman@cfa.harvard.edu
;
; CALLING SEQUENCE:
;   exofast, [RVPATH=, TRANPATH=, PRIORFILE=, FLUXFILE=, PREFIX=, /CIRCULAR,
;             /NOSLOPE, /SECONDARY, /UPDATE, PNAME=, SIGCLIP=, NTHIN=,
;             MAXSTEPS=, MINPERIOD=, MAXPERIOD=, NMIN=, /DISPLAY,
;             /DEBUG, RANDOMFUNC=, SEED=, /SPECPRIORS, /BESTONLY,
;             NINTERP=, EXPTIME=, /LONGCADENCE]
;
; INPUTS:
;
;   PRIORFILE  - An ASCII file with each line containing three white
;                space delimited columns. See
;                $EXOFAST_PATH/parnames.README for a detailed
;                explanation of this file and $EXOFAST_PATH/examples/
;                for templates to use.
;
; OPTIONAL INPUTS:
;   NPLANETS    - The number of planets you wish to fit to the
;                 data. Default is 1. If 0 is set, it will just fit
;                 the star.
;   RVPATH      - A string specifying the path to the RV data
;                 file(s). Wildcards are allowed for multiple files
;                 (e.g., '*.rv'). Each file must have at least 3
;                 columns:
;                   1) Time (BJD_TDB -- See Eastman et al., 2010)
;                   2) RV (m/s)
;                   3) err (m/s)
;                 NOTE 1: The units must be as specified, or the fit
;                 will be wrong or fail. 
;                 NOTE 2: Other input time stamps will likely not
;                 break the code, but can introduce errors in the
;                 reported times of more than a minute. The output
;                 table will display BJD_TDB but makes no attempt to
;                 convert input times.  See
;                 http://adsabs.harvard.edu/abs/2010PASP..122..935E
;                 for an explanation of times
;                 NOTE 3: If RVPATH is omitted, no RV model will be
;                 generated.
;
;   TRANPATH    - A string specifying the path to the transit data
;                 file(s). Wildcards are allowed for multiple files
;                 (e.g., '*.dat'). Each file must have at least 3
;                 columns:
;
;                   1) Time (BJD_TDB -- See Eastman et al., 2010)
;                   2) Normalized flux
;                   3) err
;                   4) Detrend parameter 1
;                   ....
;                   N+3) Detrend parameter N
;       
;                 An optional header specifies which parameters
;                 should be multiplicatively detrended and which
;                 should be additively detrended. Without a header,
;                 all detrending parameters are additively detrended.
; 
;                 The first character in the header line must be
;                 "#". It must have whitespace delimited columns
;                 corresponding to the data. Each multiplicative
;                 detrending variable is preceeded with "M" (case
;                 sensitive). For example, the header line
;
;                 #BJD_TDB FLUX ERR MAIRMASS SKY myval
;
;                 Will fit a multiplicative detrending to the 4th
;                 column (MAIRMASS) and an additive detrending to the
;                 5th and 6th columns (SKY and myval).
;
;                 The corresponding model will be:
;
;                 model = (transit + C0*SKY + C1*myval)*(F0 + M0*MAIRMASS)
;
;                 Where C0, C1, and M0 are fitted detrending
;                 parameters, F0 is the normalization, and SKY,
;                 motion, and MAIRMASS are vectors for each data point
;                 to detrend against.
;
;                 The names of the files describing the transits
;                 *must* adhere to a certain format:
;                 nYYYYMMDD.filtername.telescope.whateveryouwant. 
;
;                 nYYYYMMDD -- The UTC date of mid transit, where YYYY is
;                 the year, MM is the month, and DD is the day. This
;                 is only necessary if the data has a single
;                 transit. This is used to label the transits in the
;                 output plot.
; 
;                 filtername -- The name of the observed
;                 filter. Only certain values are allowed (use the
;                 closest approximation if yours is not in this list;
;                 see quadld.pro): 
;
;                 Johnson/Cousins: 'U','B','V','R','I','J','H','K'
;                 Sloan: 'Sloanu','Sloang','Sloanr','Sloani','Sloanz'
;                 Kepler: 'Kepler'
;                 CoRoT: 'CoRoT'
;                 TESS: 'TESS'
;                 Spitzer: 'Spit36','Spit45','Spit58','Spit80'
;                 Stromgren: 'u','b','v','y'
;
;                 This is used to define the limb darkening for the
;                 transit, dilution, and secondary depth parameters.
;
;                 telescope -- a description of the telescope used for
;                 the observations. Anything is allowed, but all
;                 observations observed with the same telescope should
;                 have the same name. This is used in the output plot
;                 and color codes the TTV plot.
;
;                 whateveryouwant -- any string you want to
;                 include for it to make sense to you. This is not
;                 used by the code.
;
;                 So a transit taken on UTC 2017-01-27 with MINERVA in
;                 the V band would be "n20170127.V.MINERVA.dat"
;
;                 NOTE 2: The units must be as specified, or the fit
;                 will be wrong or fail.
;                 NOTE 3: Other input time stamps will likely not
;                 break the code, but can introduce errors in the
;                 reported times of more than a minute. The output
;                 table will display BJD_TDB but makes no attempt to
;                 convert input times.  See
;                 http://adsabs.harvard.edu/abs/2010PASP..122..935E
;                 for an explanation of times
;                 NOTE 4: If omitted, just the RV data will bit fit
;   DTPATH      - The (optional) path to the Doppler Tomography fits
;                 file(s). If supplied, the code will fit a vsini and
;                 macro turbulence of the star, as well as a
;                 spin-orbit alignment for each planet. This must be
;                 used in conjunction with the FITDT, an NPLANETS
;                 array specifying which planets should have their DT
;                 signal modeled.
;
;                 Each fits file is a 2D array describing all DT
;                 observations during a single transit with extensions
;                 describing the axes of the array. The pixel values
;                 of the 2D array contain the fractional flux
;                 decrement at a given BJD_TDB (spectrum) and velocity
;                 (pixel value of the CCF). The first extension should
;                 specify the BJD_TDB corresponding to each Y pixel
;                 and the second extension should specify the velocity
;                 corresponding to each X pixel.
;
;                 Such a file can be generated given the 2D array of
;                 fractional flux decrements (DT), a time array
;                 (BJD_TDB) and a velocity array (VEL) like this:
; 
;                 writefits,'nYYYYMMDD.instrument.resolution.fits',DT
;                 writefits,'nYYYYMMDD.instrument.resolution.fits',BJD_TDB, /append
;                 writefits,'nYYYYMMDD.instrument.resolution.fits',VEL, /append
;
;                 The names of these files *must* adhere to a certain format:
;                 nYYYYMMDD.instrument.resolution.whateveryouwant.fits 
;
;                 nYYYYMMDD -- The UTC date of mid transit. This is
;                 used to label the transits in the output plot.
; 
;                 instrument -- the name of the instrument used for
;                 the observations. Anything is allowed, but all
;                 observations observed with the same telescope should
;                 have the same name. This is used in the labels.
;
;                 resolution -- The R value of the instrument. This is
;                 required to accurately model the DT signal and must
;                 be correct.
;
;                 whateveryouwant - any string you want to include (or
;                 nothing) for it to make sense to you (e.g, target
;                 name). This is not used by the code.
;
;                 So a transit taken on UTC 2017-01-27 with the TRES
;                 spectrograph (R=44000) would be called
;                 "n20170127.TRES.44000.fits"
; 
;                 NOTE 0: When supplied this way, the DT data does not
;                 constrain vsini. A gaussian prior must be given in
;                 the prior file.
;
;                 NOTE 1: NAXIS1 must equal the number of velocities and
;                 NAXIS2 must equal the number of times.
;
;                 NOTE 2: Not using BJD_TDB time stamps will likely
;                 not break the code, but can introduce errors in the
;                 reported times of more than a minute or cause
;                 internal inconsistencies if different data sets use
;                 different timestamps. The output table will display
;                 BJD_TDB but makes no attempt to convert or reconcile
;                 input times between data sets.
;
;                 See
;                 http://adsabs.harvard.edu/abs/2010PASP..122..935E 
;                 for an explanation of times
;
;                 NOTE 3: If DTPATH is omitted, Doppler Tomography is
;                 not included in the global fit
;
;   FLUXFILE   - An ASCII file with each line containing three white
;                space delimited columns: FILTER, MAG,
;                UNCERTAINTY. This file describes the apparent
;                broad-band magnitudes of the host star to fit the SED
;                and derive a distance, luminosity, and
;                extinction. Only certain FILTERS are allowed.  See
;                mag2fluxconv.pro for more info and citations. If not
;                specified, the distance and extinction are not fit
;                and the resultant constraint on the stellar
;                luminosity is not applied. 
;                NOTE: FLUXFILE must be specified for a parallax to
;                constrain the stellar luminosity/radius.
;
;                Galex: 'galNUV', 'galFUV' 
;                NOTE: the SED models are not great at UV, you may find it
;                better not to use Galex
;                WISE: 'WISE1','WISE2','WISE3','WISE4'
;                Sloan: 'uSDSS','gSDSS','rSDSS','iSDSS','zSDSS'
;                Panstarrs: 'zPS'
;                Johnson: 'U','B','V','R',
;                Cousins: 'RC', 'IC','J2M','H2M','K2M'
;                Tycho: 'BT','VT'
;                Kepler INT: 'U_KIS','gKIS','rKIS','iKIS'
;
;                The program mksed.pro will automatically generate
;                this file using queryVizier based on the object's
;                name or coordinates. Exercise caution that the
;                correct object was selected for each catalog.
; 
;                Thank you to Keivan Stassun at Vanderbilt for the
;                majority of the SED-related code.
;
;   PREFIX      - Each of the output files will have this string as a
;                 prefix. Default is 'planet.'
;
;   MAXSTEPS    - The maximum number of steps to take in the MCMC
;                 chain. Note that a 32-bit installation of IDL cannot
;                 allocate more than 260 million double-precision
;                 numbers, and redundant copies of each parameter are
;                 required. Even a 64-bit installation may require
;                 very slow disk swapping. A very large number for
;                 MAXSTEPS will cause memory management
;                 problems. Default is 100,000, and larger values are
;                 strongly discouraged. Increase NTHIN if the chains
;                 are not well-mixed. For complex fits with many
;                 parameters, users may wish to revise this downward.

;                 NOTE: If the MCMC chains run to MAXSTEPS,
;                 doubling this value will double the runtime. Short
;                 test runs (MAXSTEPS=100) are strongly encouraged
;                 before running week-long fits.
;   NTHIN       - If set, only every NTHINth element will be
;                 kept. Values as high as 1/acceptance rate typically
;                 don't degrade the resultant fit because there is a
;                 high correlation between adjacent steps and has the
;                 advantage of improved memory management and faster
;                 generation of the final plots. Default is 1.
;                 NOTE: Only kept links in the chain count toward
;                 MAXSTEPS, so if the MCMC chains run to MAXSTEPS,
;                 doubling this value will double the runtime.
;   RANDOMFUNC  - A string specifying the name of the random number
;                 generator to use. This generator must be able to
;                 return 1,2 or 3 dimensional uniform or normal random
;                 deviates. Default is 'EXOFAST_RANDOM' (which is slow
;                 but robust).
;   SEED        - The seed to the random number generator used for the
;                 MCMC fits. Be sure not to mix seeds from different
;                 generators. The default is -systime(/seconds).
;   NINTERP     - If set, the each model data point will be an average
;                 of NINTERP samples over a duration of EXPTIME
;                 centered on the input time.
;   EXPTIME     - If set, the each model data point will be an average
;                 of NINTERP samples over a duration of EXPTIME
;                 centered on the input time.
;                 For a dicussion on binning, see:
;                 http://adsabs.harvard.edu/abs/2010MNRAS.408.1758K
;   MAXGR       - The maximum Gelman Rubin statistic that is
;                 considered well-mixed (default=1.01)
;   MINTZ       - The minimum number of independent draws that is
;                 considered well-mixed (default=1000)
;   FITRV       - An NPLANETS boolean array that specifies which
;                 planets should be fit with an RV model. 
;                 If RVPATH is specified, default is bytarr(nplanets) + 1B.
;                 If RVPATH is not specified, default is bytarr(nplanets).
;                 At least one of FITRV and FITTRAN should be true for each planet
;   FITTRAN     - An NPLANETS boolean array that specifies which
;                 planets should be fit with a transit model. 
;                 If TRANPATH is specified, default is bytarr(nplanets) + 1B.
;                 If TRANPATH is not specified, default is bytarr(nplanets). 
;                 At least one of FITRV and FITTRAN should be true for each planet
;   CIRCULAR    - An NPLANETS boolean array that specifies which planets
;                 should be fixed to be circular (1) or left with
;                 eccentricity free (0). 
;                 Default is bytarr(nplanets) + 1B.
;   SECONDARY   - An NPLANETS boolean array that specifies which planets
;                 should have a secondary eclipse modeled. 
;                 Default is bytarr(nplanets)
;                 ***NOT YET IMPLEMENTED***
;   ROSSITER    - An NPLANETS boolean array that specifies which planets
;                 should fit the Rossiter-McLaughlin effect to the RV
;                 data using the Ohta approximation. If a run was
;                 dedicated to RM, it should be separated into its own
;                 file to fit a different zero point and jitter
;                 parameter to it.
;                 Default is bytarr(nplanets)
;                 ***NOT YET IMPLEMENTED***
;   FITDT       - An NPLANETS boolean array that specifies which planets
;                 should fit using a Doppler Tomography model.
;                 Default is bytarr(nplanets)
;                 ***NOT YET IMPLEMENTED***
;  FITTHERMAL- A string array specifying which bands to fit thermal
;             emission for. This is what you want to set to fit an
;             isolated secondary eclipse. All observations in this
;             band will be modeled with a baseline of 1 between t2 and
;             t3 of the secondary eclipse and 1 + thermal emission (in
;             PPM) out of eclipse.
;  FITREFLECT- A string array specifying which bands to fit reflected
;             light for. Set this along with thermal if you're
;             fitting a full phase curve. It will be modeled as a
;             sinusoid with the orbital period, a minimum at the
;             primary transit, and a fitted amplitude (in PPM).
;  FITDILUTE-   A string array specifying which bands to fit a dilution
;             term for. Set this if the star is blended with a
;             neighbor and you expect color-dependent depth
;             variations.
;             Note: May be degenerate with F0 (transit normalization) 
;             Note: this only affects the transit model. It is not
;             accounted for in the SED fitting.
;             TODO: automatically model dilution based on multiple
;             SEDs
;   CHEN        - An NPLANET boolean array that specifies which
;                 planets should have the Chen & Kipping, 2017
;                 mass-radius relation applied. By default CHEN =
;                 FITRV xor FITTRAN. That is, only apply the
;                 mass-radius prior when RV is not fit (to derive the
;                 planet mass) or when a transit is not fit (to derive
;                 the radius). If the defaults have been overridden
;                 and FITRV and CHEN are both false for a given
;                 planet, the RV semi-amplitude (planet mass) and all
;                 derived parameters will not be quoted. Multi-planet
;                 systems will be constrained not to cross orbits, but
;                 the Hill Sphere will be set to zero.  If FITTRAN and
;                 CHEN are both false for a given planet, the
;                 planetary radius and all derived parameters will not
;                 be quoted.
;
; OPTIONAL KEYWORDS:
;   FITSLOPE  - If set, it will fit a linear trend to the RV data.
;   FITQUAD   - If set, it will fit a quadratic trend to the RV data.
;   NOMIST    - If set, do not use the MIST evolutionary tracks 
;               see http://waps.cfa.harvard.edu/MIST/
;               And please cite
;               http://adsabs.harvard.edu/abs/2016ApJS..222....8D
;               http://adsabs.harvard.edu/abs/2016ApJ...823..102C
;               *** Use with caution, not thoroughly tested ***
;   YY        - If set, use the YY evolutionary tracks see
;               http://adsabs.harvard.edu/abs/2001ApJS..136..417Y
;               to constrain the mass/radius of the star. YY should
;               not be used for low-mass stars (~< 0.5 msun). This
;               should be accompanied by the NOMIST keyword (but is
;               not enforced).
;   TORRES    - If set, use the Torres relations to constrain the mass
;               and radius of the star. This may be useful to
;               investigate potential systematics and should be
;               accompanied by the NOMIST keyword (but is not
;               enforced). The Torres relations are not applicable for
;               low mass (< 0.6 msun) stars.
;   NOCLARET  - If set, ignore the Claret & Bloeman limb darkening
;               tables and just fit the limb darkening. This should be
;               specified for low-mass stars where these tables are
;               unreliable.
;   LONGCADENCE - If set, EXPTIME=29.425 and NINTERP=10 are set to handle
;               long cadence data from Kepler. This overwrites
;               NINTERP and EXPTIME inputs.
;   TIDES     - If set, when (1-Rstar/a-rp/a) < e < (1-3*Rstar/a), we
;               set the eccentricity to zero, presuming that the tidal
;               circularization timescale is much much smaller than
;               the age of the system.
;   EPRIOR4   - Parameterize the eccentricity and argument of
;               periastron as e^(1/4)*sin(omega) and
;               e^(1/4)*cos(omega) to more closely match the observed
;               eccentricity distribution
;   TTVS      - If set, non-periodic transit times are allowed. The
;               period is constrained by a linear fit to all transit
;               times at each step. Otherwise, a linear ephemeris is
;               assumed.
;   TDELTAVS  - If set, a new transit depth is fit for each
;               transit. Otherwise, all transits of the same planet
;               are modeled with the same same depth.
;   TIVS      - If set, a new inclination is fit for each
;               transit. Otherwise, all transits of the same planet
;               are modeled with the same same depth.
;   BESTONLY  - If set, only the best fit (using AMOEBA) will be
;               performed.
;               ***NOT YET IMPLEMENTED***
;   PLOTONLY  - If set, only a plot of the initial guesses over the
;               data is made. This is useful when refining initial
;               guesses.
;               ***NOT YET IMPLEMENTED***
;   REFINESTAR- If set, refining the stellar parameters first, before
;               the global fit.
;   EARTH     - If set, the output units of Mp and Rp are in Earth
;               units, not Jupiter units.
;   DEBUG     - If set, various debugging outputs will be printed and
;               plotted. If the fit is failing, this is your first
;               step to figuring out what's going
;               wrong. Usually a parameter starts too far from its
;               correct value to find or some parameter is not
;               constrained.
;   STARDEBUG - Same as DEBUG, but applied to the stellar parameter
;               refinement at the beginning of the fit.
;
; OUTPUTS:
;
;   Each of the output files will be preceeded by PREFIX (defined
;   above).
;
;   mcmc.idl   - An IDL save file that contains the stellar structure
;                with the full chains for each parameter, including
;                derived parameters, the chi2 at each link, and the
;                index of the burn-in period, called MCMCSS (MCMC
;                stellar structure).
;   chain.ps   - A postscript plot of each parameter as a function of
;                chain link, 8 to a page. Each color is a separate
;                chain.
;   pdf.ps     - A postscript plot of each posterior distribution
;                function, 8 to a page. Each color is a separate
;                chain. The thick black line is the average of all
;                chains.
;   covar.ps   - A postscript plot of the covariances between each
;                fitted parameter in a corner plot.
;   median.tex - The LaTeX source code for a deluxe table of the
;                median values and 68% confidence interval, rounded to
;                two sig figs in the uncertainty.
;   median.csv - A machine readable table of the median values and 68%
;                confidence interval, rounded to two sig figs in the
;                uncertainty.
;   log        - A file containing everything printed to screen during
;                the fit for later review.
;   
;   Each of the following outputs are created at 3 distinct phases in
;   the fit. 
;
;   1) Files preceeded with "start." are the starting values of the
;   fit. Often times it is necessary to tweak these by hand until the
;   starting values are a pretty good match to the data.
;
;   2) Files preceeded with "amoeba." are the models after the amoeba
;   minimization is complete. If this model is not a good fit to the
;   data, the fit is likely to fail and you should refine your
;   starting values, priors, and constraints. At a minimum, the MCMC
;   is likely to take significantly longer to converge if this is not
;   a good fit.
;
;   3) Files preceeded with "mcmc." are the final plots meant for
;   publication. They represent the best fit among all links of all
;   chains.
;
;   transit.ps - A multi-page postscript plot of the transit
;                model. The first page has each transit (file) stacked
;                on the same plot, offset by a constant. Subsequent
;                pages are the detrended, phase-folded transits for
;                each planet. Note that the model on the phase folded
;                model may have some fuzz due to different limb
;                darkening for each model.  
;                *** Fairly cursory at the moment, and poorly behaved
;                for complex fits ***
;   rv.ps      - A multi-page postscript plot of the RV model. The
;                first page is the unphased model with gamma and any
;                fitted linear or quadratic terms subtracted from both
;                the data and model. If more than one instrument is
;                used, a legend is produced in the corner. Subsequent
;                pages are each planet, phased to its period, with all
;                other planets, gamma, and any fitted linear and
;                quadratic terms subtracted.
;   mist.eps   - A plot of the star with its MIST isochrone
;                overplotted. The black point is the best-fit value,
;                the red point is the corresponding model value. Only
;                generated if the /NOMIST keyword is not set.
;   yy.eps     - A plot of the star with its YY isochrone
;                overplotted. The black point is the best-fit value,
;                the red point is the corresponding model value. Only
;                generated if the /YY keyword is not set.
;   sed.eps    - A plot of the broadband photometry and best fit
;                SED. Only generated if FLUXFILE is given.
; 
;  We recognize that in many cases, the outputs plots are not
;  publication quality. The following text outputs are intended to
;  allow the user to generate their own, more complicated or
;  customized plots without having to recreate the model or
;  detrending.
;
;  residuals.telescope_[i].txt --
;      A text file containing the residuals to the best-fit model RV
;      for the ith telescope.
;   model.telescope_[i].txt --
;      A text file containing the best-fit model (with gamma, slope,
;      and quad subtracted) RVs for each time given for telescope.
;      One for each telescope is generated.
;   model.transit_[i].txt - 
;      The model of the ith transit at each input data point,
;      including detrending.
;   residuals.transit_[i].txt -- 
;      The residuals of the ith transit file at each data point.
;   detrendedmodel.transit_[i].planet_[j].txt -- 
;      The detrended model of the ith transit of the jth planet minus
;      1 at each input data point. Sum all transit[i].planet_*.txt and add
;      one for the combined model. Useful for separating overlapping
;      transits.
;   prettymodel.transit_[i].planet_[j].txt -- 
;      Same as detrendedmodel.transit_[i].planet_[j].txt, but sampled
;      every minute from the first to the last data point. This is
;      intended to make a pretty model plot if there are gaps in the
;      data.
;
;   NOTE 1: The detrended data can by derived by adding the residuals
;      to the detrended model

;   NOTE 2: To extract a single page out of a multi-page PS file, use:
;
;         psselect -p# input.ps output.ps 
;
;      where # is the page number to extract.
;
; COMMON BLOCKS:
;   CHI2_BLOCK:
;     SS      - A structure that describes the entire stellar system
;
; EXAMPLES:  
;   ;; fit EPXXXXXXX, a 4 planet system with only K2 data
;   exofastv2, nplanets=4, tranpath='ep?????????.Kepler.K2.dat3',fluxfile='ep?????????.flux.txt',$
;           priorfile='ep?????????.priors',debug=debug, prefix='epXXXXXXXXX.eeee.nopilogg.',$
;           fittran=[1,1,1,1],fitrv=[0,0,0,0],circular=[0,0,0,0],/longcadence, /earth
;
; MODIFICATION HISTORY
; 
;  2017/01 -- Complete rewrite of exofast.pro. More general (fits
;             multiple planets, mulitple bands, multiple instrumental
;             offsets). Now easily extensible.
;-
pro exofastv2, priorfile=priorfile, $
               rvpath=rvpath, tranpath=tranpath, dtpath=dtpath, fluxfile=fluxfile,$
               prefix=prefix,$
               circular=circular,fitslope=fitslope, secondary=secondary, $
               rossiter=rossiter,chen=chen,$
               fitthermal=fitthermal, fitreflect=fitreflect, fitdilute=fitdilute,$
               nthin=nthin, maxsteps=maxsteps, dontstop=dontstop, $
               debug=debug, stardebug=stardebug, verbose=verbose, randomfunc=randomfunc, seed=seed,$
               bestonly=bestonly, plotonly=plotonly,refinestar=refinestar,$
               longcadence=longcadence, exptime=exptime, ninterp=ninterp, $
               maxgr=maxgr, mintz=mintz, $
               yy=yy, torres=torres, nomist=nomist, noclaret=noclaret, tides=tides, nplanets=nplanets, $
               fitrv=fitrv, fittran=fittran, fitdt=fitdt,$
               ttvs=ttvs, tivs=tivs, tdeltavs=tdeltavs,$
               earth=earth, i180=i180, nocovar=nocovar, alloworbitcrossing=alloworbitcrossing, stretch=stretch

;; this is required for virtual machines
par = command_line_args(count=numargs)
if numargs eq 1 then begin
   argfile = par[0]
   if file_exist(argfile) then begin
      readargs, argfile, priorfile=priorfile, $
                rvpath=rvpath, tranpath=tranpath, dtpath=dtpath, fluxfile=fluxfile,$
                prefix=prefix,$
                circular=circular,fitslope=fitslope, secondary=secondary, $
                rossiter=rossiter,chen=chen,$
                fitthermal=fitthermal, fitreflect=fitreflect, fitdilute=fitdilute,$
                nthin=nthin, maxsteps=maxsteps, dontstop=dontstop, $
                debug=debug, stardebug=stardebug, verbose=verbose, randomfunc=randomfunc, seed=seed,$
                bestonly=bestonly, plotonly=plotonly, refinestar=refinestar, $
                longcadence=longcadence, exptime=exptime, ninterp=ninterp, $
                maxgr=maxgr, mintz=mintz, $
                yy=yy, torres=torres, nomist=nomist, noclaret=noclaret, tides=tides, nplanets=nplanets, $
                fitrv=fitrv, fittran=fittran, fitdt=fitdt,$
                ttvs=ttvs, tivs=tivs, tdeltavs=tdeltavs,$
                earth=earth, i180=i180, nocovar=nocovar, alloworbitcrossing=alloworbitcrossing, stretch=stretch
   endif
endif

;; this is the stellar system structure
COMMON chi2_block, ss

;; name of the chi square function
chi2func = 'exofast_chi2v2'

;; compile all routines now to keep output legible 
;; resolve_all doesn't interpret execute; it's also broken prior to IDL v6.4(?)
if double(!version.release) ge 6.4d0 and ~lmgr(/vm) then $
   resolve_all, resolve_function=[chi2func,'exofast_random'],/cont,/quiet

;; default prefix for all output files (filename without extension)
if n_elements(prefix) eq 0 then prefix = 'planet.'
basename = file_basename(prefix)

;; if the directory doesn't exist, make it
dirname = file_dirname(prefix)
if dirname ne '.' then begin
   if ~file_test(dirname,/directory) then begin
      file_mkdir, dirname
   endif
endif

;; output to log file too
logname = prefix + 'log'
file_delete, logname, /allow_nonexistent

;; refine the stellar starting values based on the priors and SED (if supplied)
;; this can be really useful if you don't know the rough stellar
;; parameters, especially for the MIST models, but is a waste of time if you do
if nplanets ne 0 and keyword_set(refinestar) then begin
   printandlog, 'Refining stellar parameters'
   ss = mkss(fluxfile=fluxfile,nplanet=0,priorfile=priorfile, $
             yy=yy, torres=torres, nomist=nomist, logname=logname, debug=stardebug, verbose=verbose)
   pars = str2pars(ss,scale=scale,name=starparnames, angular=angular)
   staronlybest = exofast_amoeba(1d-5,function_name=chi2func,p0=pars,scale=scale,nmax=nmax)
   if staronlybest[0] eq -1 then message, 'best fit for stellar parameters failed'
endif

;; create the master structure
ss = mkss(rvpath=rvpath, tranpath=tranpath, dtpath=dtpath, fluxfile=fluxfile, nplanets=nplanets, $
          debug=debug, verbose=verbose, priorfile=priorfile, fitrv=fitrv, fittran=fittran, fitdt=fitdt,$
          circular=circular,fitslope=fitslope, fitquad=fitquad,tides=tides,$
          ttvs=ttvs, tivs=tivs, tdeltavs=tdeltavs,$
          rossiter=rossiter,longcadence=longcadence, ninterp=ninterp, exptime=exptime, earth=earth, i180=i180,$
          fitthermal=fitthermal, fitreflect=fitreflect, fitdilute=fitdilute,$
          chen=chen, yy=yy, torres=torres, nomist=nomist, noclaret=noclaret, alloworbitcrossing=alloworbitcrossing, logname=logname)

npars = 0L
nfit = 0L
for i=0L, n_tags(ss)-1 do begin
   for j=0L, n_elements(ss.(i))-1 do begin
      for k=0L, n_tags(ss.(i)[j])-1 do begin
         if n_tags(ss.(i)[j].(k)) ne 0 then begin
            if tag_exist(ss.(i)[j].(k),'fit') then begin
               npars += 1L
               if ss.(i)[j].(k).fit then nfit += 1L
            endif
         endif
      endfor
   endfor
endfor

if n_elements(mintz) eq 0 then mintz = 1000d0
if n_elements(maxgr) eq 0 then maxgr = 1.01d0
if n_elements(maxsteps) eq 0 then maxsteps = 100000L
if n_elements(nthin) eq 0 then nthin = 1L
if n_elements(sigclip) ne 1 then sigclip = !values.d_infinity ;; no clipping
if n_elements(nmin) eq 0 then nmin=5
;; use robust (slower) random number generator by default
if n_elements(randomfunc) eq 0 then randomfunc = 'exofast_random'

memrequired = double(ss.nchains)*double(maxsteps)*npars*8d0/(1024d0^3)
printandlog, 'Fit will require ' + strtrim(memrequired,2) + ' GB of RAM for the final structure', logname
if memrequired gt 2d0 then begin
   printandlog, 'WARNING: this likely exceeds your available RAM and may crash after the end of a very long run. You likely want to reduce MAXSTEPS and increase NTHIN by the same factor. If you would like to proceed anyway, type ".con" to continue', logname
   if ~lmgr(/vm) then stop
endif
printandlog, '', logname

pars = str2pars(ss,scale=scale,name=name, angular=angular)

;; replace the stellar parameters with their independently-optimized values
if keyword_set(refinestar) then begin
   for i=0, n_elements(starparnames)-1 do begin
      match = (where(name eq starparnames[i]))[0]
      if match ne -1 then pars[match] = staronlybest[i]
   endfor
   pars2str, pars, ss
endif

;; plot the data + starting guess
modelfile = prefix + 'start'
bestchi2 = call_function(chi2func, pars, psname=modelfile)
if ~finite(bestchi2) then begin
   printandlog, 'Starting conditions outside of bounds. Setting the /VERBOSE and /DEBUG flags may help you revise the starting values', logname
   return
endif

if keyword_set(display) then spawn, 'gv ' + modelfile + ' &'
if keyword_set(plotonly) then return

;; do it again for accurate timing 
;; after loading all the files into cache, not including plotting
t0 = systime(/seconds)
bestchi2 = call_function(chi2func, pars)
modeltime = systime(/seconds)-t0

;; these are the starting values for all step parameters
printandlog, 'These are the starting values for all the step parameters', logname
printandlog, 'and the amoeba stepping scale, which is roughly the range', logname
printandlog, 'of parameter space it will explore around the starting value', logname
printandlog, 'and is equal to 3x any input priors. When priors are not ', logname
printandlog, 'specified in ' + priorfile + ', a default guess is used.', logname
printandlog, 'The parameter number is useful for tracking down unconstrained parameters', logname
printandlog,'',logname 
printandlog, '**************************************************************', logname
printandlog, '*** ESPECIALLY DURING BETA TESTING, YOU SHOULD MAKE SURE   ***', logname
printandlog, '*** THESE MAKE SENSE AND AGREE WITH YOUR EXPECTATION FROM  ***', logname
printandlog, '*** PRIORFILE. IF NOT, YOUR STARTING PRIORS MAY NOT BE     ***', logname
printandlog, '*** TRANSLATED CORRECTLY INTO THE STEPPING                 ***', logname
printandlog, '*** PARAMETERIZATION BY pars2step.pro. NOT ALL PARAMETER   ***', logname
printandlog, '*** COMBINATIONS ARE ALLOWED/SUPPORTED.                    ***', logname
printandlog, '**************************************************************', logname
printandlog, '', logname
printandlog, 'Par #      Par Name    Par Value       Amoeba Scale', logname
for i=0, n_elements(name)-1 do printandlog, string(i, name[i], pars[i], scale[i], format='(i3,x,a15,x,f14.6,x,f14.6)'), logname
printandlog, '', logname

if ss.debug and ~lmgr(/vm) then begin
   printandlog, 'program halted to give you time to inspect the priors. Type ".con" to continue', logname
   stop
end

nmax = 1d5
printandlog, 'It takes ' + strtrim(modeltime,2) + ' seconds to calculate a single model'
printandlog, 'Beginning AMOEBA fit; this may take up to ' + string(modeltime*nmax/60d0,format='(f0.1)') + ' minutes if it takes the maximum allowed steps (' + strtrim(nmax,2) + ')', logname

;; do the AMOEBA fit
ss.amoeba = 1B
best = exofast_amoeba(1d-5,function_name=chi2func,p0=pars,scale=scale,nmax=nmax)
if best[0] eq -1 then begin
   printandlog, 'ERROR: Could not find best combined fit; adjust your starting values and try again. You may want to set the /DEBUG keyword.', logname
   return
endif
printandlog, 'Finished AMOEBA fit', logname
save, best, filename=prefix + 'amoeba.idl'

;; update the parameter array with the chen-derived logks/rp (is this necessary?)
;best = str2pars(ss,scale=scale,name=name) 

;; try again?
;printandlog, 'restarting AMOEBA with chen enabled', logname
;printandlog, call_function(chi2func,best,modelrv=modelrv,modelflux=modelflux, psname=prefix + 'model'), logname
;best = exofast_amoeba(1d-8,function_name=chi2func,p0=best,scale=scale,nmax=nmax)
;printandlog, call_function(chi2func,best,modelrv=modelrv,modelflux=modelflux, psname=prefix + 'model'), logname

;; output the best-fit model fluxes/rvs
bestchi2 = call_function(chi2func,best,modelrv=modelrv,modelflux=modelflux, psname=prefix + 'amoeba')

;; do the MCMC fit
if not keyword_set(bestonly) then begin
   exofast_demc, best, chi2func, pars, chi2=chi2,$
                 nthin=nthin,maxsteps=maxsteps, dontstop=dontstop, $
                 burnndx=burnndx, seed=seed, randomfunc=randomfunc, $
                 gelmanrubin=gelmanrubin, tz=tz, maxgr=maxgr, mintz=mintz, $
                 stretch=stretch, logname=logname, angular=angular
   if pars[0] eq -1 then begin
      printandlog, 'MCMC Failed to find a stepping scale. This usually means one or more parameters are unconstrained by the data or priors.', logname
   endif

   bad = where(tz lt mintz or gelmanrubin gt maxgr,nbad)
   if bad[0] ne -1 then begin
      printandlog, 'WARNING: The Gelman-Rubin statistic indicates ' + $
                   'the following parameters are not well-mixed', logname
      printandlog, '    Parameter   Rz     Tz', logname
      for i=0, nbad-1 do printandlog, string(name[bad[i]], gelmanrubin[bad[i]],tz[bad[i]], format='(a13,x,2(f0.4,x))'), logname
   endif
   printandlog, 'Synthesizing results; for long chains and/or many fitted parameters, this may take up to 15 minutes', logname

   ;; combine all chains
   sz = size(pars)
   npars = sz[1]
   nsteps = sz[2]
   nchains = sz[3]
   pars = reform(pars,npars,nsteps*nchains)
   chi2 = reform(chi2,nsteps*nchains)
   minchi2 = min(chi2,bestndx)
endif else begin
   pars = reform(best[tofit],n_elements(tofit),1)
   bestndx = 0
endelse

;; generate the model fit from the best MCMC values, not AMOEBA
bestamoeba = best
best = pars[*,bestndx]
modelfile = prefix + 'mcmc'
bestchi2 = call_function(chi2func,best,psname=modelfile, $
                         modelrv=modelrv, modelflux=modelflux)

;; make a new stellar system structure with only fitted and derived
;; parameters, populated by the pars array
;mcmcss = mcmc2str(pars, ss)
mcmcss = mkss(rvpath=rvpath, tranpath=tranpath, dtpath=dtpath, fluxfile=fluxfile, nplanets=nplanets, $
              debug=debug, verbose=verbose, priorfile=priorfile, fitrv=fitrv, fittran=fittran, fitdt=fitdt,$
              circular=circular,fitslope=fitslope, fitquad=fitquad,tides=tides, $
              ttvs=ttvs, tivs=tivs, tdeltavs=tdeltavs,$
              rossiter=rossiter,longcadence=longcadence, ninterp=ninterp, exptime=exptime, earth=earth, i180=i180,$
              fitthermal=fitthermal, fitreflect=fitreflect, fitdilute=fitdilute,$
              chen=chen,nvalues=nsteps*nchains,/silent,yy=yy,torres=torres,nomist=nomist,noclaret=noclaret,$
              alloworbitcrossing=alloworbitcrossing, logname=logname, best=best)
mcmcss.nchains = nchains
mcmcss.burnndx = burnndx
*(mcmcss.chi2) = chi2

pars2str, pars, mcmcss

;; derive all parameters
derivepars, mcmcss

;; save the chains for additional analysis
idlfile = prefix + 'mcmc.idl'
save, mcmcss, filename=idlfile

;; output filenames
label = "tab:" + basename
caption = "Median values and 68\% confidence interval for " + basename
parfile = prefix + 'pdf.ps'
covarfile = prefix + 'covar.ps'
chainfile = prefix + 'chain.ps'
texfile = prefix + 'median.tex'
csvfile = prefix + 'median.csv'

exofast_plotdist_corner, mcmcss, pdfname=parfile, covarname=covarfile,nocovar=nocovar,logname=logname, angular=angular,csvfile=csvfile
exofast_latextab2, mcmcss, caption=caption, label=label,texfile=texfile
exofast_plotchains, mcmcss, chainfile=chainfile, logname=logname

;; display all the plots, if desired
if keyword_set(display) then begin
   spawn, 'gv ' + parfile + ' &'
   spawn, 'gv ' + covarfile + ' &'
   spawn, 'gv ' + modelfile + ' &'
endif

end
