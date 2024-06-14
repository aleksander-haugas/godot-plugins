extends Node
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ##
##  AES implementation in GDscript                       (c) Aleksander Haugas 2024 / MIT Licence ##
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ##
##
## If you want to convince yourself that the Cipher function is working properly 
## internally (and you should!), NIST provide test vectors for AES (appendix C.1 of the standard).
##
## and the cipher output block should be
##
## 128-bit: 69 c4 e0 d8 6a 7b 04 30 d8 cd b7 80 70 b4 c5 5a
## 192-bit: dd a9 7c a4 86 4c df e0 6e af 70 a0 ec 0d 71 91
## 256-bit: 8e a2 b7 ca 51 67 45 bf ea fc 49 90 4b 49 60 89
##
func _ready():
	var plaintext = parse_hex_array("00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff")
	print_aes_128_vector(plaintext)
	print_aes_192_vector(plaintext)
	print_aes_256_vector(plaintext)
	
func parse_hex(value):
	return value.hex_to_int()

func parse_hex_array(hex_string):
	var hex_values = hex_string.split(" ")
	var result = []
	for value in hex_values:
		result.append(parse_hex(value))
	return result

func print_aes_128_vector(plaintext):
	var key128 = parse_hex_array("00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f")
	var cipher_text = Aes.cipher(plaintext, Aes.key_expansion(key128)).map(func(val):
		return hex_format(val)
	)
	print(join_array(cipher_text, " "))

func print_aes_192_vector(plaintext):
	var key192 = parse_hex_array("00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17")
	var cipher_text = Aes.cipher(plaintext, Aes.key_expansion(key192)).map(func(val):
		return hex_format(val)
	)
	print(join_array(cipher_text, " "))

func print_aes_256_vector(plaintext):
	var key256 = parse_hex_array("00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f")
	var cipher_text = Aes.cipher(plaintext, Aes.key_expansion(key256)).map(func(val):
		return hex_format(val)
	)
	print(join_array(cipher_text, " "))

# expanded key as hex words, as per FIPS-197§A
func hex_format(value: int) -> String:
	var hex_string = "%02X" % value
	return hex_string

func join_array(arr: Array, sep: String) -> String:
	return sep.join(arr).to_lower()
