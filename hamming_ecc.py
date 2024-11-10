# Ameer Shalabi (ameershalabi@gmail.com)
# Hamming code decoder and encoder
# both functions take binary string and return binary string
# input to the hamming_encode and hamming_decode is little endian

##### Useful functions
# create func to make sure no bits are lost
# if MSBs are 0s
def hex2bin(x):
    bin_len = 4*(len(x))
    bin_val=bin(int(x,16))[2:]
    if len(bin_val) != bin_len:
        bin_val=('0'*(bin_len-len(bin_val)))+bin_val
    return bin_val

# create func to make sure no bits are lost
# if MSBs are 0s
def bin2hex(x):
    hex_len = int((len(x))/4)
    hex_val=hex(int("0b"+x,2))
    if len(hex_val) != hex_len:
        hex_val=('0'*(hex_len-len(hex_val)))+hex_val
    return hex_val

# xor func for string
def str_xor(a="",b=""):
    if a != b:
        xor_o = '1'
    else:
        xor_o = '0'
    return xor_o

# little endian to big endian
def LE_2_BE(LE_data=""):
    BE_data=LE_data[::-1]
    return BE_data

# function that assigns a chat to location inside string
def str_assign(string,char,location):
   list1 = list(string)
   list1[location]=char
   str1 = ''.join(list1)
   return str1

def hamming_encode(data):
    ### STEP 1 : Find the number of parity bits needed 
    # get the length of data
    data_length = len(data)
    print(data)
    parity_v = "" # vector to hold parity values
    # init parity bits
    num_parity_bits = 0
    # loop over power of twos and compute the number of parities required
    # if the power of 2 os less than the data length + number of parity
    # bits needed + 1, then more parity bits are needed 
    while pow(2,num_parity_bits) < (data_length + num_parity_bits + 1):
        # increment number of parity bits if needed
        num_parity_bits = num_parity_bits + 1
    
    ##STEP 2 : add parity bits in their vector positions
    pwr_of_2 = 0 # variable to loop over powers of 2
    data_bit_idx = 0 # variable to hold current data bit index
    parity_mask = "" # new encoded vector with parity bits
    extended_data = "" # new encoded vector with parity bits
    # loop over encoded bit indicies (length of data + num of parity bits)
    for encoded_bit_index in range(0,data_length+num_parity_bits):
        # parity index is power of 2 - 1
        parity_index = pow(2,pwr_of_2)-1
        # if current position is not a power of 2
        if encoded_bit_index != parity_index:
            # store bit at current data index to the encoded bit index
            extended_data=extended_data+data[data_bit_idx]
            parity_mask = parity_mask+data[data_bit_idx]
            # increment data index
            data_bit_idx=data_bit_idx+1
        # if current position is a power of 2
        else:
            # add place holder to this current encoded bit index
            extended_data=extended_data+"0"
            parity_mask = parity_mask+"_"
            # increment next power of two to be checked
            pwr_of_2 = pwr_of_2 +1
    
    # print parity mask where "_" at each location there is a parity
    # usuful in debugging
    #print (parity_mask) 
    len_enc = len(extended_data)
    parity_bit_loc_arr=[] ### ADDITIONAL
    ##STEP 3 : generate parity bits and update their values
    # for every parity bit 
    for parity_bit in range(0,num_parity_bits):
        # get the position of the bit in the vector
        parity_position = pow(2,parity_bit)-1
        # default parity value, also value of parity before encoding
        parity_val = "0"
        parity_arr=[] ### ADDITIONAL
        # number of steps between parity offset
        step = pow(2,parity_bit+1)
        # for every bit starting after the parity position
        # with step between the parity offset
        for parity_offset in range(parity_position,len_enc,step):
            # for every number of offset bits
            for bit_offset in range(0,parity_position+1):
                # if bit index is within vector range
                if (parity_offset+bit_offset <= len_enc-1):
                    # if bit not at parity_position (avoid duplicating the parity bit val
                    # since it is initialized to 0 in the extended vectir)
                    parity_arr.append(parity_offset+bit_offset)
                    if parity_position != parity_offset+bit_offset:
                        # XOR bit at bit offset + parity offset with current value of parity
                        parity_val = str_xor(parity_val,extended_data[parity_offset+bit_offset])
        parity_v=parity_val+parity_v                
        
        ### ADDITIONAL
        parity_bit_loc=""
        parity_arr_loc=0
        bit_1_counter=0
        for i in range (0,524):
            if parity_arr[parity_arr_loc] == i :
                parity_bit_loc= '1' + parity_bit_loc
                bit_1_counter=bit_1_counter+1
                if parity_arr_loc < len(parity_arr)-1:
                    parity_arr_loc=parity_arr_loc+1
            else:
                parity_bit_loc= '0' +parity_bit_loc
        parity_bit_loc_arr.append(parity_bit_loc) ### ADDITIONAL
        extended_data = str_assign(extended_data,parity_val,parity_position)

    print(parity_v)
    # return encoded vector
    return (extended_data)

