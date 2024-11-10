--------------------------------------------------------------------------------
-- Title       : Hamming Encoding block fore 512b data
-- Project     : ECC
--------------------------------------------------------------------------------
-- File        : hamming_encoder.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 24 12:33:34 2024
-- Last update : Sun Nov 10 14:43:29 2024
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2024 User Company Name
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.hamming_pkg.all;

entity hamming_encoder is
  port (
    clk       : in  std_logic;
    n_arst    : in  std_logic;
    --ready_i   : in  std_logic; -- removed for now
    --valid_i   : in  std_logic; -- removed for now
    data_i    : in  std_logic_vector(511 downto 0);
    --ready_o   : out std_logic; -- removed for now
    --valid_o   : out std_logic; -- removed for now
    encoded_o : out std_logic_vector(521 downto 0)
  );

end entity hamming_encoder;

architecture arch of hamming_encoder is

  constant w_data_c         : integer := 512;
  constant n_parity_const   : integer := num_parity_bits(w_data_c); --hamming_pkg_func
  constant w_enc_data_const : integer := w_data_c + n_parity_const;

  -- array to hold parity bit positions
  type parity_positions is array (0 to n_parity_const-1) of integer range 0 to 2**n_parity_const;
  signal parity_pos_arr  : parity_positions;
  signal parity_step_arr : parity_positions;

  signal encoded_vector            : std_logic_vector(w_enc_data_const-1 downto 0);
  signal parities                  : std_logic_vector(n_parity_const-1 downto 0);
  signal encoded_vector_w_parities : std_logic_vector(w_enc_data_const-1 downto 0);

  -- create vectors to hold bits for each parity, lengths are different
  -- for each parity bit
  signal parity_0_bit_vector   : std_logic_vector(260 downto 0);
  signal parity_1_bit_vector   : std_logic_vector(260 downto 0);
  signal parity_3_bit_vector   : std_logic_vector(259 downto 0);
  signal parity_7_bit_vector   : std_logic_vector(258 downto 0);
  signal parity_15_bit_vector  : std_logic_vector(255 downto 0);
  signal parity_31_bit_vector  : std_logic_vector(255 downto 0);
  signal parity_63_bit_vector  : std_logic_vector(255 downto 0);
  signal parity_127_bit_vector : std_logic_vector(255 downto 0);
  signal parity_255_bit_vector : std_logic_vector(255 downto 0);
  signal parity_511_bit_vector : std_logic_vector(10 downto 0);

  signal count_1s_tst : natural;

  -- first register block (rb1_*)
  signal rb1_encoded_vector_r : std_logic_vector(w_enc_data_const-1 downto 0);
  signal rb1_parity_pos_arr_r : parity_positions;

  signal parity_0_vector_256_bits : std_logic_vector(255 downto 0);
  signal parity_0_vector_4_bits   : std_logic_vector(3 downto 0);

  signal parity_1_vector_256_bits : std_logic_vector(255 downto 0);
  signal parity_1_vector_4_bits   : std_logic_vector(3 downto 0);

  signal parity_3_vector_256_bits : std_logic_vector(255 downto 0);
  signal parity_3_vector_4_bits   : std_logic_vector(3 downto 0);

  signal parity_7_vector_256_bits : std_logic_vector(255 downto 0);
  signal parity_7_256_257_bit : std_logic;

  signal parity_511_vector_8_bits : std_logic_vector(7 downto 0);

  -- second register block (rb2_*)
  signal rb2_encoded_vector_r : std_logic_vector(w_enc_data_const-1 downto 0);

