# Simple-Galaxy-Simulation
A Basic simulation of galaxy using Newton Gravity law using CUDA Cpp for massive parallel computing, Unfortunatly, I did not have a powerfull GPU, so if you have a nice one, increase particles number..

# abstract
Yes Newton gravity law (prgramming skill issue)... I'm currently working on a simulation of accretion disk around Kerr Black Holes but, it's a massively more significant kind of programming and a very complex task because of the abstract mathematics used in the Einstein Theory. And no comments about the GRMHD code that I need to write ALONE based on realistic models (like Novikov-Thornes).. 
From :
```math
F = G \frac{m_1 m_2}{r^2}
```
to (maybe) :

```math
T_k^i=A(\eta^i+{u^\phi\over u^t}\xi^i)u_k(p+\varepsilon)+\delta^i_kp\\
```

```math
   {1\over r}(\int_{-h}^{h}\rho dz) ({r \over \Delta^{{1/2}}}u^r)(r^2-2Mr+a^2)^{1/2}{dL\over dr}-{1\over r}{d\over dr}(r\int^{+h}_{-h}t^r_\phi dz)+2FL=0
```
understand who can lol...

# Compilation

nvcc gravity.cu -o Galaxy_simulation -lSDL2

