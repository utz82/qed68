#include <iostream>
#include <fstream>
#include <string>

using namespace std;

unsigned fileoffset;
unsigned char songlength;
char cp;	//read value
ifstream INFILE;


bool isPatternUsed(int patnum);

int main(int argc, char *argv[]){

	cout << "XM 2 QED68 CONVERTER\n";
	
	//check for "-v" flag
	string arg = "";
	if (argc > 1) arg = argv[1];
	
	//open music.xm
	INFILE.open ("music.xm", ios::in | ios::binary);
	if (!INFILE.is_open()) {
		cout << "Error: Could not open music.xm\n";
		return -1;
	}
	
	//create music.asm
	ofstream OUTFILE;
	OUTFILE.open ("music.asm", ios::out | ios::trunc);
	
	if (!OUTFILE.is_open()) {
		cout << "Error: Could not create music.asm - need to set write permission?\n";
		return -1;
	}
	
	
	//verify xm parameters
	INFILE.seekg(58, ios::beg);		//read version
	INFILE.read((&cp), 1);
	if (cp != 4) {
		cout << "Error: Obsolete XM version 1.0" << +cp << ", v1.04 required" << endl;
		return -1;
	}
	
	INFILE.seekg(68, ios::beg);		//read # of channels
	INFILE.read((&cp), 1);
	if (cp != 4) {
		cout << "Error: XM has " << +cp << " channels instead of 4" << endl;
		return -1;
	}

	//read global song parameters
	unsigned char uniqueptns;
	unsigned speed;
	
	INFILE.seekg(64, ios::beg);		//read song length
	INFILE.read((&cp), 1);
	songlength = static_cast<unsigned char>(cp);
	if (arg == "-v") cout << "song length:     " << +songlength << endl;
	
	INFILE.seekg(70, ios::beg);		//read # of unique patterns
	INFILE.read((&cp), 1);
	uniqueptns = static_cast<unsigned char>(cp);
	if (arg == "-v") cout << "unique patterns: " << +uniqueptns << endl;
	
	INFILE.seekg(78, ios::beg);		//read global tempo
	INFILE.read((&cp), 1);
	speed = static_cast<unsigned>(cp);
	speed = speed&0xff;
	if (speed < 78) {
		cout << "Error: BPM < 78.\n";
		return -1;
	}
	if (arg == "-v") cout << "global bmp:    " << +speed << endl;
	speed = unsigned(19760/speed);
	speed = unsigned(255-speed);
	OUTFILE << "\n\tdc.w $" << hex << +speed << "\t\t;speed" << endl;	//write it to music.asm as hex
	
	
	//locate the pattern headers and read pattern lengths
	unsigned ptnoffsetlist[256];
	unsigned ptnlengths[256];
	unsigned headlength, packedlength, xmhead;
	unsigned char pp;
	int i;
	
	//determine XM header length
	INFILE.seekg(61, ios::beg);
	INFILE.read((&cp), 1);
	pp = static_cast<unsigned char>(cp);
	xmhead = pp*256;
	INFILE.seekg(60, ios::beg);
	INFILE.read((&cp), 1);
	pp = static_cast<unsigned char>(cp);
	xmhead+=pp;
	
	ptnoffsetlist[0] = xmhead+60;
	fileoffset = ptnoffsetlist[0];
	
	for (i=0; i < uniqueptns; i++) {
		
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&cp), 1);
		pp = static_cast<unsigned char>(cp);
		headlength = static_cast<unsigned>(pp);
		
		fileoffset += 5;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&cp), 1);
		pp = static_cast<unsigned char>(cp);
		ptnlengths[i] = static_cast<unsigned>(pp);
		
		fileoffset += 2;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&cp), 1);
		pp = static_cast<unsigned char>(cp);
		packedlength = static_cast<unsigned>(pp);
		
		fileoffset++;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&cp), 1);
		pp = static_cast<unsigned char>(cp);
		packedlength += (static_cast<unsigned>(pp))*256;
		
		ptnoffsetlist[i+1] = ptnoffsetlist[i] + headlength + packedlength;
		fileoffset = fileoffset + packedlength + 1;
		
		if (arg == "-v") cout << "pattern " << i << " starts at " << ptnoffsetlist[i] << ", length " << ptnlengths[i] << " rows\n";		
	}
	

	//generate pattern sequence
