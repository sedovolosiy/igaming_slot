# Simple Slot Game

This project implements a simple slot game with basic functionality, including generating a 3x3 screen, supporting wild symbols, calculating wins using "ways," and determining the Return to Player (RTP) percentage over 1,000,000 simulated rounds.

## Features

### Reels
Reels are used to generate the slot screen. Each reel is represented as an array of symbols. The reels used in this project are as follows:

```
[
    ["APPLE", "BANANA", "PLUM", "7", "BAR", "STAR", "7", "BAR", "APPLE", "PLUM", "BANANA", "7", "BAR", "STAR", "7", "BAR", "APPLE", "PLUM"],
    ["BANANA", "PLUM", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA"],
    ["PLUM", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA", "7", "BAR", "STAR", "WILD", "7", "BAR", "APPLE", "PLUM", "BANANA", "7"]
]
```

### Wild Symbol
The Wild symbol acts as a Joker in Poker and can substitute for any other symbol in the game to form winning combinations.

### Ways
The game uses "ways" to detect winning combinations. Unlike traditional paylines, ways do not have fixed coordinates. To calculate ways:
- Ensure adjacent columns contain the same symbols (or wilds) as the starting symbol.
- Multiply the counts of matching symbols in each column to get the total number of ways.

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

### Paytable
The paytable defines the payouts for each symbol. A way must start from the 1st column and be continuous to qualify for a payout. The paytable schema is as follows:

```
{ "SYMBOL": [0, 0, payout_for_3] }
```

#### Example Paytable
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

### RTP Calculation
Return to Player (RTP) is a metric that indicates the theoretical percentage of bets returned to players over time. The RTP is calculated as follows:

```
RTP = (sum of all wins) / (sum of all bets)
```

In this project, the RTP is calculated over 1,000,000 simulated rounds.

## Example Output
```
| APPLE  | BANANA | APPLE  |
| APPLE  | PLUM   | BANANA |
| BANANA | WILD   | PLUM   |
```

## How to Run
1. Clone the repository.
2. Ensure you have Ruby installed.
3. Run the main script to simulate the game and calculate the RTP.