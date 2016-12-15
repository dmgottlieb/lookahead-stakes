---
layout: chapter
title: Bayesian Data Analysis
custom_js:
- assets/js/index.js
custom_css:
- assets/css/index.css
---

~~~~
///fold: 
var locationPrior = function(rate) {
  if (flip(rate)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var innerOpts = {method: "enumerate"};

var getUtilityFunctionFromString = function(functionString) {
  if (functionString === 'utilityLowSym') {
    return utilityLowSym;
  }
  if (functionString === 'utilityHighSym') {
    return utilityHighSym;
  }
  if (functionString === 'utilityLowAsym') {
    return utilityLowAsym;
  }
  if (functionString === 'utilityHighAsym') {
    return utilityHighAsym;
  }
}

var utilityLowSym = function(agent, aliceBar, bobBar) {
  if (agent == 'alice') {
    var values = {
      'popular-bar-popular-bar' : 5,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 5
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 5,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 5
    };
    return values[aliceBar + "-" + bobBar];
  }
}

var utilityHighSym = function(agent, aliceBar, bobBar) {
  if (agent == 'alice') {
    var values = {
      'popular-bar-popular-bar' : 15,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 15
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 15,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 15
    };
    return values[aliceBar + "-" + bobBar];
  }
}

var utilityLowAsym = function(agent, aliceBar, bobBar) {
  if (agent == 'alice') {
    var values = {
      'popular-bar-popular-bar' : 6,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 5
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 5,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 6
    };
    return values[aliceBar + "-" + bobBar];
  }
}

var utilityHighAsym = function(agent, aliceBar, bobBar) {
  if (agent == 'alice') {
    var values = {
      'popular-bar-popular-bar' : 18,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 15
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 15,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 18
    };
    return values[aliceBar + "-" + bobBar];
  }
}



var game = function(depth, params,utility) {
  return Infer({method: 'enumerate'}, function() {
    var bobAction = sample(bob(depth,params,utility));
    var aliceAction = sample(alice(depth, params,utility)); 
    return (bobAction.myLocation === aliceAction.myLocation);
  })
}

var gamePredictive = function(depth, params,utility) {
  return Infer({method: 'enumerate'}, function() {
    var bobAction = sample(bob(depth,params,utility));
    var aliceAction = sample(alice(depth, params,utility)); 
    return {success: aliceAction.myLocation === bobAction.myLocation, 
    levels: Math.max(depth - aliceAction.levelsLeft, depth - bobAction.levelsLeft)};
  })
}

var alice = dp.cache(function(depth,params,utility) {
  return Infer(innerOpts, function(){
    var myLocation = locationPrior(params['locationPriorRate']);
    if ((depth === 0) || (!flip(params['rate']))) {
      var bobLocation = locationPrior();
      var payoff = getUtilityFunctionFromString(utility)('alice', myLocation, bobLocation);
      factor(params['alpha']*(payoff));
      return {'myLocation': myLocation, 'levelsLeft': depth};
    } else {
      var bobAction = sample(bob(depth - 1,params,utility));
      var payoff = getUtilityFunctionFromString(utility)('alice', myLocation, bobAction.myLocation);
      factor(params['alpha']*(payoff));
      return {'myLocation': myLocation, 'levelsLeft': bobAction.levelsLeft};
    }
  });
},
9999); // dp.cache maxSize

var bob = dp.cache(function(depth,params, utility) {
  return Infer(innerOpts, function(){
    var myLocation = locationPrior(params['locationPriorRate']);
    if ((depth === 0) || (!flip(params['rate']))) {
      var aliceLocation = locationPrior();
      var payoff = getUtilityFunctionFromString(utility)('bob', aliceLocation, myLocation);
      factor(params['alpha']*(payoff));
      return {'myLocation': myLocation, 'levelsLeft': depth};
    } else {
      var aliceAction = sample(alice(depth - 1,params,utility));
      var payoff = getUtilityFunctionFromString(utility)('bob', aliceAction.myLocation, myLocation);
      factor(params['alpha']*(payoff));
      return {'myLocation': myLocation, 'levelsLeft': aliceAction.levelsLeft};
    }
  });
}, 
9999); // dp.cache maxSize
///

var opts = {method: 'MCMC', samples: 1000};
//var opts = {method: 'enumerate'};

var dataModel = Infer(opts, function() {
  var params = {
    rate: sample(Uniform({a: 0, b: 1})),//, {driftKernel: uniformKernel}),
    alpha: sample(Exponential({a: 1})),
        locationPriorRate: sample(Uniform({a: 0.5, b: 1}))  
    };
   //print(params['alpha'])


  var depth = 1;  
 
    //Condition on low stakes-symmetric data
  // var popularList = repeat(24, function () { 
  //  var o = game(depth, params, utilityLowSym); 
  //  var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
  //  var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
  //  return numAlice + numBob;
  //  // if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  //  // if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  // });

  var symLowStakesDist = game(depth,params,'utilityLowSym');
  var symLowStakesCoordinateProb = Math.exp(symLowStakesDist.score(true));
  observe(Binomial({p: symLowStakesCoordinateProb, n: 24}), 17);

  var symHighStakesDist = game(depth,params,'utilityHighSym');
  var symHighStakesCoordinateProb = Math.exp(symHighStakesDist.score(true));
  observe(Binomial({p: symHighStakesCoordinateProb, n: 24}), 23);

  var asymLowStakesDist = game(depth,params,'utilityLowAsym');
  var asymLowStakesCoordinateProb = Math.exp(asymLowStakesDist.score(true));
  observe(Binomial({p: asymLowStakesCoordinateProb, n: 24}), 12);

  var asymHighStakesDist = game(depth,params,'utilityHighAsym');
  var asymHighStakesCoordinateProb = Math.exp(asymHighStakesDist.score(true));
  observe(Binomial({p: asymHighStakesCoordinateProb, n: 24}), 12);


  // condition(symLowStakesPopularChoices == 40);

  // // Condition on high stakes-symmetric data
  // var popularList = repeat(24, function () { 
  //  var o = game(depth, params, utilityHighSym); 
  //  var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
  //  var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
  //  return numAlice + numBob;
  //  // if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  //  // if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  // });

  // var symHighStakesPopularChoices = Math.sum(popularList);

  // condition(symHighStakesPopularChoices == 47);


  // // Condition on low stakes-asymmetric data
  // var popularList = repeat(24, function () { 
  //  var o = game(depth, params, utilityLowAsym); 
  //  var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
  //  var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
  //  return [numAlice, numBob];
  //  // if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  //  // if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  // });

  // var asymLowStakesAlice = Math.sum(map(function(l) {l[0]}, popularList));
  // var asymLowStakesBob = Math.sum(map(function(l) {l[1]}, popularList));

  // condition(asymLowStakesAlice == 12);
  // condition(asymLowStakesBob == 10);

  // // Condition on high stakes-asymmetric data 
  // var popularList = repeat(24, function () { 
  //  var o = game(depth, params, utilityHighAsym); 
  //  var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
  //  var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
  //  return [numAlice, numBob];
  //  // if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  //  // if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
  // });

  // var asymHighStakesAlice = Math.sum(map(function(l) {l[0]}, popularList));
  // var asymHighStakesBob = Math.sum(map(function(l) {l[1]}, popularList));

  // condition(asymHighStakesAlice == 11);
  // condition(asymHighStakesBob == 13);

  // compute predictive statistics: low-sym
  var o = gamePredictive(depth, params, 'utilityLowSym');
  var successLowSym = Math.exp(marginalize(o, 'success').score(true)); 
  var levelsLowSym = expectation(marginalize(o, 'levels'));

  // compute predictive statistics: high-sym
  var o = gamePredictive(depth, params, 'utilityHighSym');
  var successHighSym = Math.exp(marginalize(o, 'success').score(true)); 
  var levelsHighSym = expectation(marginalize(o, 'levels'));

  // compute predictive statistics: low-asym
  var o = gamePredictive(depth, params, 'utilityLowAsym');
  var successLowAsym = Math.exp(marginalize(o, 'success').score(true)); 
  var levelsLowAsym = expectation(marginalize(o, 'levels'));

  // compute predictive statistics: high-asym
  var o = gamePredictive(depth, params, 'utilityHighAsym');
  var successHighAsym = Math.exp(marginalize(o, 'success').score(true)); 
  var levelsHighAsym = expectation(marginalize(o, 'levels'));

  return {successLowSym: successLowSym, 
    levelsLowSym: levelsLowSym, 
    successHighSym: successHighSym, 
    levelsHighSym: levelsHighSym, 
    successLowAsym: successLowAsym, 
    levelsLowAsym: levelsLowAsym, 
    successHighAsym: successHighAsym, 
    levelsHighAsym: levelsHighAsym, 
    rate: params['rate'], 
    alpha: params['alpha'], 
    locationPriorRate: params['locationPriorRate']};

})

viz.marginals(dataModel)

editor.put('dataModel', dataModel)
~~~~

~~~~


~~~~