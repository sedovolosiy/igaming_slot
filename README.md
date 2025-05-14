# Slots Team Live Coding Test Task

## Task
Write a simple slot game according to the requirements below.

## Requirements
- 3x3 screen
- Generate screen from reels
- Wild symbol support
- Win by ways
- Pays by the paytable
- Count RTP of the game (on 1,000,000 rounds)

## Reels
Reels are used for generating screens, usually represented as arrays of symbols. For this task, use the following reels:

```
[
    ["APPLE", "BANANA", "PLUM", "7", "BAR", "STAR", "7", "BAR", "APPLE", "PLUM", "BANANA", "7", "BAR", "STAR", "7", "BAR", "APPLE", "PLUM"],
    ["BANANA", "PLUM", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA"],
    ["PLUM", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA", "7"]
]
```

### Output Example
```
| APPLE  | BANANA | APPLE  |
| APPLE  | PLUM   | BANANA |
| BANANA | WILD   | PLUM   |
```

## Wild Symbol
The Wild symbol acts as a Joker in Poker and can substitute for any symbol in the game.

## Ways
Ways are used for detecting win combinations. Unlike classic lines, ways do not have exact coordinates to match. To build ways, ensure that adjacent columns contain the same symbols (or wilds) as the way started. Multiply the counts of matching symbols in each column to get the total number of ways.

#### Example 1: APPLE Symbol
```
| APPLE  | BANANA | APPLE  |
| APPLE  | 7      | STAR   |
| PLUM   | WILD   | STAR   |
```
- 1st column: 2 APPLE
- 2nd column: 1 WILD
- 3rd column: 1 APPLE
- Ways: 2 x 1 x 1 = 2

#### Example 2: BANANA Symbol
```
| PLUM   | BANANA | STAR   |
| APPLE  | 7      | BANANA |
| BANANA | WILD   | STAR   |
```
- 1st column: 1 BANANA
- 2nd column: 1 WILD, 1 BANANA
- 3rd column: 1 BANANA
- Ways: 1 x 2 x 1 = 2

## Paytable
The paytable is a hash with the following schema:

```
{ "SYMBOL": [0, 0, payout_for_3] }
```
Leading zeros are for 1 & 2 continuous length of way. To be paid, a way should start from the 1st column and be continuous.

### Test Paytable
```
{
    "BANANA": [0, 0, 1],
    "APPLE": [0, 0, 2],
    "PLUM": [0, 0, 3],
    "BAR": [0, 0, 10],
    "STAR": [0, 0, 20],
    "7": [0, 10, 100]
}
```

## RTP
RTP (Return To Player) is a metric that tells how much the game theoretically returns to players. For example, with 100,000 players making 100,000 bets each (10,000,000,000 rounds), practical and theoretical RTPs are nearly the same.

To calculate practical RTP:

```
RTP = (sum of all wins) / (sum of all bets)
```

---

> **Note:** Implement the slot game logic, simulate 1,000,000 rounds, and calculate the RTP as described above.