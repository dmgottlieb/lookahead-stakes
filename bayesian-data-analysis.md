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
      'popular-bar-popular-bar' : 5,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 6
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 6,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 5
    };
    return values[aliceBar + "-" + bobBar];
  }
}

var utilityHighAsym = function(agent, aliceBar, bobBar) {
  if (agent == 'alice') {
    var values = {
      'popular-bar-popular-bar' : 15,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 18
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 18,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 15
    };
    return values[aliceBar + "-" + bobBar];
  }
}



var game = function(depth, params,utility) {
  var bobAction = sample(bob(depth,params,utility));
  var aliceAction = sample(alice(depth, params,utility)); 
  return {aliceBar: aliceAction.myLocation, bobBar: bobAction.myLocation, 
    aliceDepth: depth - aliceAction.levelsLeft, 
    bobDepth: depth - bobAction.levelsLeft}
}

var alice = function(depth,params,utility) {
  return Infer(innerOpts, function(){
    var myLocation = locationPrior(params['locationPriorRate']);
    if ((depth === 0) || (!flip(params['rate']))) {
      return {'myLocation': myLocation, 'levelsLeft': depth};
    } else {
      var bobAction = sample(bob(depth - 1,params,utility));
      var payoff = utility('alice', myLocation, bobAction.myLocation);
      factor(params['alpha']*(payoff));
      return bobAction;
    }
  });
};

var bob = function(depth,params,utility) {
  return Infer(innerOpts, function(){
    var myLocation = locationPrior(params['locationPriorRate']);
    if ((depth === 0) || (!flip(params['rate']))) {
      return {'myLocation': myLocation, 'levelsLeft': depth};
    } else {
      var aliceAction = sample(alice(depth-1,params,utility));
      var payoff = utility('bob', aliceAction.myLocation, myLocation);
      
      factor(params['alpha']*(payoff));
      return aliceAction;
    }
  });
};
///

var opts = {method: 'MCMC', samples: 5000, callbacks: [editor.MCMCProgress()]};
//var opts = {method: 'enumerate'};

var dataModel = Infer(opts, function() {
	var params = {
		rate: sample(Uniform({a: 0, b: 1})),//, {driftKernel: uniformKernel}),
		alpha: sample(Exponential({a: 1})),
        locationPriorRate: sample(Uniform({a: 0.5, b: 1}))	
    };
   //print(params['alpha'])


	var depth = 2;	
 
    //Condition on low stakes-symmetric data
	var popularList = repeat(24, function () { 
		var o = game(depth, params, utilityLowSym); 
		var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
		var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
		return numAlice + numBob;
		// if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
		// if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
	});

	var symLowStakesPopularChoices = Math.sum(popularList);

	condition(symLowStakesPopularChoices == 40);

	// Condition on high stakes-symmetric data
	var popularList = repeat(24, function () { 
		var o = game(depth, params, utilityHighSym); 
		var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
		var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
		return numAlice + numBob;
		// if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
		// if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
	});

	var symHighStakesPopularChoices = Math.sum(popularList);

	condition(symHighStakesPopularChoices == 47);


	// Condition on low stakes-asymmetric data
	var popularList = repeat(24, function () { 
		var o = game(depth, params, utilityLowAsym); 
		var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
		var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
		return [numAlice, numBob];
		// if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
		// if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
	});

	var asymLowStakesAlice = Math.sum(map(function(l) {l[0]}, popularList));
	var asymLowStakesBob = Math.sum(map(function(l) {l[1]}, popularList));

	condition(asymLowStakesAlice == 12);
	condition(asymLowStakesBob == 10);

	// Condition on high stakes-asymmetric data 
	var popularList = repeat(24, function () { 
		var o = game(depth, params, utilityHighAsym); 
		var numAlice = o.aliceBar === 'popular-bar' ? 1 : 0; 
		var numBob = o.bobBar === 'popular-bar' ? 1 : 0; 
		return [numAlice, numBob];
		// if (o.aliceBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
		// if (o.bobBar == 'popular-bar') {var symLowStakesPopularChoices = symLowStakesPopularChoices + 1}
	});

	var asymHighStakesAlice = Math.sum(map(function(l) {l[0]}, popularList));
	var asymHighStakesBob = Math.sum(map(function(l) {l[1]}, popularList));

	condition(asymHighStakesAlice == 11);
	condition(asymHighStakesBob == 13);

	return params;
})

viz.marginals(dataModel)
~~~~

