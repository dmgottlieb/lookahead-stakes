---
layout: chapter
title: First-pass Schelling game models
custom_js:
- assets/js/index.js
custom_css:
- assets/css/index.css
---

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

var depth = 5;

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

# Stochastic lookahead model 

**NB: not at all confident this is correct.** 

~~~~
var locationPrior = function() {
  if (flip(.55)) {
    return 'popular-bar';
  } else {
    return 'unpopular-bar';
  }
}

var rate = 0.5;

var alice = function() {

    var myLocation = locationPrior();
    var bobLocation = flip(rate) ? bob() : locationPrior();
    condition(myLocation === bobLocation);
    return myLocation;
};

var bob = function() {

    var myLocation = locationPrior();
      var aliceLocation = flip(rate) ? alice() : locationPrior();
      condition(myLocation === aliceLocation);
      return myLocation;
    
  
};



var d = Infer({method: 'rejection', samples: 5000}, function(){
	return {
		alice: alice(),
		bob: bob()
	}
});

viz.auto(d)
~~~~