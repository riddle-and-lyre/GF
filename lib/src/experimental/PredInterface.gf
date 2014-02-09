interface PredInterface = open Prelude, (X = ParamX) in {

---------------------
-- parameters -------
---------------------

-- standard usually general
oper
  Number : PType = X.Number ;
  Person : PType = X.Person ;
  Anteriority : PType = X.Anteriority ;
  Polarity : PType = X.Polarity ;
  STense : PType = X.Tense ;
  SVoice : PType ;

param
  Voice = Act | Pass ;  --- should be in ParamX
  Unit = UUnit ;        --- should be in Prelude

-- this works for typical "wh movement" languages

  FocusType = NoFoc | FocSubj | FocObj ; -- sover hon/om hon sover, vem älskar hon/vem hon älskar, vem sover/vem som sover 

-- language-dependent

oper
  Gender : PType ;
  Agr : PType ;       -- full agreement, inherent in NP
  Case : PType ;      -- case of CN     
  NPCase : PType ;    -- full case of NP
  VForm : PType ;     -- inflection form of V
  VVType : PType ;    -- infinitive form required by VV


-- language dependent

  VAgr : PType ;      -- agr features that a verb form depends on
  VType : PType ;     -- reflexive, auxiliary, deponent,...

oper
  active : SVoice ;
  passive : SVoice ;

  defaultVType : VType ;

  subjCase : NPCase ;
  objCase  : NPCase ;

  ComplCase : Type ; -- e.g. preposition
  agentCase : ComplCase ;
  strComplCase : ComplCase -> Str ;

  NounPhrase : Type = {s : NPCase => Str ; a : Agr} ;

  appComplCase  : ComplCase -> NounPhrase -> Str ;
  noComplCase   : ComplCase ;

  noObj : Agr => Str = \\_ => [] ;

  NAgr : PType ;
  AAgr = Agr ;  -- because of reflexives: "happy with itself"
  IPAgr : PType ;

  defaultAgr : Agr ;

-- omitting parts of Agr information

  agr2vagr : Agr -> VAgr ;
  agr2aagr : Agr -> AAgr ;
  agr2nagr : Agr -> NAgr ;

-- restoring full Agr
  ipagr2agr  : IPAgr -> Agr ;
  ipagr2vagr : IPAgr -> VAgr ;

--- this is only needed in VPC formation
  vagr2agr : VAgr -> Agr ;

-- participles as adjectives
  vPastPart : PrVerb -> AAgr -> Str ;
  vPresPart : PrVerb -> AAgr -> Str ;

  vvInfinitive : VVType ;

  isRefl : PrVerb -> Bool ;

--- only needed in Eng because of do questions
  qformsV : Str -> STense -> Anteriority -> Polarity -> VAgr -> PrVerb -> Str * Str ;
  qformsCopula : Str -> STense -> Anteriority -> Polarity -> VAgr -> Str * Str ;


-------------------------------
--- type synonyms
-------------------------------

oper
  PrVerb = {
    s  : VForm => Str ;
    p  : Str ;                 -- verb particle             
    c1 : ComplCase ; 
    c2 : ComplCase ;
    isSubjectControl : Bool ;
    vtype : VType ;  
    vvtype : VVType ;
    } ; 

  initPrVerb : PrVerb = {
    s = \\_ => [] ;
    p = [] ;
    c1 = noComplCase ;
    c2 = noComplCase ;
    isSubjectControl = True ;
    vtype = defaultVType ;
    vvtype = vvInfinitive ;
    } ;

  PrVerbPhrase = {
    v : VAgr => Str * Str * Str ;  -- would,have,slept
    inf : VVType => Str ;          -- (not) ((to)(sleep|have slept) | (sleeping|having slept)
    c1 : ComplCase ; 
    c2 : ComplCase ; 
    part  : Str ;                  -- (look) up
    adj   : Agr => Str ; 
    obj1  : (Agr => Str) * Agr ;   -- agr for object control
    obj2  : (Agr => Str) * Bool ;  -- subject control = True 
    vvtype : VVType ;              -- type of VP complement
    adv : Str ; 
    adV : Str ;
    ext : Str ;
    qforms : VAgr => Str * Str     -- special Eng for introducing "do" in questions
    } ;

  initPrVerbPhrase : PrVerbPhrase = {
    v : VAgr => Str * Str * Str  = \\_ => <[],[],[]> ;
    inf : VVType => Str = \\_ => [] ;
    c1 : ComplCase = noComplCase ; 
    c2 : ComplCase = noComplCase ; 
    part  : Str = [] ;                  -- (look) up
    adj   : Agr => Str = noObj ; 
    obj1  : (Agr => Str) * Agr = <\\_ => [], defaultAgr> ;   -- agr for object control
    obj2  : (Agr => Str) * Bool = <\\_ => [], True>;  -- subject control = True 
    vvtype : VVType = vvInfinitive ;              -- type of VP complement
    adv : Str = [] ; 
    adV : Str = [] ;
    ext : Str = [] ;
    qforms : VAgr => Str * Str = \\_ => <[],[]>    -- special Eng for introducing "do" in questions
    } ;

  initPrVerbPhraseV : 
       {s : Str ; a : Anteriority} -> {s : Str ; t : STense} -> {s : Str ; p : Polarity} -> PrVerb -> PrVerbPhrase = 
  \a,t,p,v -> initPrVerbPhrase ** {
    v   = \\agr => tenseV (a.s ++ t.s ++ p.s) t.t a.a p.p active agr v ;
    inf = \\vt => tenseInfV a.s a.a p.p active v vt ;
    c1  = v.c1 ;
    c2  = v.c2 ;
    part = v.p ;
    obj1 = <case isRefl v of {True => \\a => reflPron a ; _ => \\_ => []}, defaultAgr> ; ---- not used, just default value
    obj2 = <noObj, v.isSubjectControl> ;
    vvtype = v.vvtype ;
    adV = negAdV p ; --- just p.s in Eng
    qforms = \\agr => qformsV (a.s ++ t.s ++ p.s) t.t a.a p.p agr v ;
    } ;
 
  PrClause = {
    v : Str * Str * Str ; 
    adj,obj1,obj2 : Str ; 
    adv : Str ; 
    adV : Str ;
    ext : Str ; 
    subj : Str ; 
    c3  : ComplCase ;              -- for a slashed adjunct, not belonging to the verb valency
    qforms : Str * Str
    } ; 

  initPrClause : PrClause = {
    v : Str * Str * Str = <[],[],[]> ; 
    adj,obj1,obj2 : Str = [] ; 
    adv,adV,ext : Str = [] ; 
    subj : Str = [] ; 
    c3  : ComplCase = noComplCase ;              -- for a slashed adjunct, not belonging to the verb valency
    qforms : Str * Str = <[],[]>
    } ; 

  PrQuestionClause = PrClause ** {
    foc : Str ;                   -- the focal position at the beginning: *who* does she love
    focType : FocusType ;         --- if already filled, then use other place: who loves *who*
    } ; 

---------------------------
---- concrete syntax opers
---------------------------

oper
  reflPron : Agr -> Str ;

  infVP : VVType -> Agr -> PrVerbPhrase -> Str ;

  tenseV : Str -> STense -> Anteriority -> Polarity -> SVoice -> VAgr -> PrVerb -> Str * Str * Str ;

  tenseInfV : Str -> Anteriority -> Polarity -> SVoice -> PrVerb -> VVType -> Str ;

  tenseCopula : Str -> STense -> Anteriority -> Polarity -> VAgr -> Str * Str * Str ;
  tenseInfCopula : Str -> Anteriority -> Polarity -> VVType -> Str ;

  declCl       : PrClause -> Str ;
  declSubordCl : PrClause -> Str ;
  declInvCl    : PrClause -> Str ;

  questCl : PrQuestionClause -> Str ;
  questSubordCl : PrQuestionClause -> Str ;

  that_Compl : Str ;

  addObj2VP : PrVerbPhrase -> (Agr => Str) -> PrVerbPhrase = \vp,obj -> vp ** {
    obj2 = <\\a => vp.obj2.p1 ! a ++ obj ! a, vp.obj2.p2> ;
    } ;

  addExtVP : PrVerbPhrase -> Str -> PrVerbPhrase = \vp,ext -> vp ** {
    ext = ext ;
    } ;

  not_Str : Polarity -> Str ;

  useCopula : {s : Str ; a : Anteriority} -> {s : Str ; t : STense} -> {s : Str ; p : Polarity} -> PrVerbPhrase =
    \a,t,p -> initPrVerbPhrase ** {
    v   = \\agr => tenseCopula (a.s ++ t.s ++ p.s) t.t a.a p.p agr ;
    inf = \\vt => tenseInfCopula a.s a.a p.p vt ;
    adV = negAdV p ;
    qforms = \\agr => qformsCopula (a.s ++ t.s ++ p.s) t.t a.a p.p agr ;
    } ;

}