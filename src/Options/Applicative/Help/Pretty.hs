{-# LANGUAGE CPP #-}
module Options.Applicative.Help.Pretty
  ( module Text.PrettyPrint.ANSI.Leijen
  , (.$.)
  , groupOrNestLine
  , altSep
  , hangAtIfOver
  ) where

import           Control.Applicative
#if !MIN_VERSION_base(4,11,0)
import           Data.Semigroup ((<>))
#endif

import           Text.PrettyPrint.ANSI.Leijen hiding ((<$>), (<>), columns)
import           Text.PrettyPrint.ANSI.Leijen.Internal (Doc (..), flatten)
import qualified Text.PrettyPrint.ANSI.Leijen as PP

import           Prelude

(.$.) :: Doc -> Doc -> Doc
(.$.) = (PP.<$>)


-- | Apply the function if we're not at the
--   start of our nesting level.
ifNotAtRoot :: (Doc -> Doc) -> Doc -> Doc
ifNotAtRoot =
  ifElseAtRoot id

-- | Apply the function if we're not at the
--   start of our nesting level.
ifAtRoot :: (Doc -> Doc) -> Doc -> Doc
ifAtRoot =
  flip ifElseAtRoot id

-- | Apply the function if we're not at the
--   start of our nesting level.
ifElseAtRoot :: (Doc -> Doc) -> (Doc -> Doc) -> Doc -> Doc
ifElseAtRoot f g doc =
  Nesting $ \i ->
    Column $ \j ->
      if i == j
        then f doc
        else g doc


-- | Render flattened text on this line, or start
--   a new line before rendering any text.
--
--   This will also nest subsequent lines in the
--   group.
groupOrNestLine :: Doc -> Doc
groupOrNestLine =
  Union
    <$> flatten
    <*> ifNotAtRoot (line <>) . nest 2


-- | Separate items in an alternative with a pipe.
--
--   If the first document and the pipe don't fit
--   on the line, then mandatorily flow the next entry
--   onto the following line.
--
--   The (<//>) softbreak ensures that if the document
--   does fit on the line, there is at least a space,
--   but it's possible for y to still appear on the
--   next line.
altSep :: Doc -> Doc -> Doc
altSep x y =
  group (x <+> char '|' <> line) <//> y


-- | Shenanigans to get nice indentation on line commands
--   and subcommands.
--
--   If we're starting this section over the desired width
--   (usually 1/3 of the ribbon), then we will make a line
--   break, indent all of the usage, and go.
--
--   The ifAtRoot is an interesting clause, because it
--   means if the thing will still actually fit on a
--   single line when we do a `group`, it won't get
--   indented.
hangAtIfOver :: Int -> Int -> Doc -> Doc
hangAtIfOver i j d =
  Column $ \k ->
    if k <= j then
      align d
    else
      linebreak <> ifAtRoot (indent i) d
