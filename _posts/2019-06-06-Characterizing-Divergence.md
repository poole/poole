---
layout: post
title: Characterizing Divergence in Deep Q-Learning - Notes
usemathjax: true
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

$$ Q(s_0,a_0) = R(s_0, a_0, s_1) + \gamma \mathbb E \left( \max_{a_1} Q(s_1,a_1) \right)$$


