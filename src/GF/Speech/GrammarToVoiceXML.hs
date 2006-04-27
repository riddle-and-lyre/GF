----------------------------------------------------------------------
-- |
-- Module      : GrammarToVoiceXML
-- Maintainer  : Bjorn Bringert
-- Stability   : (stable)
-- Portability : (portable)
--
-- Create VoiceXML dialogue system from a GF grammar.
-----------------------------------------------------------------------------

module GF.Speech.GrammarToVoiceXML (grammar2vxml) where

import qualified GF.Canon.GFC as GFC
import GF.Canon.CMacros (noMark)
import GF.Canon.Unlex (formatAsText)
import GF.Compile.ShellState (StateGrammar,stateGrammarST,cncId)
import GF.Grammar.Macros hiding (assign)
import GF.Grammar.Grammar (Fun)
import GF.Grammar.Values (Tree)
import GF.UseGrammar.GetTree (string2treeErr)
import GF.UseGrammar.Linear (linTree2strings)

import GF.Infra.Modules
import GF.Data.Operations

import GF.Data.XML

import Data.List (isPrefixOf, find, intersperse)
import Data.Maybe (fromMaybe)

import Debug.Trace

-- | the main function
grammar2vxml :: String -> StateGrammar -> String
grammar2vxml startcat gr = showsXMLDoc (skel2vxml name startcat gr' qs) ""
    where (name, gr') = vSkeleton (stateGrammarST gr)
          qs = catQuestions gr (map fst gr')

--
-- * VSkeleton: a simple description of the abstract syntax.
--

type VIdent = String

type VSkeleton = [(VIdent, [(VIdent, [VIdent])])]

vSkeleton :: GFC.CanonGrammar -> (String,VSkeleton)
vSkeleton gr = (name,collectR rules [(c,[]) | c <- cats]) where
  collectR rr hh =
   case rr of
     (fun,typ):rs -> case catSkeleton typ of
        Ok (cats,cat) -> 
             collectR rs (updateSkeleton (symid (snd cat)) hh (fun,
	                                                    map (symid . snd) cats))
        _ -> collectR rs hh
     _ -> hh
  cats =  [symid cat | (cat,GFC.AbsCat _ _) <- defs]
  rules = [(symid fun, typ) | (fun,GFC.AbsFun typ _) <- defs]

  defs = concat [tree2list (jments m) | im@(_,ModMod m) <- modules gr, isModAbs m]
  name = ifNull "UnknownModule" (symid . last) [n | (n,ModMod m) <- modules gr, isModAbs m]

updateSkeleton :: VIdent -> VSkeleton -> (VIdent, [VIdent]) -> VSkeleton
updateSkeleton cat skel rule =
 case skel of
   (cat0,rules):rr | cat0 == cat -> (cat0, rule:rules) : rr
   (cat0,rules):rr               -> (cat0, rules) : updateSkeleton cat rr rule

--
-- * Questions to ask 
--

type CatQuestions = [(VIdent,String)]

catQuestions :: StateGrammar -> [VIdent] -> CatQuestions
catQuestions gr cats = [(c,catQuestion gr c) | c <- cats]

catQuestion :: StateGrammar -> VIdent -> String
catQuestion gr cat = err errHandler id (lin gr fun)
  where fun = "quest_" ++ cat
        errHandler e = trace ("GrammarToVoiceXML: " ++ e) fun
        -- FIXME: use some better warning facility

lin :: StateGrammar -> String -> Err String
lin gr fun = do
             tree <- string2treeErr gr fun
             let ls = map unt $ linTree2strings noMark g c tree
             case ls of
                 [] -> fail $ "No linearization of " ++ fun
                 l:_ -> return l
  where c = cncId gr
        g = stateGrammarST gr
        unt = formatAsText 

getCatQuestion :: VIdent -> CatQuestions -> String
getCatQuestion c qs = 
    fromMaybe (error "No question for category " ++ c) (lookup c qs)

--
-- * Generate VoiceXML
--

skel2vxml :: String -> VIdent -> VSkeleton -> CatQuestions -> XML
skel2vxml name start skel qs = 
    vxml (prelude ++ [startForm] ++ concatMap (uncurry (catForms gr qs)) skel)
  where 
  gr = grammarURI name
  prelude = var "debug" (Just "1") : scriptLib
  startForm = Tag "form" [] [subdialog "sub" [("srcexpr","'#'+"++string start)] []]

grammarURI :: String -> String
grammarURI name = name ++ ".grxml"

scriptLib :: [XML]
scriptLib = [script (unlines s)]
 where 
 s = ["function dump(r, p) {",
      "  if (isUndefined(p)) { p = 0 }",
      "  if (isUndefined(r)) {",
      "    return '*undefined*';",
      "  } else if (isArray(r)) {",
      "    var s = '[';",
      "    for (var i = 0; i < r.length; r++) {",
      "       s += dump(r[0], 0);",
      "       if (i < r.length-1) { s += ',' }",
      "    }",
      "    s += ']';",
      "    return s;",
      "  } else if (r == '?') {",
      "    return '?';",
      "  } else {",
      "    var s = r.name;",
      "    var i;",
      "    for (i = 0; ; i++) {",
      "      var c = r['arg'+i];",
      "      if (isUndefined(c)) { break; }",
      "      s += ' ' + dump(c, 1);",
      "    }",
      "    if (i > 0 && p > 0) { s = '(' + s + ')'; }",
      "    return s;",
      "  }",
      "}",
      "function isArray(a) { return a && typeof a == 'object' && a.constructor == Array; }",
      "function isUndefined(a) { return typeof a == 'undefined'; }"
     ]


catForms :: String -> CatQuestions -> VIdent -> [(VIdent, [VIdent])] -> [XML]
catForms gr qs cat fs = 
    comments [cat ++ " category."]
    ++ [cat2form gr qs cat fs] 
    ++ map (uncurry (fun2form gr)) fs

cat2form :: String -> CatQuestions -> VIdent -> [(VIdent, [VIdent])] -> XML
cat2form gr qs cat fs = 
    form cat [var "value" (Just "'?'"), formDebug cat,
              blockCond "value != '?'" [assign cat "value"],
              field cat [] [promptString (getCatQuestion cat qs), 
                            grammar (gr++"#"++cat),
                            nomatch [Data "I didn't understand you.", reprompt],
                            help [Data ("help_"++cat)],
                            filled [] [if_else (cat ++ " == '?'") [reprompt] feedback]],
              blockCond "debug == 1" [prompt [Data (cat ++ " = "), value ("dump("++cat++")")]],
              subdialog "sub" [("srcexpr","'#'+"++cat++".name")] 
                             [param "value" cat, filled [] subDone]]
  where subDone = [assign cat "sub.value", return_ [cat]]
        feedback = []

fun2form :: String -> VIdent -> [VIdent] -> XML
fun2form gr fun args = 
    form fun ([var "value" Nothing] ++ [formDebug fun]
              ++ ss
              ++ [ret])
  where 
  argNames = zip ["arg"++show n | n <- [0..]] args
  ss = map (uncurry mkSub) argNames
  mkSub a t = subdialog a [("srcexpr","'#'+"++string t)] 
                [param "value" ("value."++a),
                 filled [] [assign ("value."++a) (a++"."++t)]]
  ret = block [return_ ["value"]]

formDebug id = blockCond "debug == 1" [prompt [Data ("Entering form " ++ id ++ ". value = "), value "dump(value)"]]

--
-- * VoiceXML stuff
--

vxml :: [XML] -> XML
vxml = Tag "vxml" [("version","2.0"),("xmlns","http://www.w3.org/2001/vxml")]

form :: String -> [XML] -> XML
form id xs = Tag "form" [("id", id)] xs

field :: String -> [(String,String)] -> [XML] -> XML
field name attrs = Tag "field" ([("name",name)]++attrs)

subdialog :: String -> [(String,String)] -> [XML] -> XML
subdialog name attrs = Tag "subdialog" ([("name",name)]++attrs)

filled :: [(String,String)] -> [XML] -> XML
filled = Tag "filled"

grammar :: String -> XML
grammar uri = Tag "grammar" [("src",uri)] []

prompt :: [XML] -> XML
prompt = Tag "prompt" []

promptString :: String -> XML
promptString p = prompt [Data p]

reprompt :: XML
reprompt = Tag "reprompt" [] []

assign :: String -> String -> XML
assign n e = Tag "assign" [("name",n),("expr",e)] []

value :: String -> XML
value expr = Tag "value" [("expr",expr)] []

if_ :: String -> [XML] -> XML
if_ c b = if_else c b []

if_else :: String -> [XML] -> [XML] -> XML
if_else c t f = cond [(c,t)] f

cond :: [(String,[XML])] -> [XML] -> XML
cond ((c,b):rest) els = Tag "if" [("cond",c)] (b ++ es)
  where es = [Tag "elseif" [("cond",c')] b' | (c',b') <- rest] 
             ++ if null els then [] else (Tag "else" [] []:els)

goto_item :: String -> XML
goto_item nextitem = Tag "goto" [("nextitem",nextitem)] []

return_ :: [String] -> XML
return_ names = Tag "return" [("namelist", unwords names)] []

block :: [XML] -> XML
block = Tag "block" []

blockCond :: String -> [XML] -> XML
blockCond cond = Tag "block" [("cond", cond)]

throw :: String -> String -> XML
throw event msg = Tag "throw" [("event",event),("message",msg)] []

nomatch :: [XML] -> XML
nomatch = Tag "nomatch" []

help :: [XML] -> XML
help = Tag "help" []

param :: String -> String -> XML
param name expr = Tag "param" [("name",name),("expr",expr)] []

var :: String -> Maybe String -> XML
var name expr = Tag "var" ([("name",name)]++e) []
  where e = maybe [] ((:[]) . (,) "expr") expr

script :: String -> XML
script s = Tag "script" [] [CData s]

scriptURI :: String -> XML
scriptURI uri = Tag "script" [("uri", uri)] []

--
-- * ECMAScript stuff
--

string :: String -> String
string s = "'" ++ concatMap esc s ++ "'"
  where esc '\'' = "\\'"
        esc c    = [c]

--
-- * List stuff
--

isListCat :: (VIdent, [(VIdent, [VIdent])]) -> Bool
isListCat (cat,rules) = "List" `isPrefixOf` cat && length rules == 2
		    && ("Base"++c) `elem` fs && ("Cons"++c) `elem` fs
    where c = elemCat cat
	  fs = map fst rules

-- | Gets the element category of a list category.
elemCat :: VIdent -> VIdent
elemCat = drop 4

isBaseFun :: VIdent -> Bool
isBaseFun f = "Base" `isPrefixOf` f

isConsFun :: VIdent -> Bool
isConsFun f = "Cons" `isPrefixOf` f

baseSize :: (VIdent, [(VIdent, [VIdent])]) -> Int
baseSize (_,rules) = length bs
    where Just (_,bs) = find (("Base" `isPrefixOf`) . fst) rules