//	OUTFILE << "\n;sequence\nsloop\t\t;loop point\n";
	OUTFILE << "\nsequence\n";
	unsigned looppoint = 0;
	
	for (fileoffset = 80; fileoffset < ((unsigned)songlength+80); fileoffset++) {
		
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&cp), 1);
		OUTFILE << "\tdc.l ptn" << hex << +cp << endl;
	
	}
	OUTFILE << "\tdc.l 0\n\n;pattern data\n";

	//define note value arrays
	const unsigned notetab[79] = { 0,
		0x2FF, 0x32D, 0x35D, 0x390, 0x3C7, 0x400, 0x43D, 0x47D, 0x4C2, 0x50A, 0x557, 0x5A8,
		0x5FE, 0x659, 0x6BA, 0x721, 0x78D, 0x800, 0x87A, 0x8FB, 0x983, 0xA14, 0xAAE, 0xB50,
		0xBFC, 0xCB3, 0xD74, 0xE41, 0xF1A, 0x1000, 0x10F3, 0x11F6, 0x1307, 0x1429, 0x155B, 0x16A1,
		0x17F9, 0x1966, 0x1AE8, 0x1C82, 0x1E34, 0x2000, 0x21E7, 0x23EB, 0x260E, 0x2851, 0x2AB7, 0x2D41,
		0x2FF2, 0x32CC, 0x35D1, 0x3904, 0x3C68, 0x4000, 0x43CE, 0x47D6, 0x4C1C, 0x50A2, 0x556E, 0x5A82,
		0x5FE4, 0x6597, 0x6BA2, 0x7208, 0x78D0, 0x7FFF, 0x879C, 0x8FAC, 0x9837, 0xA144, 0xAADB, 0xB504, 
		0xBFC8, 0xCB2F, 0xD744, 0xE411, 0xF1A1, 0xFFFF	};
	 
	//convert pattern data	
	int m, note, notech1, notech2, notech3, notech4;
	unsigned char rows, ctrlb;
	bool retrig1,retrig2,retrig3,retrig4;
	unsigned char maxinstr = 0;
	char temp;
	int detune1 = 0;
	int detune2 = 0;
	int detune3 = 0;
	int detune4 = 0;	
	int ch1[257], ch2[257], ch3[257], ch4[257];
	unsigned char instr1[257], instr2[257], instr3[257], instr4[257];
	
	for (i = 0; i <= (uniqueptns)-1; i++) {
	
		if (isPatternUsed(i)) {
		
			OUTFILE << "ptn" << i << endl;
			ch1[0] = 0;
			ch2[0] = 0;
			ch3[0] = 0;		//tone/slide
			ch4[0] = 0;		//tone/noise
			instr1[0] = 0;
			instr2[0] = 0;
			instr3[0] = 0;
			instr4[0] = 0;
			
			fileoffset = ptnoffsetlist[i] + 9;
			
			for (rows = 1; rows <= ptnlengths[i]; rows++) {
			
				ch1[rows] = ch1[rows-1];
				ch2[rows] = ch2[rows-1];
				ch3[rows] = ch3[rows-1];
				ch4[rows] = ch4[rows-1];
				
				instr1[rows] = instr1[rows-1];
				instr2[rows] = instr2[rows-1];
				instr3[rows] = instr3[rows-1];
				instr4[rows] = instr4[rows-1];
				
				retrig1 = false;
				retrig2 = false;
				retrig3 = false;
				retrig4 = false;
				
				for (m = 0; m <= 3; m++) {
				
					INFILE.seekg(fileoffset, ios::beg);
					INFILE.read((&cp), 1);
					pp = static_cast<unsigned char>(cp);
					
					if (pp >= 128) {		//have compressed pattern data
					
						fileoffset++;
						
						if (pp != 128) {
						
							INFILE.seekg(fileoffset, ios::beg);
							INFILE.read((&temp), 1);
							temp = static_cast<unsigned char>(temp);
							
							if ((pp&1) == 1) {	//if bit 0 is set, it's note -> counter val.		
											
								if (temp > 78) {
									if (temp != 97) cout << "Note out of range in pattern " << +i << " row " << +rows << ", replaced with a rest\n";
									temp = 0;		//silence
								}
								
								note = notetab[static_cast<int>(temp)];
								if (m == 0) {
									ch1[rows] = note;
									retrig1 = true;
								}
								if (m == 1) {
									ch2[rows] = note;
									retrig2 = true;
								}
								if (m == 2) {
									ch3[rows] = note;
									retrig3 = true;
								}
								if (m == 3) {
									ch4[rows] = note;
									retrig4 = true;
								}
								
								fileoffset++;
								INFILE.seekg(fileoffset, ios::beg);	//read next byte
								INFILE.read((&temp), 1);
								temp = static_cast<unsigned char>(temp);
							}
							
							if ((pp&2) == 2) {				//if bit 1 is set, it's instrument
								
								if (temp > maxinstr) maxinstr = temp;
								if (m == 0) instr1[rows] = temp;
								if (m == 1) instr2[rows] = temp;
								if (m == 2) instr3[rows] = temp;
								if (m == 3) instr4[rows] = temp;
								
								fileoffset++;
								INFILE.seekg(fileoffset, ios::beg);	//read next byte
								INFILE.read((&temp), 1);
								temp = static_cast<unsigned char>(temp);
							}
							
							if ((pp&4) == 4) {				//if bit 2 is set, it's volume -> ignore
								fileoffset++;
								INFILE.seekg(fileoffset, ios::beg);	//read next byte
								INFILE.read((&temp), 1);
								temp = static_cast<unsigned char>(temp);
							}
							
							if ((pp&8) == 8 && temp == 0xb) {		//if bit 3 is set and value is $b (jump to order)
								fileoffset++;
								INFILE.seekg(fileoffset, ios::beg);	//read next byte
								INFILE.read((&temp), 1);
								temp = static_cast<unsigned char>(temp);
								looppoint = unsigned(temp*4);
								fileoffset++;
							
							}

							else if ((pp&8) == 8 && temp == 0xe) {		//if bit 3 is set and value is $e5x (finetune)
							
								fileoffset++;
								INFILE.seekg(fileoffset, ios::beg);	//read next byte
								INFILE.read((&temp), 1);
								temp = static_cast<unsigned char>(temp);
								
								if ((temp & 0xf0) == 0x50) {
									temp = (temp & 0xf) - 8;
									if (m == 0) detune1 = int(ch1[rows]/100) * temp;
									if (m == 0) detune2 = int(ch2[rows]/100) * temp;
									if (m == 0) detune3 = int(ch3[rows]/100) * temp;
									if (m == 0) detune4 = int(ch4[rows]/100) * temp;
								}
																
								fileoffset++;
							}
						} 
						
					} else {			//uncompressed pattern data
						
						//read notes
						temp = pp;
						if (temp > 78) {
							if (temp != 97) cout << "Note out of range in pattern " << +i << " row " << +rows << ", replaced with a rest\n";
							temp = 0;		//silence
						}
							
						note = notetab[static_cast<int>(temp)];
						if (m == 0) ch1[rows] = note;
						if (m == 1) ch2[rows] = note;
						if (m == 2) ch3[rows] = note;
						if (m == 3) ch4[rows] = note;
							
						fileoffset++;
						INFILE.seekg(fileoffset, ios::beg);	//read next byte
						INFILE.read((&temp), 1);
						temp = static_cast<unsigned char>(temp);
						
						
						//read instruments
						if (temp > maxinstr) maxinstr = temp;
						if (m == 0) instr1[rows] = temp;
						if (m == 1) instr2[rows] = temp;
						if (m == 2) instr3[rows] = temp;
						if (m == 3) instr4[rows] = temp;

						
						//read and ignore volume
						fileoffset++;
						INFILE.seekg(fileoffset, ios::beg);	//read next byte
						INFILE.read((&temp), 1);
						temp = static_cast<unsigned char>(temp);
						
					
						//read fx command
						fileoffset++;
						INFILE.seekg(fileoffset, ios::beg);	//read next byte
						INFILE.read((&temp), 1);
						temp = static_cast<unsigned char>(temp);
						pp = temp;
						
						//read fx parameter
						fileoffset++;
						INFILE.seekg(fileoffset, ios::beg);	//read next byte
						INFILE.read((&temp), 1);
						temp = static_cast<unsigned char>(temp);
						
						//evaluate fx
						if (pp == 0xb) looppoint = unsigned(temp*4);
						if (pp == 0xe && (temp & 0xf) == 0x50) {
							temp = (temp & 0xf) - 8;
							if (m == 0) detune1 = int(ch1[rows]/100) * temp;
							if (m == 0) detune2 = int(ch2[rows]/100) * temp;
							if (m == 0) detune3 = int(ch3[rows]/100) * temp;
							if (m == 0) detune4 = int(ch4[rows]/100) * temp;
						}
								
						//advance file pointer
						fileoffset++;
															
					}
				}
				
				if (ch1[rows] == 0) instr1[rows] = 0;
				if (ch2[rows] == 0) instr2[rows] = 0;
				if (ch3[rows] == 0) instr3[rows] = 0;
				if (ch4[rows] == 0) instr4[rows] = 0;
				
				notech1 = ch1[rows] + detune1;
				notech2 = ch2[rows] + detune2;
				notech3 = ch3[rows] + detune3;
				notech4 = ch4[rows] + detune4;
				
				ctrlb = 0;
				if ((ch4[rows] == ch4[rows-1]) && !retrig4) ctrlb = (ctrlb | 1);
				if ((ch3[rows] == ch3[rows-1]) && !retrig3) ctrlb = (ctrlb | 2);
				if ((ch2[rows] == ch2[rows-1]) && !retrig2) ctrlb = (ctrlb | 4);
				if ((ch1[rows] == ch1[rows-1]) && !retrig1) ctrlb = (ctrlb | 8);
				if (rows == 1) ctrlb = 0;
				
				OUTFILE << "\tdc.w $00" << hex << +ctrlb << "\t;ctrl word\n";
				if ((ctrlb & 1) == 0) OUTFILE << hex << "\tdc.w $" << +notech4 << "\n\tdc.l smp" << +instr4[rows] << endl;
				if ((ctrlb & 2) == 0) OUTFILE << hex << "\tdc.w $" << +notech3 << "\n\tdc.l smp" << +instr3[rows] << endl;
				if ((ctrlb & 4) == 0) OUTFILE << hex << "\tdc.w $" << +notech2 << "\n\tdc.l smp" << +instr2[rows] << endl;
				if ((ctrlb & 8) == 0) OUTFILE << hex << "\tdc.w $" << +notech1 << "\n\tdc.l smp" << +instr1[rows] << endl;
				
				detune1 = 0;
				detune2 = 0;
				detune3 = 0;
				detune4 = 0;

			}	
		OUTFILE << "\tdc.w $ffff\n\n";
		
		}
	
	}
	
	//define sequence loop point
	OUTFILE << hex << "sloop EQU sequence+$" << +looppoint << "\n\n";
	
	
	//extract and convert samples
	OUTFILE << "\n\teven\nsamples\nsmp0\n\tdc.b 0,$ff\n\tdc.l smp0\n\n";
	
	unsigned iheadersize,samplesize,csmpsize,j,loopstart,looplen,temph;
	unsigned char minvol;
	bool words, loop;
	char sraw[0xffff];
	unsigned char scon[0x4000];
	int debugh;
	
	fileoffset = ptnoffsetlist[uniqueptns] + ptnlengths[uniqueptns];	//point to beginning of instrument block
	
	for (i=1; i <= maxinstr; i++) {
	
		words = false;					//assume 8-bit sample data
		loop = false;
	
		INFILE.seekg(fileoffset, ios::beg);		//read instrument header size
		INFILE.read((&temp), 1);
		iheadersize = static_cast<unsigned>(temp);
		fileoffset++;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&temp), 1);
		temph = static_cast<unsigned>(temp);
		fileoffset += 3;				//skip upper word of header size
	
		iheadersize += (temph*256);
	
		if (arg == "-v") cout << hex << +fileoffset << "\t";
	
		for (j=0; j < 22; j++) {			//read instrument name
			INFILE.seekg(fileoffset, ios::beg);
			INFILE.read((&temp), 1);
			temp = static_cast<unsigned char>(temp);
			fileoffset++;
			if (arg == "-v") cout << temp;
		}
		if (arg == "-v") cout << "\t";

		fileoffset = fileoffset + iheadersize - 26;
		
		INFILE.seekg(fileoffset, ios::beg);		//read sample length
		INFILE.read((&temp), 1);
		samplesize = static_cast<unsigned char>(temp);
		fileoffset++;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&temp), 1);
		temph = static_cast<unsigned char>(temp);
		fileoffset++;
		samplesize += (temph*256);
		
		INFILE.seekg(fileoffset, ios::beg);		//read sample length upper word, should be 0
		INFILE.read((&temp), 1);
		temp = static_cast<unsigned char>(temp);
		if (temp != 0) cout << "Error: sample size > 64k\n";
		fileoffset++;
		INFILE.seekg(fileoffset, ios::beg);		//read sample length upper word, should be 0
		INFILE.read((&temp), 1);
		temp = static_cast<unsigned char>(temp);
		if (temp != 0) cout << "Error: sample size > 64k\n";
		fileoffset++;
		
		INFILE.seekg(fileoffset, ios::beg);		//read loop start
		INFILE.read((&temp), 1);
		loopstart = static_cast<unsigned char>(temp);
		fileoffset++;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&temp), 1);
		temph = static_cast<unsigned char>(temp);
		fileoffset += 3;
		loopstart += (temph*256);
		
		INFILE.seekg(fileoffset, ios::beg);		//read loop length
		INFILE.read((&temp), 1);
		looplen = static_cast<unsigned char>(temp);
		fileoffset++;
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&temp), 1);
		temph = static_cast<unsigned char>(temp);
		fileoffset += 5;				//skip loop length hi-word, volume, finetune
		looplen += (temph*256);
		
		INFILE.seekg(fileoffset, ios::beg);		//read loop length
		INFILE.read((&temp), 1);
		temph = static_cast<unsigned char>(temp);
		
		if ((temph & 1) == 1) loop = true;		//detect looping
