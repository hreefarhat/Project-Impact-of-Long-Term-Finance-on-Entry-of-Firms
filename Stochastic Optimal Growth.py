# -*- coding: utf-8 -*-
"""
Created on Mon Mar 23 20:19:09 2020

@author: hreef
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
from scipy.optimize import minimize_scalar


###########################################################################
########################## SCALAR MAXIMIZATION ############################
###########################################################################


#Using Bounded Method
def maximize(func1, a, b, args):

    objective = lambda x: -func1(x, *args)
    res = minimize_scalar(objective, bounds=(a, b), method='bounded')
    maximizer, maximum = res.x, -res.fun
    return maximizer, maximum


# We can use numerical values for bounds
    objective = lambda x: -func1(x, *args)
    res = minimize_scalar(objective, bounds=(-3, 1), method='bounded')
    maximizer, maximum = res.x, -res.fun
    return maximizer, maximum   

#Using Brent Method 
#An example with a common choice of utility function
# u(c)=(c^(1-γ) - 1) /(1−γ)
γ = 1.5   # Preference parameter

def f(c):
    return (c**(1 - γ) - 1) / (1 - γ)
    res = minimize_scalar(f)
    res.c

################################################################
######################### OPTIMAL GROWTH MODEL #################
################################################################

class OptimalGrowthModel:

    def __init__(self,
                 α=0.4,
                 β=0.96,
                 μ=0,
                 s=0.1,
                 γ=1.5,
                 grid_max=4,
                 grid_size=120,
                 shock_size=250,
                 seed=1234):

        self.α, self.β, self.γ, self.μ, self.s = α, β, γ, μ, s

        # Set up grid
        self.grid = np.linspace(1e-5, grid_max, grid_size)

        # Store shocks (with a seed, so results are reproducible)
        np.random.seed(seed)
        self.shocks = np.exp(μ + s * np.random.randn(shock_size))

    def f(self, k):
        return k**self.α

    def u(self, c):
        return (c**(1 - self.γ) - 1) / (1 - self.γ)

    def objective(self, c, y, v_array):
        """
        Right hand side of the Bellman equation.
        """

        u, f, β, shocks = self.u, self.f, self.β, self.shocks

        v = lambda x: interp1d(self.grid, v_array, x)

        return u(c) + β * np.mean(v(f(y - c) * shocks))
    
###################################################################
################## THE BELLMAN OPERATOR ##########################
##################################################################

def T(og, v):
    """
    The Bellman operator.

      * og is an instance of OptimalGrowthModel
      * v is an array representing a guess of the value function
    """
    v_new = np.empty_like(v)

    for i in range(len(og.grid)):
        y = og.grid[i]

        # Maximize RHS of Bellman equation at state y
        v_max = maximize(og.objective, 1e-10, y, args=(y, v))[1]
        v_new[i] = v_max

    return v_new

def get_greedy(og, v):
    """
    Compute a v-greedy policy.

      * og is an instance of OptimalGrowthModel
      * v is an array representing a guess of the value function
    """
    v_greedy = np.empty_like(v)

    for i in range(len(og.grid)):
        y = og.grid[i]

        # Find maximizer of RHS of Bellman equation at state y
        c_star = maximize(og.objective, 1e-10, y, args=(y, v))[0]
        v_greedy[i] = c_star

    return v_greedy
    ########################################
    """
    Here's a function that iterates from a starting guess of the value function until the difference 
    between successive iterates is below a particular tolerance level.  
    """"" 
def solve_model(og,
                tol=1e-4,
                max_iter=1000,
                verbose=True,
                print_skip=25):

    # Set up loop
    v = np.log(og.grid)  # Initial condition
    i = 0
    error = tol + 1

    while i < max_iter and error > tol:
        v_new = T(og, v)
        error = np.max(np.abs(v - v_new))
        i += 1
        if verbose and i % print_skip == 0:
            print(f"Error at iteration {i} is {error}.")
        v = v_new

    if i == max_iter:
        print("Failed to converge!")

    if verbose and i < max_iter:
        print(f"\nConverged in {i} iterations.")

    return v_new

og = OptimalGrowthModel()

v_greedy = get_greedy(og, v_solution)

fig, ax = plt.subplots()

ax.plot(og.grid, v_greedy, lw=2,
        alpha=0.6, label='Approximate value function')

ax.legend(loc='lower right')
plt.show()



    
#USING LINEAR INTERPOLATION FOR BELLMAN EQUATION


""" 
An Example To Test Out The Bell Man Operator 
• 𝑓(𝑘) = 𝑘𝛼
• 𝑢(𝑐) = ln 𝑐
• 𝜙 is the distribution of exp(𝜇 + 𝜎𝜁) when 𝜁 is standard normal
V(y) = log(1 - α * β) / (1 - β) + (μ + α * np.log(α * β)) / (1 - α) + 1 / (1 - β) + 1 / (1 - α * β)

"""
def v_star(y, α, β, μ):
    """
    True value function
    """
    c1 = np.log(1 - α * β) / (1 - β)
    c2 = (μ + α * np.log(α * β)) / (1 - α)
    c3 = 1 / (1 - β)
    c4 = 1 / (1 - α * β)
    return c1 + c2 * (c3 - c4) + c4 * np.log(y)

def σ_star(y, α, β):
    """
    True optimal policy
    """
    return (1 - α * β) * y
α = 0.4
def fcd(k):
    return k**α

og = OptimalGrowthModel(u=np.log, f=fcd)

v_init = v_star(og.grid, α, og.β, og.μ)    # Start at the solution
v_greedy, v = T(og, v_init)             # Apply T once

fig, ax = plt.subplots()
ax.set_ylim(-35, -24)
ax.plot(og.grid, v, lw=2, alpha=0.6, label='$Tv^*$')
ax.plot(og.grid, v_init, lw=2, alpha=0.6, label='$v^*$')
ax.legend()
plt.show()







    