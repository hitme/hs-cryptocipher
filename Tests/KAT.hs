{-# LANGUAGE OverloadedStrings, CPP #-}
module KAT (katTests) where

-- unfortunately due to a bug in some version of cabal
-- there's no way to have a condition cpp-options in the cabal file
-- for test suite. to run test with AESni, uncomment the following
-- #define HAVE_AESNI

import Test.Framework.Providers.QuickCheck2 (testProperty)
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC

import Data.Word

import qualified Crypto.Cipher.AES.Haskell as AES
#ifdef HAVE_AESNI
import qualified Crypto.Cipher.AES.X86NI as AESNI
#endif
import qualified Crypto.Cipher.Blowfish as Blowfish
import qualified Crypto.Cipher.Camellia as Camellia
import qualified Crypto.Cipher.RC4 as RC4

encryptStream fi fc key plaintext = B.unpack $ snd $ fc (fi key) plaintext

encryptBlock fi fc key plaintext =
	let e = fi (B.pack key) in
	case e of
		Right k -> B.unpack $ fc k plaintext
		Left  e -> error e

wordify :: [Char] -> [Word8]
wordify = map (toEnum . fromEnum)

vectors_aes128_enc =
	[
	  ( [0x10, 0xa5, 0x88, 0x69, 0xd7, 0x4b, 0xe5, 0xa3,0x74,0xcf,0x86,0x7c,0xfb,0x47,0x38,0x59]
	  , B.replicate 16 0
	  , [0x6d,0x25,0x1e,0x69,0x44,0xb0,0x51,0xe0,0x4e,0xaa,0x6f,0xb4,0xdb,0xf7,0x84,0x65]
	  )
	, ( replicate 16 0
	  , B.replicate 16 0
	  , [0x66,0xe9,0x4b,0xd4,0xef,0x8a,0x2c,0x3b,0x88,0x4c,0xfa,0x59,0xca,0x34,0x2b,0x2e]
	  )
	, ( replicate 16 0
	  , B.replicate 16 1
	  , [0xe1,0x4d,0x5d,0x0e,0xe2,0x77,0x15,0xdf,0x08,0xb4,0x15,0x2b,0xa2,0x3d,0xa8,0xe0]
	  )
	, ( replicate 16 1
	  , B.replicate 16 2
	  , [0x17,0xd6,0x14,0xf3,0x79,0xa9,0x35,0x90,0x77,0xe9,0x55,0x77,0xfd,0x31,0xc2,0x0a]
	  )
	, ( replicate 16 2
	  , B.replicate 16 1
	  , [0x8f,0x42,0xc2,0x4b,0xee,0x6e,0x63,0x47,0x2b,0x16,0x5a,0xa9,0x41,0x31,0x2f,0x7c]
	  )
	, ( replicate 16 3
	  , B.replicate 16 2
	  , [0x90,0x98,0x85,0xe4,0x77,0xbc,0x20,0xf5,0x8a,0x66,0x97,0x1d,0xa0,0xbc,0x75,0xe3]
	  )
	]

vectors_aes192_enc =
	[
	  ( replicate 24 0
	  , B.replicate 16 0
	  , [0xaa,0xe0,0x69,0x92,0xac,0xbf,0x52,0xa3,0xe8,0xf4,0xa9,0x6e,0xc9,0x30,0x0b,0xd7]
	  )
	, ( replicate 24 0
	  , B.replicate 16 1
	  , [0xcf,0x1e,0xce,0x3c,0x44,0xb0,0x78,0xfb,0x27,0xcb,0x0a,0x3e,0x07,0x1b,0x08,0x20]
	  )
	, ( replicate 24 1
	  , B.replicate 16 2
	  , [0xeb,0x8c,0x17,0x30,0x90,0xc7,0x5b,0x77,0xd6,0x72,0xb4,0x57,0xa7,0x78,0xd9,0xd0]
	  )
	, ( replicate 24 2
	  , B.replicate 16 1
	  , [0xf2,0xf0,0xae,0xd8,0xcd,0xc9,0x21,0xca,0x4b,0x55,0x84,0x5d,0xa4,0x15,0x21,0xc2]
	  )
	, ( replicate 24 3
	  , B.replicate 16 2
	  , [0xca,0xcc,0x30,0x79,0xe4,0xb7,0x95,0x27,0x63,0xd2,0x55,0xd6,0x34,0x10,0x46,0x14]
	  )
	]

vectors_aes256_enc =
	[ ( replicate 32 0
	  , B.replicate 16 0
	  , [0xdc,0x95,0xc0,0x78,0xa2,0x40,0x89,0x89,0xad,0x48,0xa2,0x14,0x92,0x84,0x20,0x87]
	  )
	, ( replicate 32 0
	  , B.replicate 16 1
	  , [0x7b,0xc3,0x02,0x6c,0xd7,0x37,0x10,0x3e,0x62,0x90,0x2b,0xcd,0x18,0xfb,0x01,0x63]
	  )
	, ( replicate 32 1
	  , B.replicate 16 2
	  , [0x62,0xae,0x12,0xf3,0x24,0xbf,0xea,0x08,0xd5,0xf6,0x75,0xb5,0x13,0x02,0x6b,0xbf]
	  )
	, ( replicate 32 2
	  , B.replicate 16 1
	  , [0x00,0xf9,0xc7,0x44,0x4b,0xb0,0xcc,0x80,0x6c,0x7c,0x39,0xee,0x22,0x11,0xf1,0x46]
	  )
	, ( replicate 32 3
	  , B.replicate 16 2
	  , [0xb4,0x05,0x87,0x3e,0xa0,0x76,0x1b,0x9c,0xa9,0x9f,0x70,0xb0,0x16,0x16,0xce,0xb1]
	  )
	]

vectors_aes128_dec =
	[ ( replicate 16 0
	  , B.replicate 16 0
	  , [0x14,0x0f,0x0f,0x10,0x11,0xb5,0x22,0x3d,0x79,0x58,0x77,0x17,0xff,0xd9,0xec,0x3a]
	  )
	, ( replicate 16 0
	  , B.replicate 16 1
	  , [0x15,0x6d,0x0f,0x85,0x75,0xd5,0x33,0x07,0x52,0xf8,0x4a,0xf2,0x72,0xff,0x30,0x50]
	  )
	, ( replicate 16 1
	  , B.replicate 16 2
	  , [0x34,0x37,0xd6,0xe2,0x31,0xd7,0x02,0x41,0x9b,0x51,0xb4,0x94,0x72,0x71,0xb6,0x11]
	  )
	, ( replicate 16 2
	  , B.replicate 16 1
	  , [0xe3,0xcd,0xe2,0x37,0xc8,0xf2,0xd9,0x7b,0x8d,0x79,0xf9,0x17,0x1d,0x4b,0xda,0xc1]
	  )
	, ( replicate 16 3
	  , B.replicate 16 2
	  , [0x5b,0x94,0xaa,0xed,0xd7,0x83,0x99,0x8c,0xd5,0x15,0x35,0x35,0x18,0xcc,0x45,0xe2]
	  )
	]

vectors_aes192_dec =
	[
	  ( replicate 24 0
	  , B.replicate 16 0
	  , [0x13,0x46,0x0e,0x87,0xa8,0xfc,0x02,0x3e,0xf2,0x50,0x1a,0xfe,0x7f,0xf5,0x1c,0x51]
	  )
	, ( replicate 24 0
	  , B.replicate 16 1
	  , [0x92,0x17,0x07,0xc3,0x3d,0x1c,0xc5,0x96,0x7d,0xa5,0x1d,0xbb,0xb0,0x66,0xb2,0x6c]
	  )
	, ( replicate 24 1
	  , B.replicate 16 2
	  , [0xee,0x92,0x97,0xc6,0xba,0xe8,0x26,0x4d,0xff,0x08,0x0e,0xbb,0x1e,0x74,0x11,0xc1]
	  )
	, ( replicate 24 2
	  , B.replicate 16 1
	  , [0x49,0x67,0xdf,0x70,0xd2,0x9e,0x9a,0x7f,0x5d,0x7c,0xb9,0xc1,0x20,0xc3,0x8a,0x71]
	  )
	, ( replicate 24 3
	  , B.replicate 16 2
	  , [0x74,0x38,0x62,0x42,0x6b,0x56,0x7f,0xd5,0xf0,0x1d,0x1b,0x59,0x56,0x01,0x26,0x29]
	  )
	]

vectors_aes256_dec =
	[ ( replicate 32 0
	  , B.replicate 16 0
	  , [0x67,0x67,0x1c,0xe1,0xfa,0x91,0xdd,0xeb,0x0f,0x8f,0xbb,0xb3,0x66,0xb5,0x31,0xb4]
	  )
	, ( replicate 32 0
	  , B.replicate 16 1
	  , [0xcc,0x09,0x21,0xa3,0xc5,0xca,0x17,0xf7,0x48,0xb7,0xc2,0x7b,0x73,0xba,0x87,0xa2]
	  )
	, ( replicate 32 1
	  , B.replicate 16 2
	  , [0xc0,0x4b,0x27,0x90,0x1a,0x50,0xcf,0xfa,0xf1,0xbb,0x88,0x9f,0xc0,0x92,0x5e,0x14]
	  )
	, ( replicate 32 2
	  , B.replicate 16 1
	  , [0x24,0x61,0x53,0x5d,0x16,0x1c,0x15,0x39,0x88,0x32,0x77,0x29,0xc5,0x8c,0xc0,0x3a]
	  )
	, ( replicate 32 3
	  , B.replicate 16 2
	  , [0x30,0xc9,0x1c,0xce,0xfe,0x89,0x30,0xcf,0xff,0x31,0xdb,0xcc,0xfc,0x11,0xc5,0x23]
	  )
	]

aes128InitKey = AES.initKey128
aes192InitKey = AES.initKey192
aes256InitKey = AES.initKey256

vectors_rc4 =
	[ (wordify "Key", "Plaintext", [ 0xBB,0xF3,0x16,0xE8,0xD9,0x40,0xAF,0x0A,0xD3 ])
	, (wordify "Wiki", "pedia", [ 0x10,0x21,0xBF,0x04,0x20 ])
	, (wordify "Secret", "Attack at dawn", [ 0x45,0xA0,0x1F,0x64,0x5F,0xC3,0x5B,0x38,0x35,0x52,0x54,0x4B,0x9B,0xF5 ])
	]

vectors_camellia128 =
	[ 
	  ( replicate 16 0
	  , B.replicate 16 0
	  , [0x3d,0x02,0x80,0x25,0xb1,0x56,0x32,0x7c,0x17,0xf7,0x62,0xc1,0xf2,0xcb,0xca,0x71]
	  )
	, ( [0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10]
	  , B.pack [0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10]
	  , [0x67,0x67,0x31,0x38,0x54,0x96,0x69,0x73,0x08,0x57,0x06,0x56,0x48,0xea,0xbe,0x43]
	  )
	]

vectors_camellia192 =
	[
	  ( [0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10,0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77]
	  , B.pack [0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10]
	  ,[0xb4,0x99,0x34,0x01,0xb3,0xe9,0x96,0xf8,0x4e,0xe5,0xce,0xe7,0xd7,0x9b,0x09,0xb9]
	  )
	]

vectors_camellia256 =
	[
	  ( [0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10
	    ,0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff]
	  , B.pack [0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef,0xfe,0xdc,0xba,0x98,0x76,0x54,0x32,0x10]
	  , [0x9a,0xcc,0x23,0x7d,0xff,0x16,0xd7,0x6c,0x20,0xef,0x7c,0x91,0x9e,0x3a,0x75,0x09]
	  )
	]

vectors_blowfish =
    [
      ( replicate 8 0
      , B.replicate 8 0
      , [0x4e,0xf9,0x97,0x45,0x61,0x98,0xDD,0x78]
      )
    , ( replicate 8 255
      , B.replicate 8 255
      , [0x51,0x86,0x6F,0xD5,0xB8,0x5E,0xCB,0x8A]
      )
    , ( [0x7C,0xA1,0x10,0x45,0x4A,0x1A,0x6E,0x57]
      , B.pack [0x01,0xA1,0xD6,0xD0,0x39,0x77,0x67,0x42]
      , [0x59,0xC6,0x82,0x45,0xEB,0x05,0x28,0x2B]
      )
    ]

vectors =
	[ ("RC4",        vectors_rc4,         encryptStream RC4.initCtx RC4.encrypt)
	-- AES haskell implementation
	, ("AES 128 Enc", vectors_aes128_enc,  encryptBlock aes128InitKey AES.encrypt)
	, ("AES 192 Enc", vectors_aes192_enc,  encryptBlock aes192InitKey AES.encrypt)
	, ("AES 256 Enc", vectors_aes256_enc,  encryptBlock aes256InitKey AES.encrypt)
	, ("AES 128 Dec", vectors_aes128_dec,  encryptBlock aes128InitKey AES.decrypt)
	, ("AES 192 Dec", vectors_aes192_dec,  encryptBlock aes192InitKey AES.decrypt)
	, ("AES 256 Dec", vectors_aes256_dec,  encryptBlock aes256InitKey AES.decrypt)
#ifdef HAVE_AESNI
	-- AES ni implementation
	, ("AESNI 128 Enc", vectors_aes128_enc,  encryptBlock (Right . AESNI.initKey128) AESNI.encrypt)
	, ("AESNI 128 Dec", vectors_aes128_dec,  encryptBlock (Right . AESNI.initKey128) AESNI.decrypt)
#endif
    -- Blowfish implementation
    , ("Blowfish",   vectors_blowfish,    encryptBlock Blowfish.initKey Blowfish.encrypt)
	-- Camellia implementation
	, ("Camellia",   vectors_camellia128, encryptBlock Camellia.initKey128 Camellia.encrypt)
	]

katTests = map makeTests vectors
	where makeTests (name, v, f) = testProperty name (and $ map makeTest v)
		where makeTest (key,plaintext,expected) = assertEq expected $ f key plaintext

assertEq expected got
	| expected == got = True
	| otherwise       = error ("expected: " ++ show expected ++ " got: " ++ show got)
