function mh(model::Model, opts::MhOpts)
  mcmc = Array(Float64, opts.mcmc.nPostBurnin, model.nPars)
  z = Array(Float64, opts.mcmc.nPostBurnin, model.nPars)
  proposalSd = ones(model.nPars, 1)
  proposed = zeros(model.nPars, 1)
  accepted = zeros(model.nPars, 1)
  acceptanceRatio = Array(Float64, model.nPars, 1)

  println("Running burn-in iterations...")
  pars = model.randPrior()
  currentLogPosterior = model.logPosterior(pars)
  currentGradLogPosterior = model.gradLogPosterior(pars)

  for i = 1:opts.mcmc.n
    for j = 1:model.nPars
      proposed[j] = proposed[j]+1
          
      proposedParameters = copy(pars)
      proposedParameters[j] = proposedParameters[j]+randn()*proposalSd[j]
      proposedLogPosterior = model.logPosterior(proposedParameters)
      proposedGradLogPosterior = model.gradLogPosterior(proposedParameters)
   
      ratio = proposedLogPosterior-currentLogPosterior
  
      if ratio > 0 || (ratio > log(rand()))
        accepted[j] = accepted[j]+1
        
        pars = copy(proposedParameters)           
        currentLogPosterior = copy(proposedLogPosterior)
        currentGradLogPosterior = copy(proposedGradLogPosterior)
      end        
    end

    if i > opts.mcmc.nBurnin
      mcmc[i-opts.mcmc.nBurnin, :] = pars
      z[i-opts.mcmc.nBurnin, :] = -currentGradLogPosterior/2
    end
  
    if mod(i, opts.mcmc.monitorRate) == 0
      if i < opts.mcmc.nBurnin
        for j = 1:model.nPars
          acceptanceRatio[j] = accepted[j]/proposed[j]
            
          if acceptanceRatio[j] > 0.6
            proposalSd[j] = proposalSd[j]*(1+opts.widthCorrection)
          elseif acceptanceRatio[j] < 0.2
            proposalSd[j] = proposalSd[j]*(1-opts.widthCorrection)
          end        
        end
      end
    
      println("Iteration $i of $(opts.mcmc.n):")
      for j = 1:model.nPars
        println("  Parameter $j: ", round(100*accepted[j]/proposed[j], 2),
        "% acceptance ratio")
      end
      proposed = zeros(model.nPars, 1)
      accepted = zeros(model.nPars, 1)
    end

    if i == opts.mcmc.nBurnin
      println("Burn-in completed...\n\nRunning post burn-in MCMC...");
    end
  end

  output = cell(3)
  output[1] = mcmc
  output[2] = z
  
  return output
end
