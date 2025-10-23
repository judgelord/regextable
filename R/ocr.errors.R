ocr.errors <- function(FROM) {

  #gsub() appropriate for piping
  #Can use stringr::str_replace_all() but maybe regex rules are different,
  #e.g., https://stackoverflow.com/q/62471164/6348551
  psub <- function(x, pattern, replacement, ...) {
    gsub(pattern = pattern, replacement = replacement, x = x, ...)
  }

  # adds deleted "ll" to last names
  #CAN EDIT HERE
  FROM <- FROM %>%
    psub("Hiary", "Hillary") %>%
    psub("(^| )Dinge($| )", "\\1Dingell\\2") %>%
    psub("Connoy", "Connolly") %>%
    psub("(^| )Russe($| )", "\\1Russell\\2") %>%
    psub("(^| )Swalwe($| )", "\\1Swalwell\\2") %>%
    psub("Cheie", "Chellie") %>%
    psub("(^| )Uda($| )", "\\1Udall\\2") %>%
    psub("(^| )Wooda($| )", "\\1Woodall\\2") %>%
    #   psub("Marsha$", "Marshall") %>%
    psub("Wiiam", "William") %>%
    psub("(^| )Cantwe($| )", "\\1Cantwell\\2") %>%
    psub("Mier$", "Miller") %>%
    psub("Way$", "Wally") %>%
    psub("Aen$", "Allen") %>%
    psub("(^| )Bi($| )", "\\1Bill\\2") %>%
    psub("Coins", "Collins") %>%
    psub("Paone|Pal lone", "Pallone") %>%
    psub("(^| )Campbe($| )", "\\1Campell\\2") %>%
    psub("Hoen", "Hollen") %>%
    psub("(^| )Darre($| )", "\\1Darrell\\2") %>%
    psub("Gaegly", "Gallegly") %>%
    psub("Giibrand", "Gillibrand") %>%
    psub("(^| )McConne( |$)", "\\1McConnell\\2", ignore.case = TRUE) %>%
    psub("(^| )Ayson", "\\1Allyson") %>%
    psub("Keer($| |,)", "Keller\\1") %>%
    psub("(^| )Een($| )", "\\1Ellen\\2") %>%
    psub("Roybal-Aard", "Roybal-Allard") %>%
    psub("Cuear($| |,)", "Cuellar\\1") %>%
    psub("Pascre($| |,)", "Pascrell\\1") %>%
    psub("Pa one", "Pallone") %>%
    psub("Gabriee", "Gabrielle") %>%
    psub("(^| )Aard", "\\1Allard") %>%
    psub("McCoum", "McCollum", ignore.case = TRUE) %>%
    psub("(^| )Eison( |$)", "\\1Ellison\\2") %>%
    psub("(^| )Weer( |$)", "\\1Weller\\2") %>%
    psub("Rockefeer", "Rockefeller") %>%
    psub("(^| )Suivan( |$)", "\\1Sullivan\\2") %>%
    psub("(^| )Tiis( |$)", "\\1Tillis\\2") %>%
    psub("(^| )McCaski( |$)", "\\1McCaskill\\2") %>%
    psub("(^| )Espaiat( |$)", "\\1Espalliat\\2") %>%
    psub("(^| )Costeo( |$)", "\\1Costello\\2") %>%
    psub("(^| )Hi( |$)", "\\1Hill\\2") %>%
    psub("(^| )Gaego( |$)", "\\1Gallego\\2") %>%
    psub("(^| )McSay( |$)", "\\1McSally\\2", ignore.case = TRUE) %>%
    psub("(^| )Muin( |$)", "\\1Mullin\\2") %>%
    psub("(^| )Ciciin.( |$)", "\\1Cicilline\\2") %>%
    psub("(^| )Sewe( |$)", "\\1Sewell\\2") %>%
    psub("(^| )Heer( |$)", "\\1Heller\\2") %>%
    psub("(^| )Rige( |$)", "\\1Rigell\\2") %>%
    psub("(^| )Emers( |$)", "\\1Ellmers\\2") %>%
    psub("(^| )Mier( |$)", "\\1Miller\\2") %>%
    psub("(^| )Ha( |$)", "\\1Hall\\2") %>%
    psub("(^| )McAISTER( |$)", "\\1McAllister\\2", ignore.case = TRUE) %>%
    psub("(^| )Boswe( |$)", "\\1Boswell\\2") %>%
    psub("(^| )Manzuo( |$)", "\\1Manzullo\\2") %>%
    psub("(^| )Schiing( |$)", "\\1Shilling\\2") %>%
    psub("(^| )Kisse( |$)", "\\1Kissell\\2") %>%
    psub("(^| )Hoingsworth( |$)", "\\1Hollingsworth\\2") %>%
    psub("(^| )Gaagher( |$)", "\\1Gallagher\\2") %>%
    psub("(^| )Joy( |$)", "\\1Jolly\\2") %>%
    psub("(^| )Raha( |$)", "\\1Rahall\\2") %>%
    psub("(^| )Boswe( |$)", "\\1Boswell\\2") %>%
    psub("(^| )Perrieo( |$)", "\\1Perriello\\2") %>%
    psub("(^| )Fain( |$)", "\\1Fallin\\2") %>%
    psub("(^| )Esworth( |$)", "\\1Ellsworth\\2") %>%
    psub("(^| )Moohan( |$)", "\\1Mollohan\\2") %>%
    psub("(^| )Fossea( |$)", "\\1Fossella\\2") %>%
    psub("(^| )Miender-McDonald( |$)", "\\1Millender-McDonald\\2", ignore.case = TRUE) %>%
    psub("(^| )Knoenberg( |$)", "\\1Knollenberg\\2") %>%
    psub("(^| )Gimor( |$)", "\\1Gillmor\\2") %>%
    psub("(^| )Jewe( |$)", "\\1Jewell\\2") %>%
    # add 'll' to first names
    psub("(^| )oyd( |$)", "\\1Lloyd\\2") %>%
    psub("(^| )Lucie( |$)", "\\1Lucille\\2") %>%
    psub("(^| )Michee( |$)", "\\1Michelle\\2") %>%
    psub("(^| )Bi( |$)", "\\1Bill\\2") %>%
    psub("(^| )Biy( |$)", "\\1Billy\\2") %>%
    psub("(^| )Coeen( |$)", "\\1Colleen\\2") %>%
    psub("(^| )Cheie( |$)", "\\1Chellie\\2") %>%
    psub("(^| )Sheey( |$)", "\\1Shelley\\2") %>%
    psub("(^| )Darre( |$)", "\\1Darrell\\2") %>%
    psub("(^| )Ayson( |$)", "\\1Allyson\\2") %>%
    psub("(^| )Aen( |$)", "\\1JAllen\\2") %>%
    psub("(^| )Say( |$)", "\\1Sally\\2") %>%
    psub("(^| )Wi( |$)", "\\1Will\\2") %>%
    psub("(^| )Way( |$)", "\\1Wally\\2") %>%
    psub("(^| )Key( |$)", "\\1Kelly\\2") %>%
    psub("([A-Z])(55)([A-Z])", "\\1SS\\2") %>%
    psub("([A-Z])(5)([A-Z])", "\\1S\\2") %>%
    psub("A1 ", "Al ") %>%
    psub(" 1. ", " L. ") %>%
    psub("Hany", "Harry")

  # other errors
  #FIXED
  FROM <- FROM %>% psub(".1.", "")
  FROM <- ifelse(grepl(" Cha", FROM) & grepl("((^| )Ja)|(J a.son)", FROM) & grepl('etz', FROM),
                 gsub("J.*?n","Jason", FROM), FROM) #not sure if we should make this correction
  FROM <- ifelse(grepl(" Cha", FROM) & grepl("((^| )Ja)|(J a.son)", FROM) & grepl('etz', FROM),
                 gsub("Chaf.*?z","Chaffetz", FROM), FROM) #also not sure if we should make this correction
  FROM <- ifelse(grepl("Tom", FROM) & grepl("Cobum|Co bum", FROM),
                 gsub("Cobum|Co bum", "Coburn", FROM), FROM) #fixed
  FROM <- ifelse(grepl("DarrellIssa", FROM), 'Darrell Issa', FROM) #fixed
  FROM <- ifelse(grepl("Trent|Robin|Mike", FROM) & grepl("Key", FROM),
                 gsub("(Trent|Robin|Mike) Key", "\\1 Kelly",FROM), FROM) #this goes in OCR errors/last name errors
  FROM <- ifelse(grepl("Comyn|Com yn|Cobum|Corvyn", FROM) & grepl("John", FROM),
                 gsub("Comyn|Com yn|Corvyn","Cornyn", FROM), FROM) #fixed
  FROM <- ifelse(grepl("Jon", FROM) & grepl("(^| )Kyi( |$)", FROM),
                 gsub("Kyi","Kyl", FROM), FROM) #fixed
  FROM <- ifelse(grepl("Diane", FROM) & grepl("(^| )Feinstein( |$|,)", FROM),
                 gsub("Diane","Dianne", FROM), FROM) #fixed

  # FROM <- ifelse(grepl("Cliff", FROM)&grepl("Steams", FROM), gsub("Steams","Stearns", FROM), FROM) #fixed

  #FIXED
  FROM <- FROM %>%
    psub("Cwnmings", 'Cummings') %>% # fixed
    psub("Tnhofe", "Inhofe") %>% # fixed
    psub("Ellrners","Ellmers") %>% # fixed
    psub("TONKA", "TONKO") %>% #fixed
    psub("Mcarthur|Mccarthur", "MacArthur", ignore.case = TRUE) %>% #fixed
    psub("(^| )Coryn( |$|,)", "\\1Cornyn\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Connelly( |$|,)", "\\1Connolly\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Heitkmap( |$|,)", "\\1Heitkamp\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Micahel( |$)", "\\1Michael\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Farenhold( |$|,)", "\\1Farenthold\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Eschoo( |$|,)", "\\1Eshoo\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Lary( |$)", "\\1Larry\\2", ignore.case = TRUE) %>% #fixed
    psub("Christophers", "Christopher", ignore.case = TRUE) %>% #fixed
    psub("Courntey", "Courtney", ignore.case = TRUE) %>% #fixed
    psub("(^| )Martrin( |$)", "\\1Martin\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Machin( |$|,)", "\\1Manchin\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Marry( |$|,)", "\\1Mary\\2", ignore.case = TRUE) %>% # might not need this code because it is Harry not Marry
    psub("(^| )T MOTHY( |$|,)", "\\1Timothy\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )L NCOLN( |$|,)", "\\1Lincoln\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Wydon( |$|,)", "\\1Wyden\\2", ignore.case = TRUE) %>% #fixed
    psub("(^| )Klobachur( |$|,)", "\\1Klobuchar\\2", ignore.case = TRUE) %>% #fixed

    return(FROM)
}
