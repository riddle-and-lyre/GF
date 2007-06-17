concrete IdiomSwe of Idiom = CatSwe ** 
  open MorphoSwe, ParadigmsSwe, IrregSwe, Prelude in {

  flags optimize=all_subs ;

  oper
    utr = ParadigmsSwe.utrum ;
    neutr = ParadigmsSwe.neutrum ;

  lin
    ImpersCl vp = mkClause "det" (agrP3 neutr Sg) vp ;
    GenericCl vp = mkClause "man" (agrP3 utr Sg) vp ;

    CleftNP np rs = mkClause "det" (agrP3 neutr Sg) 
      (insertObj (\\_ => rs.s ! np.a)
        (insertObj (\\_ => np.s ! rs.c) (predV verbBe))) ;

    CleftAdv ad s = mkClause "det" (agrP3 neutr Sg) 
      (insertObj (\\_ => "som" ++ s.s ! Sub)
        (insertObj (\\_ => ad.s) (predV verbBe))) ;


    ExistNP np = 
      mkClause "det" (agrP3 neutr Sg) (insertObj 
        (\\_ => np.s ! accusative) (predV (depV finna_V))) ;

    ExistIP ip = {
      s = \\t,a,p => 
            let 
              cls = 
               (mkClause "det" (agrP3 neutr Sg) (predV (depV finna_V))).s ! t ! a ! p ;
              who = ip.s ! accusative
            in table {
              QDir   => who ++ cls ! Inv ;
              QIndir => who ++ cls ! Sub
              }
      } ;


    ProgrVP vp = 
      insertObj (\\a => "att" ++ infVP vp a) (predV (partV h�lla_V "p�")) ;

    ImpPl1 vp = {s = ["l�t oss"] ++ infVP vp {gn = Plg ; p = P1}} ;


}

