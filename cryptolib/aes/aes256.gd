@tool
class_name Aes extends Node
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ##
##  AES implementation in GDscript                       (c) Aleksander Haugas 2024 / MIT Licence ##
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ##
## 
##  AES (Rijndael cipher) encryption routines reference implementation,
## 
##  This is an annotated direct implementation of FIPS 197, without any optimisations. It is
##  intended to aid understanding of the algorithm rather than for production use.
## 
##  See csrc.nist.gov/publications/fips/fips197/fips-197.pdf
## 

# s_box is pre-computed multiplicative inverse in GF(2^8) used in subBytes and keyExpansion [§5.1.1]
const s_box = [
	0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
	0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
	0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
	0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
	0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
	0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
	0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
	0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
	0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
	0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
	0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
	0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
	0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
	0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
	0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
	0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
]

const r_sbox = [
	0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
	0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
	0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
	0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
	0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
	0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
	0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
	0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
	0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
	0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
	0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
	0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
	0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
	0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
	0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
	0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d,
]

# r_con is Round Constant used for the Key Expansion [1st col is 2^(r-1) in GF(2^8)] [§5.2]
const r_con = [
	[ 0x00, 0x00, 0x00, 0x00 ],
	[ 0x01, 0x00, 0x00, 0x00 ],
	[ 0x02, 0x00, 0x00, 0x00 ],
	[ 0x04, 0x00, 0x00, 0x00 ],
	[ 0x08, 0x00, 0x00, 0x00 ],
	[ 0x10, 0x00, 0x00, 0x00 ],
	[ 0x20, 0x00, 0x00, 0x00 ],
	[ 0x40, 0x00, 0x00, 0x00 ],
	[ 0x80, 0x00, 0x00, 0x00 ],
	[ 0x1b, 0x00, 0x00, 0x00 ],
	[ 0x36, 0x00, 0x00, 0x00 ],
]

##
## AES Cipher function: encrypt (input) state with Rijndael algorithm [§5.1];
## applies Nr rounds (10/12/14) using key schedule w for (add round key) stage.
##
## Cipher is the main function that encrypts the PlainText.
## round_key is of len 240 chars.
##
## @param   {number[]}   input - 16-byte (128-bit) input state array.
## @param   {number[][]} w - Key schedule as 2D byte-array (Nr+1 × Nb bytes).
## @returns {number[]}   Encrypted output state array.
##
static func cipher(input: Array, w: Array) -> Array:
	var Nb = 4 # block size (in words): no of columns in state (fixed at 4 for AES)
	var Nr = w.size() / Nb - 1 # no of rounds: 10/12/14 for 128/192/256-bit keys
	var state = [[], [], [], []] # initialise 4×Nb byte-array 'state' with input [§3.4]
	
	for i in range(4 * Nb):
		state[i % 4].append(input[i])
	
	state = Aes.add_round_key(state, w, 0, Nb)
	
	for i in range(1, Nr):
		state = Aes.sub_bytes(state, Nb)
		state = Aes.shift_rows(state, Nb)
		state = Aes.mix_columns(state, Nb)
		state = Aes.add_round_key(state, w, i, Nb)
	
	state = Aes.sub_bytes(state, Nb)
	state = Aes.shift_rows(state, Nb)
	state = Aes.add_round_key(state, w, Nr, Nb)
	
	var output = [] # convert state to 1-d array before returning [§3.4]
	
	for i in range(4 * Nb):
		output.append(state[i % 4][int(i / 4)])  # Usando int() para conversión
	
	return output

##
## Perform key expansion to generate a key schedule from a cipher key [§5.2].
##
## @param   {number[]}   key - Cipher key as 16/24/32-byte array.
## @returns {number[][]} Expanded key schedule as 2D byte-array (Nr+1 × Nb bytes).
##
static func key_expansion(key: Array) -> Array:
	var Nb = 4 # block size (in words): no of columns in state (fixed at 4 for AES)
	var Nk = key.size() / 4 # key length (in words): 4/6/8 for 128/192/256-bit keys
	var Nr = Nk + 6 # no of rounds: 10/12/14 for 128/192/256-bit keys
	
	var w = []
	# initialise first Nk words of expanded key with cipher key
	for i in range(Nk):
		var r = [key[4 * i], key[4 * i + 1], key[4 * i + 2], key[4 * i + 3]]
		w.append(r)
	# expand the key into the remainder of the schedule
	for i in range(Nk, Nb * (Nr + 1)):
		var temp = w[i - 1].duplicate()
		# each Nk'th word has extra transformation
		if i % Nk == 0:
			temp = Aes.sub_word(Aes.rot_word(temp))
			temp[0] ^= r_con[int(i / Nk)][0]  # Used int() for conversion
		# 256-bit key has subWord applied every 4th word
		elif Nk > 6 and i % Nk == 4:
			temp = Aes.sub_word(temp)
		var r = []
		# xor w[i] with w[i-1] and w[i-Nk]
		for j in range(4):
			r.append(w[i - Nk][j] ^ temp[j])
		w.append(r)
	
	return w
##
## Apply SBox to state S [§5.1.1]
## The SubBytes Function Substitutes the values in the
## state matrix with values in an s_box.
##
## @private
##
static func sub_bytes(s: Array, Nb: int) -> Array:
	for r in range(4):
		for c in range(Nb):
			s[r][c] = s_box[s[r][c]]
	return s
##
## Shift row r of state S left by r bytes [§5.1.2]
## The shift_rows() function shifts the rows in the state to the left.
## Each row is shifted with different offset.
## Offset = Row number. So the first row is not shifted.
##
## @private
##
static func shift_rows(s: Array, Nb: int) -> Array:
	var t = []
	for r in range(4):
		for c in range(Nb):
			t.append(s[r][(c + r) % Nb]) # shift into temp copy
		for c in range(Nb):
			s[r][c] = t[c] # and copy back
		t.clear()
	# note that this will work for Nb=4,5,6, but not 7,8 (always 4 for AES):
	return s # see asmaes.sourceforge.net/rijndael/rijndaelImplementation.pdf
##
## Combine bytes of each col of state S [§5.1.3]
## MixColumns function mixes the columns of the state matrix
## @private
##
static func mix_columns(s: Array, Nb: int) -> Array:
	for c in range(Nb):
		var a = []
		var b = []
		for r in range(4):
			a.append(s[r][c])
			b.append((s[r][c] << 1) ^ 0x011b if s[r][c] & 0x80 else s[r][c] << 1)
		s[0][c] = b[0] ^ a[1] ^ b[1] ^ a[2] ^ a[3]
		s[1][c] = a[0] ^ b[1] ^ a[2] ^ b[2] ^ a[3]
		s[2][c] = a[0] ^ a[1] ^ b[2] ^ a[3] ^ b[3]
		s[3][c] = a[0] ^ b[0] ^ a[1] ^ a[2] ^ b[3]
	return s
##
## Xor Round Key into state S [§5.1.4]
## @private
##
static func add_round_key(state: Array, w: Array, rnd: int, Nb: int) -> Array:
	for r in range(4):
		for c in range(Nb):
			state[r][c] ^= (w[rnd * 4 + c][r])
	return state
##
## Apply SBox to 4-byte word w
## @private
##
static func sub_word(w: Array) -> Array:
	for i in range(4):
		w[i] = s_box[w[i]]
	return w
##
## Rotate 4-byte word w left by one byte
## @private
##	
static func rot_word(w: Array) -> Array:
	var tmp = w[0]
	for i in range(3):
		w[i] = w[i + 1]
	w[3] = tmp
	return w
