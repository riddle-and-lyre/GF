abstract App = 
  Translate - [
  -- Verb
    ComplVS, ComplVQ, ComplVA,
    Slash2V3, Slash3V3, SlashV2V, SlashV2S, SlashV2Q, SlashV2A,
    SlashVV, SlashV2VNP,
    PassVP, ReflVP,
    AdvVPSlash, AdVVPSlash, VPSlashPrep,
  -- Sentence
    PredSCVP, 
    AdvSlash, SlashPrep, SlashVS,
    EmbedS, EmbedQS, EmbedVP, RelS,
  -- Question
    ComplSlashIP,AdvQVP,AddAdvQVP,QuestQVP,
  -- Idiom
    CleftNP, CleftAdv,
    ExistIP,
    ExistNPAdv, ExistIPAdv,
    ImpP3,
    SelfAdvVP, SelfAdVVP, SelfNP,
    
  -- Construction
    hungry_VP, thirsty_VP, has_age_VP, have_name_Cl, married_Cl, what_name_QCl, how_old_QCl, how_far_QCl,
    weather_adjCl, is_right_VP, is_wrong_VP, n_units_AP, bottle_of_CN, cup_of_CN, glass_of_CN, 
    where_go_QCl, where_come_from_QCl, go_here_VP, come_here_VP, come_from_here_VP, go_there_VP, come_there_VP, come_from_there_VP
  -- Extensions
  ]
  ,Phrasebook

              ** {
flags
  startcat=Phr ;
  heuristic_search_factor=0.80; -- doesn't seem to affect speed or quality much

fun
  PhrasePhr : Phrase -> Phr ;
  Phrase_Chunk : Phrase -> Chunk ;

}
