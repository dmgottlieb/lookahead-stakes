---
layout: chapter
title: First-pass Schelling game models
custom_js:
- assets/js/index.js
custom_css:
- assets/css/index.css
---

* TOC
{:toc}

# Baseline model

The below is directly adapted from the *agentmodels* textbook ([here](http://agentmodels.org/chapters/7-multi-agent.html)), with some small tweaks: 

* sample both Alice and Bob's recursive models and return the joint distribution,
* both Alice and Bob reason to the depth given by the `depth` variable. 

(Also: a limitation of this implementation is that it doesn't use `dp.cache` from the `webppl-dp` module by Stuhlmüller. 
The built-in `mem` function won't work in mutual recursion. 
In complex deep recursions, this could be a real hit to efficiency, but it doesn't seem to matter here.)

~~~~
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var alice = function(depth) {
  return Infer({ method: 'enumerate' }, function(){
    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else {
      var bobLocation = sample(bob(depth - 1));
      condition(myLocation === bobLocation);
      return myLocation;
    }
  });
};

var bob = function(depth) {
  return Infer({ method: 'enumerate' }, function(){
    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else {
      var aliceLocation = sample(alice(depth-1));
      condition(myLocation === aliceLocation);
      return myLocation;
    }
  });
};

var depth = 3;

var d = Infer({method: 'enumerate'}, function(){
  return {
    alice: sample(alice(depth)),
    bob: sample(bob(depth))
  }
});

viz.auto(d)
~~~~

# Sampling hypothesis model

The *sampling hypothesis* predicts that human reasoners make use of their belief distributions by drawing one or more samples (rather than directly using a MAP estimate, for example). 
In the baseline model above, Alice and Bob choose their ultimate action by drawing one sample (each) from their respective belief distributions. 
However, in the nested conditioning they use to reason about each others' beliefs, they use the whole distribution rather than drawing a sample. 

What if instead they are limited to drawing a sample from their beliefs about the other agent? 

**NB: on testing, this change actually makes no difference at all. It appears that the original design was already sample-based, even though it constructs an explicit distribution at each step.** 

~~~~
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var alice = function(depth) {

    var myLocation = locationPrior();
    var bobLocation = bob(depth - 1);
    condition(myLocation === bobLocation);
    return myLocation;
};

var bob = function(depth) {

    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else {
      var aliceLocation = alice(depth);
      condition(myLocation === aliceLocation);
      return myLocation;
    }
  
};

var depth = 1;

var d = Infer({method: 'enumerate'}, function(){
	return {
		alice: alice(depth),
		bob: bob(depth)
	}
});

viz.auto(d)
~~~~

## Maximum a posteriori

If Alice and Bob used MAP estimates from their predictive distributions, rather than samples, then they would always successfully coordinate.
In fact, they could do this with only one recursive reasoning step. 

~~~~
///fold:
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var alice = function(depth) {
  return Infer({ method: 'enumerate' }, function(){
    var myLocation = locationPrior();
    var bobLocation = sample(bob(depth - 1));
    condition(myLocation === bobLocation);
    return myLocation;
  });
};

var bob = function(depth) {
  return Infer({ method: 'enumerate' }, function(){
    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else {
      var aliceLocation = sample(alice(depth));
      condition(myLocation === aliceLocation);
      return myLocation;
    }
  });
};
///

var depth = 1;

var d = Infer({method: 'enumerate'}, function(){
	return {
		alice: alice(depth).MAP().val,
		bob: bob(depth).MAP().val
	}
});

viz.auto(d)
~~~~

## With multiple samples

Another way that Alice and Bob could improve their performance would be to draw multiple samples from their predictive distribution. 
In the limit of many samples, they would achieve the MAP estimate and always coordinate. 

**NB: pretty sure this is not yet correct. It behaves strangely.** 

~~~~
///fold:
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var alice = function(depth) {

    var myLocation = locationPrior();
    var bobLocation = bob(depth - 1);
    condition(myLocation === bobLocation);
    return myLocation;
};

var bob = function(depth) {

    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else {
      var aliceLocation = alice(depth);
      condition(myLocation === aliceLocation);
      return myLocation;
    }
  
};

var decision = function(sampler, depth, numSamples) { 
  var d = Infer({method: "forward", samples: numSamples}, function() {
    return sampler(depth);
  });
  return d.MAP().val
}

///

var depth = 1;
var numSamples = 3;

var d = Infer({method: 'rejection',samples: 2000}, function(){
	return {
		"alice": decision(alice,depth,numSamples),
		"bob": decision(bob,depth,numSamples)
	}
});

viz.auto(d)

~~~~



# Stochastic lookahead model 

**NB: I think this is correct but I'm not completely sure. Note also that some cases take a loooong time to run.** 

~~~~
///fold: 
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var opts = {method: "enumerate"};

var alice = function(depth,rate) {
  return Infer(opts, function(){
    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else if (!flip(rate)) {
      return sample(alice(depth-1,rate));
    } else {
      var bobLocation = sample(bob(depth - 1,rate));
      condition(myLocation === bobLocation);
      return myLocation;
    }
  });
};

var bob = function(depth,rate) {
  return Infer(opts, function(){
    var myLocation = locationPrior();
    if (depth === 0) {
      return myLocation;
    } else if (!flip(rate)) {
      return sample(bob(depth-1,rate));
    } else {
      var aliceLocation = sample(alice(depth-1,rate));
      condition(myLocation === aliceLocation);
      return myLocation;
    }
  });
};
///

var depth = 5;
var rate = 0.9;

var d = Infer({method: 'enumerate'}, function(){
	return {
		alice: sample(alice(depth,rate)),
		bob: sample(bob(depth,rate))
	}
});

viz.auto(d)
~~~~

# Lookahead-stakes model

~~~~
///fold: 
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var opts = {method: "enumerate"};

var utility = function(agent, aliceBar, bobBar) {
  if (agent == 'alice') {
    var values = {
      'popular-bar-popular-bar' : 3.6,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 3
    };
    return values[aliceBar + "-" + bobBar];
  }
  if (agent == 'bob') {
    var values = {
      'popular-bar-popular-bar' : 3,
      'popular-bar-unpopular-bar' : 0,
      'unpopular-bar-popular-bar' : 0,
      'unpopular-bar-unpopular-bar' : 3.6
    };
    return values[aliceBar + "-" + bobBar];
  }
}

var game = function(depth, rate, alpha) {
  var bobAction = sample(bob(depth,rate, alpha));
  var aliceAction = sample(alice(depth, rate, alpha)); 
  return {//aliceBar: aliceAction.myLocation, bobBar: bobAction.myLocation, 
    aliceDepth: depth - aliceAction.levelsLeft, 
    bobDepth: depth - bobAction.levelsLeft}
}

var alice = function(depth,rate, alpha) {
  return Infer(opts, function(){
    var myLocation = locationPrior();
    if ((depth === 0) || (!flip(rate))) {
      return {'myLocation': myLocation, 'levelsLeft': depth};
    } else {
      var bobAction = sample(bob(depth - 1,rate, alpha));
      var payoff = utility('alice', myLocation, bobAction.myLocation);
      factor(alpha*(payoff));
      return bobAction;
    }
  });
};

var bob = function(depth,rate, alpha) {
  return Infer(opts, function(){
    var myLocation = locationPrior();
    if ((depth === 0) || (!flip(rate))) {
      return {'myLocation': myLocation, 'levelsLeft': depth};
    } else {
      var aliceAction = sample(alice(depth-1,rate, alpha));
      var payoff = utility('bob', aliceAction.myLocation, myLocation);
      factor(alpha*(payoff));
      return aliceAction;
    }
  });
};
///

var depth = 5;
var rate = 0.5;
var alpha = 1;

var d = Infer({method: 'enumerate'}, function(){
  return game(depth, rate, alpha)
});

viz.auto(d)
~~~~