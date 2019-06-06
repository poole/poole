---
layout: post
title: Characterizing Divergence in Deep Q-Learning - Notes
---

> [Link to paper](https://arxiv.org/pdf/1903.08894.pdf) 

<!-- MarkdownTOC -->

- [Towards Characterizing Divergence in Deep RL](#towards-characterizing-divergence-in-deep-rl)
    - [What is RL?](#what-is-rl)
        - [Introduction](#introduction)
        - [The Bellman equation](#the-bellman-equation)
        - [Function approximation and the deadly triad](#function-approximation-and-the-deadly-triad)
    - [Characterising Divergence](#characterising-divergence)
        - [The key equation](#the-key-equation)
        - [Derivation](#derivation)
        - [Contraction Maps](#contraction-maps)
        - [$\mathcal U$ as a map](#%24mathcal-u%24-as-a-map)
        - [Some \(formalised\) heuristics for when divergences will not occur](#some-formalised-heuristics-for-when-divergences-will-not-occur)
    - [A solution - PreQN](#a-solution---preqn)

<!-- /MarkdownTOC -->


# Towards Characterizing Divergence in Deep RL

## What is RL?
### Introduction
Deep reinforcement learning (RL) is an area of machine learning around how agents should take actions to maximise some cumulative reward. It is used when the AI has to choose actions to try to achieve some objective, where the best action can depend on the the situation the AI is in, and the environment may not be deterministic. Some currently popular examples:

* [**AlphaZero**](https://deepmind.com/blog/alphago-zero-learning-scratch/) which is able play both Go and chess and beat world champions
* [**AlphaStar**](https://www.theverge.com/2019/1/24/18196135/google-deepmind-ai-starcraft-2-victory) which can play StarCraft and beat human pros
* [Gentle Manipulation](https://sites.google.com/view/gentlemanipulation) which can successfully interact with an object in the real world which may be fragile

Let's take StarCraft as an example: StarCraft is like any real-time strategy game. The AI needs to make a decision now, but the full benefits or costs of this action may not be received until far into the future. Moreover, the benefits may be somewhat random - they may depend on the opponent's actions (which are probably not deterministic), or on certain rewards which are generated randomly.
### The Bellman equation 
(I assume a bit of knowledge here, because an introduction to RL is probably much easier to get elsewhere. I'm just interested in the setup.)

In general, we want to be able to estimate the expected future rewards of every move the AI could make (and then we want to pick the best action). However, the best action depends on what _state_ the AI is in. We define a function $Q(s,a)$ to be the expected future rewards from taking action $a$ in state $s$. 

This problem sounds quite hard: in theory, before you estimate how valuable  your first move was, you need to wait until the end of the game to properly evaluate it. 

Luckily, this equation telescopes into the Bellman equation:
$$ Q(s_0,a_0) = R(s_0, a_0, s_1) + \gamma \mathbb E \left( \max_{a_1} Q(s_1,a_1) \right)$$

That is, the value of taking action $a_0$ in state $s_0$ is the sum of:
* The reward you get immediately after you take that action; plus
* The expected value you will get from the next state $s_1$, assuming you take the best action, with the future rewards discounted by some discount factor $\gamma$.

### Function approximation and the deadly triad
You can imagine this like a giant spreadsheet, where every possible state that could ever be reached is a row, and ever possible action that could ever be taken in that state is a column. We just need to run backwards induction over and over until this table converges on a solution. Such an approach I will term the "lookup table" approach.

And this is what you could do if there were only a few possible states you could be in, and a few possible moves. However, in a complex environments, the number of dimensions is huge: there are many, many states and many, many actions that can be taken. Keeping track of a single value for each cell in this table is just too much work.

Because of this, a common method is to approximate the Q-function using a neural network. In theory, a neural network of sufficient width and/or depth can replicate any function, so this shouldn't be a problem.

Unfortunately this completes the third of what Sutton and Barton call **the deadly triad of RL**:

* Function approximation;
* Bootstrapping; and
* Off-policy learning

Basically if we take action $a_t$ in state $s_t$ and the reward is worse than our Q-function predicted, we would want to reduce the Q-estimate of this. However, in a neural network, this is achieved by slightly adjusting all of the parameters a little bit. And that means that changing the value of $Q(a_t, s_t)$ also affects the value of every other state-action pair in this function, even if we didn't intend this to happen.

If we were just using function approximation alone, this might be OK. However, we also *bootstrap* our learning, which is to say in order to estimate the correct value of $Q(s_t, a_t)$, we calculate 

$$R(s_t, a_t, s_{t+1})+\max_{a_{t+1}} Q(s_{t+1},a_{t+1})$$ 

where the second term is itself an estimation. Hence, if one of the values of $Q(s_{t+1}, \cdot)$ is over-estimated, then this will flow onto $Q(s_t,a_t)$, which will also be over-estimated. This tends to flow onto the entire network, and values keep getting larger and larger. This "values keep getting larger and larger" is called _divergence_.

## Characterising Divergence
### The key equation
Despite the above argument that the network will diverge, RL sometimes still works. The first contribution of this paper is to show why it does diverge in some cases, and in others it doesn't. The key step is to describe the update of the parameters of the Q-function (from $\theta$ to $\theta'$) as:

$$Q_{\theta'}=Q_\theta+\alpha K_\theta D_\rho (\mathcal T^* Q_\theta-Q_\theta)+\mathcal O(g^2)$$

Here:

* $Q_{\theta'}$ is a vector where we have converted all two-place arguments of the Q-function $(s,a)$ to a one-place index so that it can be expressed a vector. We use the Q-function with the updated parameters $\theta'$. 
    * For notation, I'll write this index as $i_{s,a} \in \{0,\ldots,\vert S \vert \vert A \vert -1\}$, where $\vert S \vert$ and $\vert A\vert$ are the number of different states and actions that could ever be visisted and taken respectively
* $Q_\theta$ is the equivalent vectorised Q-function using the initial parameters $\theta$
* $\alpha$ is the learning rate
* $K_\theta$ is a matrix where the $(i, j)$th element is $\nabla_\theta Q_i \nabla_\theta Q_j$. This is also called the _neural tangent kernal_, to be discussed later.
* $D_\rho$ is a diagonal matrix is the _off-policy data distribution_, where the $(i_{s,a},i_{s,a})$th element $\rho(s,a)$ is the proportion of the experience buffer which relates to taking action $a$ in state $s$. 
* $\mathcal T^*Q_\theta (s,a)= R(s,a,s') + \gamma \max_{a'} Q(s',a')$, where both $R(s,a,s')$ and $s'$ are known from the actual experience. $\mathcal T^*Q_\theta$ is the _sample estimate_ of $Q_\theta$. (Note that if the environment is stochastic, it is possible that the same $(s,a)$ could lead to different $s'$, and so $\mathcal T^*Q_\theta$ can be seen as an average of the sample estimates.
* $g = \Vert \theta' - \theta \Vert$, which can be regarded as the _non-linear_ part of the approximation

In short, this doesn't converge (i.e. diverges) when any of $K_\theta, D_\rho, \mathcal T^* Q_\theta, g$ are too large. But first let's derive this equation.

### Derivation
Firstly, we have the Taylor series. Given any function $f$:

$$f(x)=\sum_{n=0}^\infty \left(\frac{f^{(n)}(a)}{n!}(x-a)^n \right) $$

So we repeat this with the function $Q_\theta(\bar{s},\bar{a})$, where we hold $\bar{s}, \bar{a}$ constant and use the Taylor expansion to write the Q-function when we update from $\theta$ to $\theta'$.

$$Q_{\theta'}(\bar{s},\bar{a}) = Q_{\theta}(\bar{s}, \bar{a})+\nabla_\theta Q_\theta(\bar{s},\bar{a})^T(\theta'-\theta)+\mathcal O(\Vert \theta'-\theta \Vert^2) $$

And we know $\theta'$ from the back propagation algorithm:

$$\theta'=\theta +\alpha \mathbb E_{s,a \sim \rho} \left[ (\mathcal T^*Q(s,a)-Q(s,a)) \nabla_\theta Q_\theta(s,a) \right]$$

Substituting this into the Taylor series, we have:

$$
\begin{aligned} Q_{\theta'}(\bar{s},\bar{a}) = &Q_{\theta}(\bar{s}, \bar{a})\\&+ \alpha \nabla_\theta Q_\theta(\bar{s},\bar{a})^T\mathbb E_{s,a \sim \rho} \left[ (\mathcal T^*Q(s,a)-Q(s,a)) \nabla_\theta Q_\theta(s,a) \right]\\&+\mathcal O(\Vert \theta'-\theta \Vert^2) 
\end{aligned}
$$

To remove the expectation, we use $D_\rho$, and we combine the two derivatives in the second term to yield $K_\theta$, which gets us the required result.

### Contraction Maps
As previously said, the "key equation" suggests divergence when any of $K_\theta, D_\rho, \mathcal T^* Q_\theta, g$ are too large. To show this, we want to see what happens when as we continue to update the Q-function - that is we iteratively apply this update operator $\mathcal U$:

$$\mathcal UQ := Q+\alpha K D (\mathcal T^*Q-Q)+\mathcal O (g^2)$$


and see if this converges or not. 

It turns out this converges if the operator $\mathcal U$ is a _contraction map_, or more formally, if we have some metric $d$ and two Q-functions $Q_1, Q_2$ which each have parameters $\theta_1, \theta_2$ respectively:


$$d(UQ_1, UQ_2) \leq \beta d(Q_1,Q_2)$$

is a contraction map if $\beta \leq 1$, and is a .

The obvious distance metric is (any, not just L2) norm $d(x, y) := \Vert x-y\Vert$, i.e.

$$\Vert UQ_1 - UQ_2 \Vert \leq \beta \Vert Q_1-Q_2 \Vert$$


As some intuition, it is helpful to imagine $Q_1, Q_2$ as points in $\mathbb R^{\vert S \vert \vert A \vert}$ space, where the location of each point can be described by specifying the parameters $\theta_1, \theta_2$.

Suppose we initialise two different networks with $\theta_1, \theta_2$. Now suppose we update each network (with the update operate $\mathcal U$). We now have $\theta_1', \theta_2'$ and which correspond to two points in our $\mathbb R^{\vert S \vert \vert A \vert}$ space $\mathcal UQ_1, \mathcal UQ_2$.

If $\mathcal U$ is a contraction map, then we know the two points are closer together. And that means if we apply the update operator again, the points after the second update $\mathcal U^2Q_1, \mathcal U^2Q_2$ will be even closer together. 

As we continue to update, the distance will decrease until they are on the same point. Once this happens, further applications of $\mathcal U$ will not change  the location of either Q-function, and the network is said to have "converged" to some $Q^*$ (intuitively, it cannot learn anything more from the data).

(It's worth noting that there is not guarantee that the mapping from $\theta$ to $Q$ is surjective - there may be values in $\mathbb R^{\vert S \vert \vert A \vert}$ space which are not attainable by any $\theta$. This especially means that $Q^*$ may not even be attainable)

So firstly we need to show that $\mathcal U$ can be expressed as 

$$\Vert \mathcal UQ_1 - \mathcal UQ_2 \Vert \leq \beta \Vert Q_1-Q_2 \Vert$$ 

for some $\beta$, and then we need to discuss what would lead to a $\beta > 1$.

### $\mathcal U$ as a map
To begin, we assume that  $\mathcal O (g^2)$ term is 0, so that we can drop it. This assumption is normally reasonable, because most RL networks use ReLU for the hidden layers, meaning the second derivative of the update step wrt to this step is 0.

The authors further assume that the Q-function can be expressed as linear function approximation (I'm not sure if this is reasonable, I should add!), so that we can write,

$$Q_\theta(s,a) = \theta^T \phi(s,a)$$

for some function $\phi$. 

This both automatically guarantees that the second order terms are effectively 0, and means that we can express $K_\theta$ as some $K$ invariant to $\theta$:

$$\begin{aligned}
K_\theta(s,a,\bar s, \bar a) &= \nabla_\theta (\theta^T \phi(s,a))\nabla_\theta (\theta^T \phi(\bar s,\bar a))\\
& = \phi(s,a) \phi(\bar s, \bar a) \\
&=: K(s,a)
\end{aligned}
$$

Given we can pick any norm, we use the sup-norm ( $\Vert \cdot \Vert_\infty$), and consider a specific state-action $i = i(s,a)$:

$$
\begin{aligned}
{[}\mathcal UQ_1 - \mathcal UQ_2 ]_i &= [ (Q_1+\alpha K D_\rho (\mathcal T^*Q_1-Q1)) -( Q_2+\alpha K D_\rho (\mathcal T^*Q_2-Q_2))]_i \\
&= [Q_1-Q_2]_i + \alpha \sum_j K_{ij} \rho_j ((\mathcal T^*Q_1-Q_1) - (\mathcal T^*Q_2-Q_2)) \\
&=  \sum_j \left[ (\delta_{ij} - \alpha K_{ij} \rho_i )(Q_1-Q_2) + \alpha K_{ij} \rho_j (\mathcal T^* Q_1 - \mathcal T^* Q_2) \right] 
\end{aligned}
$$

Now because $\mathcal T^*Q_1, \mathcal T^*Q_2$ are the sample estimates, the values of $R(s,a,s')$ and $s'$ are not dependent on the parameters $\theta$ (they are based on the experience). Hence we simplify the second term via:

$$
\begin{aligned}
{[} \mathcal T^* Q_1- \mathcal T^*Q_2]_{s,a} &\leq \max_{s,a} (\mathcal T^* Q_1(s,a)- \mathcal T^* Q_2(s,a)) \\
&= \max_{s,a} ( R(s, a,s')+\gamma \max_{a'}Q_1(s',a') \\
&- R(s,a,s')-\gamma \max_{a''}Q_2(s',a'') ) \\
&= \gamma \max_{s,a} (\max_{a'}Q_1(s',a') - \max_{a''}Q_2(s',a'') ) \\
&\leq \gamma \max_{s,a} ( Q_1(s,a) - Q_2(s,a) ) \\
&= \gamma \Vert Q_1-Q_2 \Vert_\infty
\end{aligned}$$

If the environment is stochastic, then as we previously noted $\mathcal T^*Q_1, \mathcal T^*Q_2$ can be seen as the average of their respective sample estimates. Regardless, the above proof still follows. 

And so we continue from before (noting that $\alpha, \rho_ \geq 0$),

$$
\begin{aligned}
{[} \mathcal UQ_1 - \mathcal UQ_2 ]_i & \leq \sum_j \left[ (\delta_{ij} - \alpha \vert K_{ij} \vert \rho_i )(Q_1-Q_2) + \alpha \gamma K_{ij} \rho_j \Vert Q_1 - Q_2 \Vert_\infty \right] \\
&\leq \sum_j \left[ ( \vert \delta_{ij} - \alpha K_{ij} \rho_i \vert + \alpha \gamma \vert K_{ij} \vert \rho_j )\Vert Q_1 - Q_2 \Vert_\infty \right] 
\end{aligned}
$$

And because this is true for all $i$, it is true even if we pick out the $i$ with the largest $[\mathcal UQ_1 - \mathcal UQ_2]_i$, i.e.,

$$\Vert \mathcal UQ_1 - \mathcal UQ_2 \Vert_\infty \leq \max_i \left( \sum_j  ( \vert \delta_{ij} - \alpha K_{ij} \rho_i \vert + \alpha \gamma \vert K_{ij} \vert \rho_j ) \right) \Vert Q_1 - Q_2 \Vert_\infty   $$

And so we know $\mathcal U$ is a contraction map if we assume $\alpha K_{ii} \rho_i < 1$ (which we require in the third step, to remove the modulus) and,

$$ 
\begin{aligned}
& \max_i \left( \sum_j ( \vert \delta_{ij} - \alpha K_{ij} \rho_i \vert + \alpha \gamma \vert K_{ij} \vert \rho_j ) \right) \leq 1 \\
\implies & \max_i \left( \vert 1-\alpha K_{ii} \rho_i \vert + \alpha \gamma K_{ii} \rho_j + \alpha (1+\gamma) \sum_{j\neq i} \vert K_{ij} \vert \rho_j \right) \leq 1\\
\implies & \max_i \left( 1- (1 - \gamma) \alpha K_{ii} \rho_i + \alpha (1+\gamma) \sum_{j\neq i} \vert K_{ij} \vert \rho_j \right) \leq 1\\
\implies & \forall i, \quad (1+\gamma) \sum_{j\neq i} \vert K_{ij} \vert \rho_j \leq (1-\gamma) K_{ii}\rho_i
\end{aligned}
$$

The authors note that this condition is quite restrictive, as $\gamma$ close to $1$ (as is common) makes the ratio $\frac{1+\gamma}{1-\gamma}$ quite large. Nevertheless they say this is still "instructive".

Finally, because we are iteratively applying this operator, each "update step" involves a different operator (because each update includes a different minibatch - different $\rho$; and a different neural tangent kernal - different $K_\theta$). 


If we assume that each operator has the same fixed point $\tilde Q$, then applying this sequence of operators still gets us to converge to this fixed point:

More formally, if we apply a sequence $\{ \mathcal U_0, \mathcal U_1, \ldots\}$, and $Q_i := \mathcal U_i Q_{i-1}$ and $Q_0$ is some arbitrary initial point, and:

1. Each $\mathcal U_i$ is also a contraction map, i.e. it can be written as,

    $$ \Vert \mathcal U_i Q_{\theta_A} - \mathcal U_i Q_{\theta_B} \Vert \leq \beta_i  \Vert Q_{\theta_A} - Q_{\theta_B} \Vert $$

    for some $\beta_i \in [0,1)$

2. Each $\mathcal U_i$ has the same fixed point, then,

$$
\begin{aligned}
\Vert \tilde Q - Q_i \Vert &= \Vert \mathcal U_{i-1} \tilde Q - \mathcal U_{i-1} Q_{i-1} \Vert\\
&\leq \beta_{i-1}  \Vert \tilde Q - Q_{i-1} \Vert \\
&\leq (\prod_{k=0}^{i=1} \beta_k) \Vert \tilde Q - Q_0 \Vert
\end{aligned}
$$

We know (1) is true so long as $\forall h, (1+\gamma) \sum_{j\neq h} \vert K_{hj} \vert \rho_j \leq (1-\gamma) K_{hh}\rho_h$.

(2) is intuitively true, as it is the theoretic "optimal" parameterisation, which leads to the best play. It is, however, not guaranteed to actually exist. For example, the neural network may not have enough degrees of freedom to accurately output correct Q-estimates for all $(s,a)$ pairs.

### Some (formalised) heuristics for when divergences will not occur

As we said, $\mathcal U$ is a contraction map when,

$$\forall i, \quad (1+\gamma) \sum_{j\neq i} \vert K_{ij} \vert \rho_j \leq (1-\gamma) K_{ii}\rho_i$$

Or when:

$$\alpha K_{ii} \rho_i \geq 1$$

Which suggests the following failure conditions:

- The off diagonal kernel entries are too large, that is $\nabla_\theta Q_i^T \nabla_\theta Q_j$ is too large. This intuitively happens when the same parameter $\theta_k$ is updated significantly by different states. This *wouldn't* happen on a lookup table, and is the result of us using function approximation.
- The value $\rho_i = 0$ for some $i$. This intuitively happens when there isn't enough data. Because each parameter $\theta_k$ is updated by every data point, if there is no data relating to the $k$ th action-pair state, the Q-value for state $k$ may be wildly overestimated, leading to divergence.
- The learning rate $\alpha$ is too large, so much so that we "overstep". This is a common failure of neural networks, but here, because we bootstrap our next estimate by looking at our predictions, this can again lead to divergence.

## A solution - PreQN

The paper goes onto describe PreQN - I will fill this out in a future note
