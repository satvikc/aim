{-|

Internal module that captures the abstract syntax of the assembly
language. It is desired that users of Aim do not have access to this
to avoid losing the type safety.

-}

{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Aim.Assembler.Language
       ( ProgramMonoid, BlockMonoid, CommentMonoid
       , Declaration
       , Arg(..), Statement(..), VarDec(..)
       , Commented(..), (<#>), (<!>)
       , Size(..), Signed(..), signed, unsigned
       , Constant(..)
       , word8, word16, word32, word64, word128, word256, char8
       , int8, int16, int32, int64, int128, int256
       ) where

import Data.Int              ( Int8, Int16, Int32, Int64     )
import Data.String
import Data.Text             ( Text                          )
import Data.Word             ( Word8, Word16, Word32, Word64 )


-- | A program for a given architecture.
type ProgramMonoid arch  = CommentMonoid (Declaration arch)

-- | A statement block for a given architecture
type BlockMonoid   arch  = CommentMonoid (Statement   arch)

-- | A declaration is either an array or a function definition.
data Declaration arch = Array    Text Size  (Signed [Integer])
                      | Function Text [VarDec]   --  parameters
                                      [VarDec]   --  local variables
                                      (BlockMonoid arch)
                      deriving Show

-- | An statement can take 0,1,2 or 3 arguments. The text field is the
-- neumonic of the instruction.
data Statement arch = S0 Text
                    | S1 Text Arg
                    | S2 Text Arg Arg
                    | S3 Text Arg Arg Arg deriving Show

-- | An argument of an assembly statement.
data Arg = Immediate Constant -- ^ An immediate value
         | Param     Int      -- ^ A parameter
         | Local     Int      -- ^ A local variable
         | Reg       Text     -- ^ A register
         | Indirect  Text
                     Size
                     Int       deriving Show

-- | A variable declaration.
data VarDec = VarDec (Signed Size) Text deriving Show

-- | An 8-bit unsigned integer.
word8  :: Word8  -> Arg
word8  = Immediate . I Size8 . unsigned . toInteger

-- | A 16-bit unsigned integer.
word16 :: Word16 -> Arg
word16 = Immediate . I Size16 . unsigned . toInteger

-- | A 32-bit unsigned integer.
word32 :: Word32 -> Arg
word32 = Immediate . I Size32 . unsigned . toInteger

-- | A 64-bit unsiged integer.
word64 :: Word64 -> Arg
word64 = Immediate . I Size64 . unsigned . toInteger

-- | A 128-bit unsigned integer.
word128 :: Integer -> Arg
word128 = Immediate . I Size128 . unsigned

-- | A 256-bit unsiged integer.
word256 :: Integer -> Arg
word256 = Immediate . I Size256 . unsigned

-- | Encode a character into its ascii equivalent.
char8 :: Char -> Arg
char8 = word8 . toEnum . fromEnum

-- | A signed 8-bit integer
int8 :: Int8 -> Arg
int8 = Immediate . I Size8 . signed . toInteger

-- | A signed 16-bit integer
int16 :: Int16 -> Arg
int16 = Immediate . I Size16 . signed . toInteger

-- | A signed 32-bit integer
int32 :: Int32 -> Arg
int32 = Immediate . I Size32 . signed . toInteger

-- | A signed 64-bit integer
int64 :: Int64 -> Arg
int64 = Immediate . I Size64 . signed . toInteger

-- | A signed 128-bit integer.
int128 :: Integer -> Arg
int128 = Immediate . I Size128 . signed

-- | A signed 256-bit integer.
int256 :: Integer -> Arg
int256 = Immediate . I Size256 . signed


--------------------- Constants ----------------------------------------


-- | A constant.
data Constant = I Size (Signed Integer)  -- ^ A signed integer
              | F Double                 -- ^ A floting point constant.
              deriving Show


-- | Different sizes that are available on the processor.
data Size = Size8
          | Size16
          | Size32
          | Size64
          | Size128
          | Size256
          | SizePtr  -- ^ Size of the pointer
          deriving Show

-- | Tags the value to distinguish between signed and unsigned
-- quantities.
data Signed a = S a
              | U a  deriving Show

-- | Create a signed object.
signed :: a -> Signed a
signed = S

-- | Create an unsigned object.
unsigned :: a -> Signed a
unsigned =  U

------------------ Commenting ------------------------------------------

-- | An element that can be tagged with a comment.
data Commented a = Comment (Maybe a) Text deriving Show

-- | The comments monoid
type CommentMonoid a = [Commented a]

instance Functor Commented where
  fmap f (Comment ma txt) = Comment (fmap f ma) txt

instance IsString (Commented a) where
  fromString = Comment Nothing . fromString

-- | Comment an object.
(<#>) :: a -> Text -> Commented a
(<#>) x = Comment (Just x)

-- | Comments first and then the object.
(<!>) :: Text -> a -> Commented a
(<!>) = flip (<#>)
