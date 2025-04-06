# Reputation System

A simple Clarity smart contract that lets users build reputation on the Stacks blockchain through peer ratings.

## Overview

This is a test project that implements a simple reputation system where users can rate each other. The ratings affect reputation scores, with some cool features:

- Users with higher reputation (50+) can rate up to 20 points, others only 10
- Users with higher reputation can also give more negative ratings (-20 vs -10)
- Cooldown periods between ratings of the same person
- Reputation decay over time
- Tracking of all ratings made and received

## Key Features

- **Reputation Scoring**: Rate others and affect their reputation
- **Rating Limits**: Higher reputation users can give bigger ratings
- **Cooldown Periods**: Wait between ratings of the same person
- **Reputation Decay**: Reputation gradually decreases over time
- **Rating History**: All ratings are tracked and can be queried

## Contract Structure

The system uses several maps to track data:

- `user-reputation`: Stores the current reputation score for each user
- `user-decay`: Tracks when a user's reputation was last decayed
- `user-ratings`: Records ratings made by each user
- `received-ratings`: Records ratings received by each user
- `all-ratings-made`: Tracks all ratings made by a user (for testing purposes)

## Testing Approach

Regular unit tests weren't cutting it for this project. The interactions are pretty complex, so I wrote comprehensive tests to be used with Rendezvous, a testing framework for Clarity contracts.

The test suite includes:

- `test-first-rate`: Tests the first rating a user makes
- `test-second-rate`: Tests rating a user who has already been rated
- `test-optional-decay-reputation`: Tests the reputation decay mechanism

These tests verify the complex state transitions and edge cases that occur in the reputation system.

## Usage

To use this contract:

1. Deploy it to the Stacks blockchain (or just use Clarinet for local testing)
2. Users can rate others using the `rate-user` function
3. Query user reputations with `get-user-reputation`
4. View rating history with `get-ratings-made` and `get-ratings-received`

## Development

This is a small test project I built during the Clarity Bootcamp. It's mainly used with Clarinet for local development and testing. The comprehensive tests were added to ensure the system behaves correctly in all scenarios, especially when used with Rendezvous for testing. 

## Future Plans

While this is currently a small test project, I'm considering expanding it into something more robust. The idea is to build a reputation system that could be used as a backend for various applications on Stacks. Think of it as a foundation for building reputation-based features in other apps - like a trust score system for marketplaces, content quality indicators, or user verification systems. 