def hamming_decode(data):
    ### STEP 1 : Find the number of parity bits in the encoded data 
    # get the length of data
    data_length = len(data)
    #print (data)
    # init parity bits
    num_parity_bits = 0
    # loop over power of twos and compute the number of parities in the data
    # if the power of 2 os less than the data length + number of parity + 1, 
    # then there are more parity bits in the data 
    while pow(2,num_parity_bits) < (data_length + num_parity_bits + 1):
        # increment number of parity bits if needed
        num_parity_bits = num_parity_bits + 1
    
    ##STEP 2 : check the parity bits in the encoded data and correct errors
    # to match the input
    # each parity bit is check for error and stored in array.
    error_position = ""
    error_pos_int = 0
    error_detected = "0"
    ##STEP 2.1 : Check the parity bits and detect errors
    # for every parity bit 
    for parity_bit in range(0,num_parity_bits):
        # get the position of the bit in the vector
        parity_position = pow(2,parity_bit)-1
        # default parity value, also value of parity before encoding
        #parity_val = "0"
        # number of steps between parity offset
        step = pow(2,parity_bit+1)
        # for every bit starting after the parity position
        # with step between the parity offset
        for parity_offset in range(parity_position,data_length,step):
            # for every number of offset bits
            for bit_offset in range(0,parity_position+1):
                # if bit index is within vector range
                if (parity_offset+bit_offset <= data_length-1):
                    # if bit not at parity_position (avoid duplicating the parity bit val
                    # since it is initialized to 0 in the extended vectir)
                    if parity_position != parity_offset+bit_offset:
                    # XOR bit at bit offset + parity offset with current value of parity
                        parity_val = str_xor(parity_val,data[parity_offset+bit_offset])
                    else:
                        parity_val = data[parity_position]
        
        #mark where errors occur in error array in binary code
        if parity_val != "0":
            error_position = error_position+"1"
            error_pos_int = error_pos_int + parity_position+1
            print ("error at position : ", parity_position," expecting : ")
            error_detected = "0"
        else:
            error_position = error_position+"0"
    
    ##STEP 2.2 : Correct errors at each detection
    if error_detected == "1":
        correction_bit = str_xor(data[error_pos_int-1],"1")
        data = str_assign(data,correction_bit,error_pos_int-1)

    ##STEP 3 : Extract data from the 
    pwr_of_2 = 0 # variable to loop over powers of 2
    decoded_data = "" # new decoded vector with parity bits
    for encoded_bit_index in range(0,data_length):
        # parity index is power of 2 - 1
        parity_index = pow(2,pwr_of_2)-1
        # if current position is not a power of 2
        if encoded_bit_index != parity_index:
            # store bit at current data index to the encoded bit index
            decoded_data=decoded_data+data[encoded_bit_index]
        else:
           pwr_of_2 = pwr_of_2+1 

    return decoded_data

# create an inout array for testing
input_vectors = [
    "0x228570e7","0xe54a03c6","0xc0688a06","0x97e1d363","0x227ceda0","0x8695899a",
    "0x64e3d0db","0x02687e99","0xdc93d203","0x121b7212","0xe81fb670","0xe87d1ed6"]
# expected output of hamming encoder for each input in input array
expected_out = ["11010100001010010010101110000110100111",
    "11111101010101000101000000011110000110",
    "00111000000001100100010001010000000110",
    "00110010011111110000111010011011100011",
    "01010100001001101110011101101101100000",
    "11100000011010011010110001001101011010",
    "11011101010011110001111010000110011011",
    "01000001001001100100001111110101011001",
    "00101011110010011001111010010000000011",
    "11000010001000001101101110010000010010",
    "00111100100000011111110110110010110000",
    "11101101100001101110100011110111010110"
]

## quick test to check if encoding output matches expected
#for i in range(0, len(input_vectors)):
#    data = hex2bin(input_vectors[i])
#    ham = hamming_encode(data)
#    exp = expected_out[i]
#    if ham != exp:
#        print("Enc Mismatch : ", i)
#        print("exp : ",exp)
#        print("act : ",ham)
#    else:
#        print("Enc Match : ", i)
#
### quick test to check if decoding output matches expected
#for i in range(0, len(expected_out)):
#    data = hamming_decode(expected_out[i])
#    exp = hex2bin(input_vectors[i])
#    if data != exp:
#        print("Dec Mismatch : ", i)
#        print("exp : ",exp)
#        print("act : ",data)
#    else:
#        print("Dec Match : ", i)

v_512_h="10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010"
#v_512_b = hex2bin(v_512_h)
ham_o = hamming_encode(v_512_h)
# print hex in Big endian
print(bin2hex(LE_2_BE(ham_o)), len(ham_o))