//		if ((temph & 0x10) == 0x10) words = true;	//detect sample bit depth
		if ((temph & 0x10) == 0x10) {			//exit if 16-bit sample found, because 16-bit conversion doesn't work yet.
			cout << "Error: 16-bit sample data found.\n";
			return -1;
		}
		
		fileoffset += 4;				//skip irrelevant stuff
		
		if (arg == "-v") cout << hex << +fileoffset << "\t";
		for (j=0; j < 22; j++) {			//read sample name
			INFILE.seekg(fileoffset, ios::beg);
			INFILE.read((&temp), 1);
			temp = static_cast<unsigned char>(temp);
			fileoffset++;
			if (arg == "-v") cout <<	temp;
		}
		
		if (arg == "-v") cout << hex << "\t\tsample size 0x" << +samplesize << " bytes\n";
		unsigned char temp2,temp3;
		
		if (!words) {					//read in sample data			
			for (j=0; j < samplesize; j++) {	//8-bit
				INFILE.seekg(fileoffset, ios::beg);
				INFILE.read((&temp), 1);
				sraw[j] = static_cast<char>(temp);
				fileoffset++;
				//if (i==2) cout << +j << " ";
			}
		} else {
			for (j=0; j < samplesize; j+=2) {	//16-bit
				INFILE.seekg(fileoffset, ios::beg);
				INFILE.read((&temp), 1);
				temp2 = static_cast<char>(temp);
				fileoffset++;
				INFILE.seekg(fileoffset, ios::beg);
				INFILE.read((&temp), 1);
				temp3 = static_cast<char>(temp);
				
				debugh = (temp3*256)|temp2;
				cout << hex << +temp2 << "\t" << +temp3 <<  "\t" << +debugh << endl;
				
				sraw[j] = char((((temp3&0xff)*256)|temp2)/256)&0xff;
				fileoffset++;	
			}
			samplesize = unsigned(samplesize/2);
		}
		
		temp = 0;					//convert delta-based sample data to raw pcm
		for (j=0; j < samplesize; j++) {
			sraw[j] += temp;
			temp = sraw[j];
			if ((sraw[j] & 0x80) == 0x80) {		//convert to unsigned
				sraw[j] = (sraw[j] & 0x7f);
			} else {
				sraw[j] = (sraw[j] | 0x80);
			}  
		}
		
		if ((samplesize & 3) == 1) samplesize--;	//pad/truncate sample size so there's a multiple of 4 samples
		else if ((samplesize & 3) == 2) samplesize = samplesize -2;
		else if ((samplesize & 3) == 3) {
			samplesize++;
			sraw[samplesize-1] = sraw[samplesize-2];
		}
		csmpsize = unsigned(samplesize/4);		//downsample and convert raw pcm to digiplay68 format (11khz, 3-bit volume)

		for (j=0; j < samplesize; j++) {
			temph = reinterpret_cast<unsigned char&>(sraw[j]);
			temph = unsigned(temph/32)*4;
			scon[unsigned(j/4)] = (unsigned char)temph;
		}
		if ((csmpsize&1) == 0) csmpsize--;		//if converted sample size is even, make it odd

		for (j=0; j < csmpsize; j++) {			//minimize sample volume
			if (scon[j] < minvol) minvol = scon[j];
		}

		for (j=0; j < csmpsize; j++) {
			scon[j] = scon[j] - minvol;
		}
		
		OUTFILE << "smp" << +i;				//output sample to file
				
		unsigned n,pblk;
		pblk = unsigned(csmpsize/32);
		j = 0;
		for (n=0; n < pblk; n++) {
			OUTFILE << "\n\tdc.b ";
			for (m=0; m<32; m++) {
				OUTFILE << hex << "$" << +scon[j];
				j++;
				if (m != 31) OUTFILE << ",";
			}			
		}
		OUTFILE << "\n\tdc.b ";
		for (; j < csmpsize; j++) {
			OUTFILE << hex << "$" << +scon[j] << ",";
		}
		
		OUTFILE << "$ff\n";
		loopstart = unsigned(loopstart/4);
		if (!loop) OUTFILE << "\tdc.l smp0\n\n";
		else OUTFILE << hex << "\tdc.l smp" << +i << "+$" << +loopstart << "\n\n";	
		
	}

	cout << "Success!\n";

	INFILE.close();
	OUTFILE.close();
	return 0;
}


//check if a pattern exists in sequence
bool isPatternUsed(int patnum) {

int usage = false;

	for (fileoffset = 80; fileoffset < ((unsigned)songlength+80); fileoffset++) {
		INFILE.seekg(fileoffset, ios::beg);
		INFILE.read((&cp), 1);
		if (patnum == static_cast<unsigned char>(cp)) usage = true;
	}

	return(usage);
}