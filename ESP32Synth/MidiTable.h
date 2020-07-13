/*
 * Contains MIDI note ID to frequency table
 */
 

const uint32_t midiFreq[153] = {
//C,    C',   D,    D',   E,     F,     F',    G,     G',    A,     A',    B  
  8,    9,    9,    10,   10,    11,    12,    12,    13,    14,    15,    15,
16, 17, 18, 19, 21, 22, 23, 24, 26, 28, 29, 31, 
33, 35, 37, 39, 41, 44, 46, 49, 52, 55, 58, 62, 
65, 69, 73, 78, 82, 87, 92, 98, 104, 110, 117, 123, 
131, 139, 147, 156, 165, 175, 185, 196, 208, 220, 233, 247, 
262, 277, 294, 311, 330, 349, 370, 392, 415, 440, 466, 494, 
523, 554, 587, 622, 659, 698, 740, 784, 831, 880, 932, 988, 
1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976, 
2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951,
4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902, 
8372, 8870, 9397, 9956, 10548, 11175, 11840, 12544, 13290, 14080, 14917, 15804, 
16744, 17740, 18795, 19912, 21096, 22351, 23680, 25088, 26580, 28160, 29834, 31609, 
33488, 35479, 37589, 39824, 42192, 44701, 47359, 50175, 53159 
};


uint32_t getFreq(uint32_t note) 
{
  return midiFreq[note];
}

/*
const float PROGMEM midiFreq[132] = {
//C,    C',   D,    D',   E,     F,     F',    G,     G',    A,     A',    B  
8.1758, 8.6620, 9.1770, 9.7227, 10.3009, 10.9134, 11.5623, 12.2499, 12.9783, 13.7500, 14.5676, 15.4339, 
16.3516, 17.3239, 18.3540, 19.4454, 20.6017, 21.8268, 23.1247, 24.4997, 25.9565, 27.5000, 29.1352, 30.8677, 
32.7032, 34.6478, 36.7081, 38.8909, 41.2034, 43.6535, 46.2493, 48.9994, 51.9131, 55.0000, 58.2705, 61.7354, 
65.4064, 69.2957, 73.4162, 77.7817, 82.4069, 87.3071, 92.4986, 97.9989, 103.8262, 110.0000, 116.5409, 123.4708, 
130.8128, 138.5913, 146.8324, 155.5635, 164.8138, 174.6141, 184.9972, 195.9977, 207.6523, 220.0000, 233.0819, 246.9417, 
261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047, 440.0000, 466.1638, 493.8833, 
523.2511, 554.3653, 587.3295, 622.2540, 659.2551, 698.4565, 739.9888, 783.9909, 830.6094, 880.0000, 932.3275, 987.7666, 
1046.5023, 1108.7305, 1174.6591, 1244.5079, 1318.5102, 1396.9129, 1479.9777, 1567.9817, 1661.2188, 1760.0000, 1864.6550, 1975.5332, 
2093.0045, 2217.4610, 2349.3181, 2489.0159, 2637.0205, 2793.8259, 2959.9554, 3135.9635, 3322.4376, 3520.0000, 3729.3101, 3951.0664, 
4186.0090, 4434.9221, 4698.6363, 4978.0317, 5274.0409, 5587.6517, 5919.9108, 6271.9270, 6644.8752, 7040.0000, 7458.6202, 7902.1328, 
8372.0181, 8869.8442, 9397.2726, 9956.0635, 10548.0818, 11175.3034, 11839.8215, 12543.8540, 13289.7503, 14080.0000, 14917.2404, 15804.2656
};

float getFreq(uint32_t note) 
{
  return pgm_read_float( &midiFreq[note] );
}
*/
