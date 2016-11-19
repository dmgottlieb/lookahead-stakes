---
layout: chapter
title: Models section
custom_js:
- assets/js/index.js
custom_css:
- assets/css/index.css
---

# Model

Our model features two agents, Alice and Bob, attempting to meet at one of two possible bars: the popular bar and the unpopular bar. 
They model each other's decisions using nested conditioning, and choose the best action according to the "planning as inference" paradigm.
Each agent's decision process begins with a prior over possible actions. 
All possible outcomes are then weighted with log-probability scores according to their utilities, and an action is sampled from the posterior with a softmax process. 
Each agent's decision is then characterized by the following probability distribution: 

$$P(\text{action}) \propto e^{\alpha EU(\text{action})},$$

where $EU(\text{action})$ is the expected utility of the action and $\alpha$ is a softmax temperature parameter (low $\alpha$ = high temperature). 


In the model, the main possible actions are `{'popular-bar', 'unpopular-bar'}`. 
Both agents have the same prior over actions, which is a 55% chance of choosing the popular bar (this bias reflects that the popular bar is the more *salient* option). 
They then have utility payoffs assigned to game outcomes. 
For example, in the baseline symmetric game, each agent receives a payoff of 1 if they coordinate on the same bar, and 0 otherwise. 
Finally, they also have an implicit resource cost to recursion, encoded by a `rate` parameter. 
The `rate` parameter reflects the chance, at the $n$th level of recursion, to descend to level $n+1$. 


The core of the model is recursive nested conditioning: each agent decides what to do by simulating the other agent, and assigning larger utility weights to outcomes in which the agent and the simulated opponent choose the same action. 
For example, here is Alice's core loop: 

~~~~
var alice = function(depth,rate, alpha) {
  return Infer(opts, function(){
    var myLocation = locationPrior();
    if ((depth === 0) || (!flip(rate))) {
      return myLocation;
    } else {
      var bobLocation = sample(bob(depth - 1,rate, alpha));
      var payoff = utility('alice', myLocation, bobLocation);
      factor(alpha*(payoff));
      return myLocation;
    }
  });
};
~~~~

`depth` is the maximum possible recursion depth -- in the prototype, we usually set this parameter to 5 for computational tractability. 
`rate` is the prior over the decision, at each level of recursion, to go one level deeper. 
If `rate` is 0.5 then, *ceteris paribus*, the agent will do at least one level of recursion 0.5 of the time, at least two levels of recursion $(0.5)^2 = 0.25$ of the time, etc. 
This reflects our novel modeling assumption, that deeper recursions are more expensive. 
In the case in which agents are indifferent among all outcomes, then we can derive the cost of each level of recursion as follows: 

\begin{align*} 
P(n\text{ levels}) &\propto e^{EU(n\text{ levels})},\\
P(n\text{ levels}) &= \frac{1}{2^{n+1}} \\
				   &= e^{-(\ln 2)(n+1)}
\end{align*}

In other words, `rate` $> 0$ corresponds to a utility cost that's linear on recursion depth, here expressed as $\ln 2$ per recursion level.

`alpha` is the softmax temperature as discussed above. 

# Results

Here we report preliminary results from applying the model in several different conditions: 

1. Baseline (recursion is free). 
2. Bounded (recursion is costly).
  
  a. Low stakes.
  b. High stakes.

3. Asymmetric (agents prefer different bars). 
  
  a. Low stakes.
  b. High stakes.

4. Asymmetric (agents prefer the same bar to different degrees).

  a. Low stakes. 
  b. High stakes. 


## Baseline

To make recursion cost-free, we set the `rate` parameter to 1.0. 
Agents will then always use the maximal allowed recursion depth (in this case 5). 

In this condition, agents successfully coordinate about 64% of the time. 
In particular, they coordinate on the popular bar 59% of the time, and the unpopular bar 5% of the time. 

## Bounded

Here, recursion has a resource cost that is linear on recursion depth, as discussed above. 
Setting `rate` to 0.5 results in a resource cost of about 0.69 in the utility units of the payoff. 

In the low stakes condition, the payoffs are (1,1) for successfully coordinating and (0,0) for failing.
So we expect the costs of recursion to quickly outrun the expected benefits. 
The results reflect this. 
In this condition, the agents successfully coordinate only about 51% of the time, 33% at the popular bar and 18% at the unpopular bar. 

In the high stakes condition, we set the payoffs to (3,3) for successful coordination (this increase is comparable to the high stakes differential in experimental papers). 
Now, the rewards for success should be large enough to offset the costs of increased recursion depth.
Again, the results reflect this. 
In this condition, agents successfully coordinate about 57% of the time, 47% at the popular bar and 10% at the unpopular bar. 

## Asymmetric (agents prefer different bars) 

The experimental literature has found that this kind of payoff asymmetry destroys coordination. 
Our model correctly predicts this finding. 

In the low stakes condition, we set the payoffs to (1.2,1) and (1,1.2) respectively for the two agents, reflecting that both want to coordinate but they prefer to coordinate on different bars. 
In this condition, they coordinate about 50% of the time, 33% at the popular bar and 17% at the unpopular bar. 

In the high stakes condition, we set the payoffs to (3.6,3) and (3,3.6) respectively for the two agents. 
This increase is comparable to the differential in the high stakes condition in experiments that have tested behavior in asymmetric high stakes conditions. 
In this condition, the agents coordinate about 55% of the time, 47% on the popular bar and 8% on the unpopular bar. 
This seems somewhat at odds with the experimental results. 
The probable explanation is that the higher stakes enabled the agents to reason to a higher recursive depth, which amplified the effect of the salience bias towards the popular bar (note that the agents are also much more likely to go to the popular bar). 

More modeling and analysis is required. 

## Asymmetric (agents prefer the same bar to different degrees)

[To come.]

# Further work

We are largely done with the conceptual work of the project. 
Several engineering points remain outstanding. 

In particular: 

* We are not sure the current model handles the payoffs correctly. 

	In the code block above, you can see that `factor(alpha*(payoff))` is added at each level of recursive simulation. 
	This seems to have the effect that the payoff for coordinating on the same bar can be double-counted, or in fact counted up to $d$ times where $d$ is the depth parameter. 
	Unfortunately, this seems to be worse than simply being off by a constant factor, because it means deep recursions get a `factor` bonus that increases as they go deeper. 
	The coordination payoff is supposed to offset the resource cost of recursion, but the offset should be a flat amount, not proportional to the depth. 

	If this diagnosis is correct, we're not sure what the correct theoretically motivated fix of this problem should be. 

* We would like to report a richer range of results for each of our trials. 
Currently, we report only the joint distribution over which bars the agents go to, which allows us to calculate the rate of successful coordination. 
However, we would also like to report the distribution of actual recursion depth induced by a particular setting of `rate` and utilities. 
This would allow us to examine in a more fine-grained way (1) how stakes influence recursion depth, and (2) how much increased recursion depth helps achieve good outcomes in various conditions. 