begin

  -- generate the parity positions 
  gen_parity_position_arr : for parity in 0 to n_parity_const-1 generate
    parity_pos_arr(parity)  <= 2**parity - 1;
    parity_step_arr(parity) <= 2**(parity + 1);
  end generate gen_parity_position_arr;

  -- create the encoded array with parity = '0'
  create_init_encoded_vector_proc : process (data_i,parity_pos_arr)
    variable parity_idx_v : integer range 0 to n_parity_const-1;
    variable data_idx_v   : integer range 0 to w_data_c-1;
    variable vector_enc_v : std_logic_vector(w_enc_data_const-1 downto 0);
  begin
    -- set parity index
    parity_idx_v := 0;
    -- set data index 
    data_idx_v := 0;
    data_loop : for bit_idx in 0 to w_enc_data_const-1 loop
      -- if current bit index is equal to a parity position
      if (bit_idx = parity_pos_arr(parity_idx_v)) then
        -- assign parity bit as '0'
        vector_enc_v(bit_idx) := '0';
        -- increnment parity index to get next parity position
        -- from parity position array
        if parity_idx_v < n_parity_const-1 then
          parity_idx_v := parity_idx_v + 1;
        end if;
      else
        -- if bit index is not parity position, get data from 
        -- input vector at data index
        vector_enc_v(bit_idx) := data_i(data_idx_v);
        -- increment data index to get the next data bit from
        -- data vector
        if data_idx_v < w_data_c-1 then
          data_idx_v := data_idx_v + 1;
        end if;
      end if;
    end loop data_loop;
    -- assign resulting vector as the encoded vector
    encoded_vector <= vector_enc_v;
  end process create_init_encoded_vector_proc;

  reg_block_1_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      rb1_encoded_vector_r <= (others => '0');
      rb1_parity_pos_arr_r <= (others => 0);
    elsif rising_edge(clk) then
      rb1_encoded_vector_r <= encoded_vector;
      rb1_parity_pos_arr_r <= parity_pos_arr;
    end if;
  end process reg_block_1_proc;


  generate_parity_val_proc : process (rb1_encoded_vector_r)
    variable parity_0_vector_bit_idx_v   : integer;
    variable parity_1_vector_bit_idx_v   : integer;
    variable parity_3_vector_bit_idx_v   : integer;
    variable parity_7_vector_bit_idx_v   : integer;
    variable parity_15_vector_bit_idx_v  : integer;
    variable parity_31_vector_bit_idx_v  : integer;
    variable parity_63_vector_bit_idx_v  : integer;
    variable parity_127_vector_bit_idx_v : integer;
    variable parity_255_vector_bit_idx_v : integer;
    variable parity_511_vector_bit_idx_v : integer;

  begin

    parity_0_vector_bit_idx_v   := 0;
    parity_1_vector_bit_idx_v   := 0;
    parity_3_vector_bit_idx_v   := 0;
    parity_7_vector_bit_idx_v   := 0;
    parity_15_vector_bit_idx_v  := 0;
    parity_31_vector_bit_idx_v  := 0;
    parity_63_vector_bit_idx_v  := 0;
    parity_127_vector_bit_idx_v := 0;
    parity_255_vector_bit_idx_v := 0;
    parity_511_vector_bit_idx_v := 0;

    -- to generate each parity bit, the placemnt constants are used to determine which
    -- bits are XORed to generate the parity. Those bits are seperated into a vector
    -- containing the bits to be XORed to generate parity

    --=== parity 0 vector (261 bits) ===--
    generate_partry_0_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_0_loc_placement(b) = '1' then
        parity_0_bit_vector(parity_0_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_0_vector_bit_idx_v                      := parity_0_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_0_vector;

    --=== parity 1 vector (261 bits) ===--
    generate_partry_1_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_1_loc_placement(b) = '1' then
        parity_1_bit_vector(parity_1_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_1_vector_bit_idx_v                      := parity_1_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_1_vector;

    --=== parity 3 vector (260 bits) ===--
    generate_partry_3_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_3_loc_placement(b) = '1' then
        parity_3_bit_vector(parity_3_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_3_vector_bit_idx_v                      := parity_3_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_3_vector;

    --=== parity 7 vector (259 bits) ===--
    generate_partry_7_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_7_loc_placement(b) = '1' then
        parity_7_bit_vector(parity_7_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_7_vector_bit_idx_v                      := parity_7_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_7_vector;

    --=== parity 15 vector (256 bits) ===--
    generate_partry_15_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_15_loc_placement(b) = '1' then
        parity_15_bit_vector(parity_15_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_15_vector_bit_idx_v                       := parity_15_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_15_vector;

    --=== parity 31 vector (256 bits) ===--
    generate_partry_31_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_31_loc_placement(b) = '1' then
        parity_31_bit_vector(parity_31_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_31_vector_bit_idx_v                       := parity_31_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_31_vector;

    --=== parity 63 vector (256 bits) ===--
    generate_partry_63_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_63_loc_placement(b) = '1' then
        parity_63_bit_vector(parity_63_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_63_vector_bit_idx_v                       := parity_63_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_63_vector;

    --=== parity 127 vector (256 bits) ===--
    generate_partry_127_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_127_loc_placement(b) = '1' then
        parity_127_bit_vector(parity_127_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_127_vector_bit_idx_v                        := parity_127_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_127_vector;

    --=== parity 255 vector (256 bits) ===--
    generate_partry_255_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_255_loc_placement(b) = '1' then
        parity_255_bit_vector(parity_255_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_255_vector_bit_idx_v                        := parity_255_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_255_vector;

    --=== parity 255 vector (256 bits) ===--
    generate_partry_511_vector : for b in 0 to encoded_vector'length - 1 loop
      if parity_511_loc_placement(b) = '1' then
        parity_511_bit_vector(parity_511_vector_bit_idx_v) <= rb1_encoded_vector_r(b);
        parity_511_vector_bit_idx_v                        := parity_511_vector_bit_idx_v+1;
      end if;
    end loop generate_partry_511_vector;

  end process generate_parity_val_proc;

  -- To avoid long series of XOR gates, the parity vectors are split into vectors
  -- of lengths that are power of 2 to create complete XOR binary trees. This will
  -- minimize the data path of each parity bit and reduce the overall number of logic
  -- cells needed to generate the bits
  -- generate parity 0 : two xor binary trees (256 + 4) + MSB
  parity_0_vector_256_bits <= parity_0_bit_vector(255 downto 0);
  parity_0_vector_4_bits   <= parity_0_bit_vector(259 downto 256);
  parities(0)              <= generate_xor_tree_logic(parity_0_vector_256_bits) xor
    generate_xor_tree_logic(parity_0_vector_4_bits) xor
    parity_0_bit_vector(260);

  -- generate parity 1 : two xor binary trees (256 + 4) + MSB
  parity_1_vector_256_bits <= parity_1_bit_vector(255 downto 0);
  parity_1_vector_4_bits   <= parity_1_bit_vector(259 downto 256);
  parities(1)              <= generate_xor_tree_logic(parity_1_vector_256_bits) xor
    generate_xor_tree_logic(parity_1_vector_4_bits) xor
    parity_1_bit_vector(260);

  -- generate parity 3 : two xor binary trees (256 + 4)
  parity_3_vector_256_bits <= parity_3_bit_vector(255 downto 0);
  parity_3_vector_4_bits   <= parity_3_bit_vector(259 downto 256);
  parities(2)              <= generate_xor_tree_logic(parity_3_vector_256_bits) xor
    generate_xor_tree_logic(parity_3_vector_4_bits);

  -- generate parity 3 : one xor binary trees (256) + 3 xor series
  parity_7_vector_256_bits <= parity_7_bit_vector(255 downto 0);
  parity_7_256_257_bit     <= parity_7_bit_vector(256) xor parity_7_bit_vector(257);
  parities(3)              <= generate_xor_tree_logic(parity_7_vector_256_bits) xor
  parity_7_256_257_bit xor
  parity_7_bit_vector(258);

  -- generate parity 15 : one xor binary trees (256)
  parities(4) <= generate_xor_tree_logic(parity_15_bit_vector);

  -- generate parity 31 : one xor binary trees (256)
  parities(5) <= generate_xor_tree_logic(parity_31_bit_vector);

  -- generate parity 63 : one xor binary trees (256)
  parities(6) <= generate_xor_tree_logic(parity_63_bit_vector);

  -- generate parity 127 : one xor binary trees (256)
  parities(7) <= generate_xor_tree_logic(parity_127_bit_vector);

  -- generate parity 255 : one xor binary trees (256)
  parities(8) <= generate_xor_tree_logic(parity_255_bit_vector);

  -- generate parity 255 : one xor binary trees (8) + 3 xor series
  parity_511_vector_8_bits <= parity_511_bit_vector(7 downto 0);
  parities(9)              <= generate_xor_tree_logic(parity_511_vector_8_bits) xor
    parity_511_bit_vector(8) xor parity_511_bit_vector(9) xor parity_511_bit_vector(10);

  generate_encoded_w_parities : process (
      parities,
      rb1_encoded_vector_r,
      rb1_parity_pos_arr_r)
  begin
    encoded_vector_w_parities <= rb1_encoded_vector_r;
    add_parities_to_encoded_vector : for parity_pos in 0 to n_parity_const-1 loop
      encoded_vector_w_parities(rb1_parity_pos_arr_r(parity_pos)) <= parities(parity_pos);
    end loop add_parities_to_encoded_vector;
  end process generate_encoded_w_parities;

  reg_block_2_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      rb2_encoded_vector_r <= (others => '0');
    elsif rising_edge(clk) then
      rb2_encoded_vector_r <= encoded_vector_w_parities;
    end if;
  end process reg_block_2_proc;

  encoded_o <= rb2_encoded_vector_r;

end arch;

