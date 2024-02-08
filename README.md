# Fast Engines (experimenting)

Improvements:

- Reduced performance impact: 0.4/0.47 5s cpu usage.
- Enhanced drift detection:
  - RPM gradually increases based on angle.
  - Resulting in fewer revs and reduced gear interference.
- Updated configuration structure.
- Implemented new smoothing parameters:
  - Enable (smoothing activation).
  - Simple (applies solely to the local player's vehicle).
- Modified output RPM, ensuring values remain within the range of 0 to 1.
