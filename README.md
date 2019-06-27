# Open Source PHY Architecture

## Introduction

This repository contains an ADC-based high-speed link design, along with the behavioral models and simulation framework needed to test it.  Certain parts of the design are parameterized (such as the number of filter taps), and it's possible to simulate the link behavior for an arbitrary channel by providing a file of S-parameters.

## Running the demo

1. First set up the shell environment:
```shell
> source setup.cshrc
```
2. Then go into the channel/model folder:
```shell
> cd channel/model
```
3. Build the channel models:
```shell
> make
```
4. Next, go into the architect/sim folder:
```shell
> cd ../../architect/sim
```
5. Run the simulation:
```shell
> make
```
6. View the simulation waveforms with SimVision.
```shell
> simvision
```
![Sample results as viewed in SimVision](waveforms.png?raw=true "Sample results as viewed in SimVision")
