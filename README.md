# quadBlastSim

[![DOI](https://img.shields.io/badge/DOI-10.3390%2Faerospace13070646-blue)](https://doi.org/10.3390/aerospace13070646)
[![Paper](https://img.shields.io/badge/Aerospace-Open%20Access-green)](https://www.mdpi.com/2226-4310/13/7/646)
[![MATLAB](https://img.shields.io/badge/MATLAB-Simulink-orange)](https://www.mathworks.com/)

Fast estimation of the **diffractive loads** acting on a quadrotor UAV in the moments after a nearby explosion.

Rather than running a full CFD or FEA solve for every blast scenario, this code approximates the vehicle as a set of spheres connected by rods (one sphere per motor, one for the central body) and numerically integrates a *convected* blast pressure field over that geometry. A 90 ms rigid-body simulation of a representative quadrotor perturbed from hover runs in roughly a second, which makes parameter sweeps and control-design studies practical.

This repository contains all the code and data needed to reproduce the figures in the paper below. Folder numbers correspond to the figure numbers they generate.

---

## Paper

**Fast Estimation of the Diffractive Loads on a Quadrotor UAV Following an Explosive Blast**
Nicholas P. Kakavitsas, Andrew Willis, Dipankar Maity, and Artur Wolek
*Aerospace* **2026**, *13*(7), 646 · Special Issue: *Flight Dynamics, Control & Simulation (3rd Edition)*
University of North Carolina at Charlotte

**[Read the paper (open access)](https://www.mdpi.com/2226-4310/13/7/646)** · 🔗 **[DOI: 10.3390/aerospace13070646](https://doi.org/10.3390/aerospace13070646)** · ⬇️ **[PDF](https://www.mdpi.com/2226-4310/13/7/646/pdf)**

This article is a revised and expanded version of an earlier conference paper, adding a broader set of simulation results and more rigorous model validation against CFD.

### What the method does

1. **Convected wave assumption** — extends the single-distance Friedlander overpressure model (with Sadovskiy parameters) and Dewey's blast-induced wind model into a spatiotemporal field valid over the extent of the vehicle, including a modification that forces the wind profile to decay to zero rather than grow without bound.
2. **Fast diffractive load estimation** — exploits the symmetry of a sphere to reduce the surface pressure integral to a 1-D quadrature, then superposes the contributions of the five spheres to get net force and moment on the airframe.
3. **CFD validation** — blastFoam simulations of a 10 kg TNT charge are used to show the convected field can be tuned to match higher-fidelity data.
4. **Flight simulation** — the loads are integrated with quadrotor rigid-body dynamics in Simulink under quadratic drag and constant hover thrust to predict the terminal state after the blast passes.

---

## Repository layout

| Folder | Figures | Contents |
|---|---|---|
| `00_subroutines/` | — | Shared model functions (Friedlander/Sadovskiy overpressure, modified Dewey wind, convected field, sphere load integration). Everything else depends on this. |
| `01_velocity_model/` | Fig. 1 | Parametric fits to Dewey's blast wind parameters; wind Mach number time history at a fixed point. |
| `02_pressure_force_spheres/` | Fig. 2 | Friedlander overpressure, resulting axial force on a single sphere, and the evolving surface pressure distribution. |
| `03_planar_vs_radial/` | Fig. 3 | Planar vs. spherical spreading comparison; sagitta-based validity bound on the planar wave assumption. |
| `04_ritzel_comparison/` | Fig. 4 | Model fits against digitized experimental data from the literature. |
| `06-07_blastfoam/` | Figs. 6–7 | blastFoam case setup and post-processing: mesh convergence study and overpressure/velocity field evolution. |
| `08-09_cfd_analysis/` | Figs. 8–9 | Empirical models (propagated and non-propagated) vs. best-fit vs. CFD data; propagation speed fit. |
| `10_simulink_model/` | Fig. 10 | The Simulink blast-response model. |
| `11-13_param_sweep_grid/` | Figs. 11–13 | Sweeps over standoff distance and blast angle: terminal states, peak loads and impulses, transient state histories. |
| `14_sensitivity_study/` | Fig. 14 | Sensitivity of terminal states to drag coefficient and air density. |

> Figure 5 (the multi-link quadrotor schematic) is an illustration and has no associated code, hence the gap in the numbering.

---

## Requirements

- **MATLAB** R2024a or newer, with:
  - Simulink
  - Curve Fitting Toolbox (`fit`, `lsqcurvefit`)
  - Optimization Toolbox (`fmincon`)
- **blastFoam v6.0** on OpenFOAM — only needed if you want to re-run the CFD validation from scratch. The analysis scripts in `08-09_cfd_analysis/` work from exported data.

## Getting started

```bash
git clone https://github.com/robotics-uncc/quadBlastSim.git
cd quadBlastSim
```

In MATLAB, add the shared subroutines to your path, then run any figure folder's top-level script:

```matlab
addpath(genpath('00_subroutines'))
cd 03_planar_vs_radial
% run the script in this folder
```

Each folder is self-contained apart from `00_subroutines`, so figures can be regenerated in any order.

### Reproducing the CFD validation

The blastFoam case modifies the 2-D Kingery–Bulmash axisymmetric wedge validation case shipped with blastFoam, simulating 10 kg of TNT at the origin. Changes from the stock case:

- domain radius extended from 16 m to 100 m
- base mesh refined from 25 to 200 cells per axis (~0.5 m base cell)
- end time extended from 0.025 s to 0.1 s
- adaptive mesh refinement (`adaptiveFvMesh`) level 3, giving a 0.0625 m minimum cell

The level-3 AMR run took roughly 24 h of wall-clock time on 32 cores of an AMD Ryzen Threadripper 3990X with 256 GB RAM.

> **Note on raw CFD data:** the full blastFoam output is too large to host here. The repository includes the extracted data needed for the figures. If you need the raw fields, please open an issue or contact the corresponding author.

---

## Citation

If you use this code, please cite the paper:

```bibtex
@article{kakavitsas2026blast,
  author  = {Kakavitsas, Nicholas P. and Willis, Andrew and Maity, Dipankar and Wolek, Artur},
  title   = {Fast Estimation of the Diffractive Loads on a Quadrotor {UAV} Following an Explosive Blast},
  journal = {Aerospace},
  volume  = {13},
  number  = {7},
  pages   = {646},
  year    = {2026},
  doi     = {10.3390/aerospace13070646},
  url     = {https://www.mdpi.com/2226-4310/13/7/646}
}
```

---

## License

The paper is published open access under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). <!-- TODO: add a LICENSE file for the code and state the license here (MIT and BSD-3-Clause are common choices for research code). -->

## Contact

Nicholas P. Kakavitsas — [ORCID 0000-0003-3658-1831](https://orcid.org/0000-0003-3658-1831)
Artur Wolek — [ORCID 0000-0003-4934-5184](https://orcid.org/0000-0003-4934-5184)
Department of Mechanical Engineering and Engineering Science, UNC Charlotte

Questions about the code are best raised as a [GitHub issue](https://github.com/robotics-uncc/quadBlastSim/issues).
