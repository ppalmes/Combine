# System tests.
module TestSystem

using CombineML.Types
using CombineML.System
using CombineML.Transformers
importall CombineML.Util

include("fixture_learners.jl")
using .FixtureLearners
nfcp = NumericFeatureClassification()
fcp = FeatureClassification()

function all_concrete_subtypes(a_type::Type)
  a_subtypes = Type[]
  for a_subtype in subtypes(a_type)
    if isleaftype(a_subtype)
      push!(a_subtypes, a_subtype)
    else
      append!(a_subtypes, all_concrete_subtypes(a_subtype))
    end
  end
  return a_subtypes
end

concrete_learner_types = setdiff(
  all_concrete_subtypes(Learner),
  all_concrete_subtypes(TestLearner)
)

using FactCheck


facts("CombineML system") do
  context("All learners train and predict on fixture data.") do
    for concrete_learner_type in concrete_learner_types
      learner = concrete_learner_type()
      fit_and_transform!(learner, nfcp)
    end

    @fact 1 --> 1
  end

  context("All learners train and predict on iris dataset.") do
    # Get data
    dataset = readcsv(joinpath(Pkg.dir("CombineML"),"test", "iris.csv"))
    features = dataset[:,1:(end-1)]
    labels = dataset[:, end]
    (train_ind, test_ind) = holdout(size(features, 1), 0.3)
    train_features = features[train_ind, :]
    test_features = features[test_ind, :]
    train_labels = labels[train_ind]
    test_labels = labels[test_ind]

    # Test all learners
    for concrete_learner_type in concrete_learner_types
      learner = concrete_learner_type()
      fit!(learner, train_features, train_labels)
      transform!(learner, test_features)
    end

    @fact 1--> 1
  end

  context("Ensemble with learners from different libraries work.") do 
    learners = Learner[]
    push!(learners, RandomForest())
    push!(learners, StackEnsemble())
    if LIB_SKL_AVAILABLE
      push!(learners, SKLLearner())
    end
    if LIB_CRT_AVAILABLE
      push!(learners, CRTLearner())
    end
    ensemble = VoteEnsemble(Dict(:learners => learners))
    predictions = fit_and_transform!(ensemble, nfcp)

    @fact 1 --> 1
  end

  context("Pipeline works with fixture data.") do
    transformers = [
      OneHotEncoder(),
      Imputer(),
      #StandardScaler(),
      BestLearner()
    ]
    pipeline = Pipeline(Dict(:transformers => transformers))
    predictions = fit_and_transform!(pipeline, fcp)

    @fact 1 --> 1
  end
end

end # module
