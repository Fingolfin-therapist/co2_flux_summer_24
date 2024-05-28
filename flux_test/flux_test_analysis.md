# Pipeline

1. Import Data
2. Correct Timestamps
3. Calibrate Sensors / Reference Instrument
4. Per Set-Point Analysis

   1. Determine Steady State Periods

       - `movmean < threshold`

   2. Calculate Flux

       - Use gradient method on non-steady state values.
       - Use steady-state model on assumed steady state periods.

   3. Format Data

       - Organize and document all actions performed on the datasets.
       - Organize all of the data to one .csv file showing important numbers.

   4. Display Data

       - Display important information

   5.  Generate Plots

       - Generate plots
       - Display Important Plots

5.  Save Data

## Information
- What ELTs map to which DAQ column.
- Calibration or Colocation Dataset
- The flowrate of the 