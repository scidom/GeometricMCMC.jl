## Run RMHMC using a Bayesian logit model with a Normal prior N(0, priorVar*I)
## on the Swiss banknote data

using Distributions, GeometricMCMC

include("swiss.jl")
include("logitNormalPrior.jl")

# Create Model instance
model = Model(nPars, data, logPrior, logLikelihood, gradLogPosterior,
  tensor, derivTensor, randPrior);

# Create setDriftStep function for adjusting the leap step of RMHMC
leapSteps = [0.9, 0.01, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]

setLeapStep(i::Int, acceptanceRatio::Float64, nMcmc::Int, 
  nBurnin::Int, currentStep::Float64) =
  setRmhmcLeapStep(i, acceptanceRatio, nMcmc, nBurnin, currentStep, leapSteps)

# Create instance malaOpts of RMHMC options
rmhmcOpts = RmhmcOpts(55000, 5000, 6, setLeapStep, 4);

# Run RMHMC
mcmc = Array(Float64, nPars, nPars)
z = Array(Float64, nPars, nPars)
linearZvMcmc = Array(Float64, nPars, nPars)
linearCoef = Array(Float64, nPars, nPars)
quadraticZvMcmc = Array(Float64, nPars, nPars)
quadraticCoef = Array(Float64, convert(Int, nPars*(nPars+3)/2), nPars)

try
  mcmc, z = rmhmc(model, rmhmcOpts);
  
  # Compute ZV-RMHMC mean estimators based on linear polynomial
  linearZvMcmc, linearCoef = linearZv(mcmc, z);

  # Compute ZV-RMHMC mean estimators based on quadratic polynomial
  quadraticZvMcmc, quadraticCoef = quadraticZv(mcmc, z);
catch msg
  println(msg)
end
