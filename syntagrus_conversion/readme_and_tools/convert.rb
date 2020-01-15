# -*- coding: utf-8 -*-

require "rubygems"
require 'nokogiri'

f = File.open(ARGV[0])
@flags = File.open( "flags.txt", "w" )
@non_v_roots = File.open( "nonvroots.txt", "w" )
@erase_trees = []
@excluded_sentences = []
@crit_flags = File.open( "critical_flags.txt", "w" )
@sentence_ids = File.open( "sentence_ids.txt", "w" )
testmode = false #import metadata from the original tgt files or just use dummy patterns

EMERGENCY_POS = {"COM" => "Nb"}


doc = Nokogiri::XML(f,nil,'utf-8') 
f.close
#STDERR.puts doc

FT = {"СОВ" => "pf",
  "НЕСОВ" => "ipf",
  "ИМ" => "n",
  "ВИН" => "a",
  "РОД" => "g",
  "ДАТ" => "d",
  "ТВОР" => "i",
  "ПР" => "l",
  "МЕСТН" => "l",
  "ПАРТ" => 'g',
  "ЗВ" => 'v',
  "МУЖ" => 'm',
  'ЖЕН' => 'f',
  'СРЕД' => 'n',
  'ЕД' => 's',
  'МН' => 'p',
  'СРАВ' => 'c',
  'ПРЕВ' => 's',
  'КР' => 's',
  'ИНФ' => 'n',
  'ПРИЧ' => 'p',
  'ДЕЕПР' => 'd',
  'ИЗЪЯВ' => 'i',
  'ПОВ' => 'm',
  'НЕПРОШ' => 'p',
  'ПРОШ' => 'u',
  'НАСТ' => 'p',
  '1-Л' => '1',
  '2-Л' => '2',
  '3-Л' => '3',
  'СТРАД' => 'p',
  'V' => 'V-',
  'S' => 'Nb',
  'A' => 'A-',
  'ADV' => 'Df',
  'NUM' => 'Ma',
  'PR' => 'R-',
  'CONJ' => 'C-',
  'PART' => 'Df',
  'P' => 'I-',
  'INTJ' => 'I-',
  'NID' => 'F-',
  'COM' => 'COM' #Covered by convert_coms
}

RELATIONS1={"опред"=>"atr", #biunique relations (currently also contains relations that require structural changes, I haven't decided yet how to deal with them)
"аппоз"=>"apos",
"релят"=>"rel",
"электив"=>"part",
"разъяснит"=>"apos", 
"предл"=>"obl", 
"об-аппоз"=>"apos",
"ном-аппоз"=>"apos",
"нум-аппоз"=>"apos",
"колич-огран"=>"adv",
"длительн"=>"adv",
"кратно-длительн"=>"adv",
"дистанц"=>"adv",
"обст-тавт"=>"adv",
"суб-обст"=>"adv",
"об-обст"=>"adv",
"изъясн"=>"apos",
"эксплет"=>"apos",
"пролепт"=>"apos",
"агент"=>"ag",
#"несобст-агент"=>"adv", 
"подч-союзн"=>"pred",
"сравнит"=>"obl", #DONE with simplifications
"сравн-союзн"=>"obl", #DONE with simplifications
"сент-предик"=>"voc", #DONE
#"адр-присв"=>"obl", #DONE
"атриб"=>"atr",
#"количест"=>"part", #DONE (flagging ambiguous cases)
#"аппрокс-колич"=>"part", #DONE
#"колич-копред"=>"sub",	#DONE
"распред"=>"atr",
"примыкат"=>"parpred",
"уточн"=>"apos", #or revert to APOS? I'd say no, all the work on deciding what's restricting what has already been done. But then we have discrepancy with OR and OCS
"пасс-анал"=>"xobj",
#"присвяз"=>"xobj", #separate method created
"компл-аппоз"=>"apos",
"инф-союзн"=>"pred", 
"композ"=>"atr", 
#"1-несобст-компл"=>"adv", #for now
#"2-несобст-компл"=>"adv",
#"3-несобст-компл"=>"adv",
#"4-несобст-компл"=>"adv"
}

RELATIONS2={"квазиагент"=>"atr", #DONE
"обст"=>"adv", #DONE
#"дат-субъект"=>"sub",  #DONE
"вводн"=>"parpred", #DONE. check, consider stuff like разумеется
#"оп-опред"=>"atr", #DONE 
#"суб-копр"=>"xadv", #DONE
#"об-копр"=>"xobj", # DONE
#"соотнос"=>"aux", #DONE
"неакт-компл"=>"obl", 
"1-компл"=>"obj", 
"2-компл"=>"obl",
"3-компл"=>"obl",
"4-компл"=>"obl",
"5-компл"=>"obl",
"огранич"=>"aux", #DONE, but improve lexical methods 
#"предик"=>"sub", #DONE, but consider further structural changes and correct errors
"аналит"=>"aux", #DONE
#"вспом"=>"apos", #structural changes 
"соч-союзн"=>"expl" #just to mark some complex cases
}

RELATIONS0=["adnom","adv","ag","apos","arg","atr","aux","comp","expl","narg","nonsub","obj","obl","parpred","part","per","pred","rel","sub","voc","xadv","xobj"]
RELATIONS_AFTER=["оп-опред","вспом"]#, "несобст-агент", "1-несобст-компл", "2-несобст-компл", "3-несобст-компл", "4-несобст-компл"]
POS_ALL = ["A-", "Df", "S-", "Ma", "Nb", "C-", "Pd" , "F-" , "Px" , "N-" , "I-" , "Du", "Pi" , "Mo" , "Pp" , "Pk" , "Ps" , "Pt", "R-", "Ne", "Py", "Pc", "Dq", "Pr", "G-", "V-", "X-"]


#The relations which will be relocated from a non-verbal node to a governing empty verb if and when it is inserted. TODO: consider expanding. 
#AUXs don't get caught, e.g. sentence-initial conjunctions (they remain on xobjs). But that's not relevant for CPs.
RELATIONS_TO_RELOCATE=["колич-огран", "длительн", "кратно-длительн","дистанц","обст-тавт", "суб-обст", "об-обст", "несобст-агент","уточн","1-несобст-компл","2-несобст-компл","3-несобст-компл","4-несобст-компл","обст","суб-копр","неакт-компл"]
RELATIONS_TO_RELOCATE_SUB=["неакт-компл"]

#adverbal relations that cannot be repeated 
SINGLE_RELS=["sub","obj","xobj","comp","ag"]

ACCPREPS=["СКВОЗЬ", "ЧЕРЕЗ", "ПРО", "В", "ЗА", "НА", "ПО", "О", "ПОД"]
GENPREPS=["БЕЗ","ВМЕСТО","ДЛЯ","ДО","ИЗ","ИЗ-ЗА","КРОМЕ","МИМО","ОКОЛО","ОТ","ПРОТИВ","СРЕДИ","У","ВОЗЛЕ","БЛИЗ","ВБЛИЗИ","ВВИДУ","ВДОЛЬ","ВЗАМЕН","ВНЕ","ВОКРУГ","ВПЕРЕДИ","ВРОДЕ","НАКАНУНЕ","НАПОДОБИЕ","НАПРОТИВ","ПОДЛЕ","ПОЗАДИ","ПОМИМО","ПОПЕРЕК","ПОСЛЕ","ПРЕЖДЕ","СВЕРХ"]

#with these verbs ob-kopr converts into xobj, not xadv
PERCVERBS=["ВИДЕТЬ","НАХОДИТЬ","ОБНАРУЖИВАТЬ","ЗНАТЬ","ОСОЗНАВАТЬ","ЗАПОМИНАТЬ"]

#TODO: add more PDs, MOs, maybe more PI? And lots of POS will be decided by syntax!

PP = ['Я','ТЫ','МЫ','ВЫ','ОН','ОНА','ОНО','ОНИ']

PS = ['МОЙ','ТВОЙ','ВАШ','НАШ']

PT = ['СВОЙ']

PK = ['СЕБЯ']

PD = ['ТОТ','ЭТОТ','ТАКОЙ','САМ','СЕЙ','ТО','ЭТО']

FIRST = ['Я','МЫ','МОЙ','НАШ']

SECOND = ['ТЫ','ВЫ','ТВОЙ','ВАШ']

THIRD = ['ОН','ОНА','ОНО','ОНИ','СВОЙ','СЕБЯ']

SING = ['Я','ТЫ','ОН','ОНА','ОНО','СЕБЯ']

PLUR = ['МЫ','ВЫ','ОНИ']

MO = ['ПЕРВЫЙ','ВТОРОЙ','ТРЕТИЙ','ЧЕТВЕРТЫЙ','ПЯТЫЙ','ШЕСТОЙ','СЕДЬМОЙ','ВОСЬМОЙ','ДЕВЯТЫЙ','ДЕСЯТЫЙ','ОДИННАДЦАТЫЙ','ДВЕНАДЦАТЫЙ','ЧЕТЫРНАДЦАТЫЙ','ПЯТНАДЦАТЫЙ','ШЕСТНАДЦАТЫЙ','СЕМНАДЦАТЫЙ','ВОСЕМНАДЦАТЫЙ','ДЕВЯТНАДЦАТЫЙ','ДВАДЦАТЫЙ','ТРИДЦАТЫЙ','СОРОКОВОЙ','ПЯТИДЕСЯТЫЙ','ШЕСТИДЕСЯТЫЙ','СЕМИДЕСЯТЫЙ','ВОСЬМИДЕСЯТЫЙ','ДЕВЯНОСТЫЙ','СОТЫЙ',"70-Й","1-Й","1930-Й","90-Й","2-Й","13-Й","1864-Й","2001-Й","1993-Й","1956-Й","80-Й","42-Й","1960-Й","91-Й","1718-Й","96-Й","60-Й","3-Й","20-Й","30-Й","2000-Й","99-Й","92-Й","14-Й","93-Й","2003-Й","88-Й","1950-Й","1980-Й","1943-Й","1990-Й","2008-Й","76-Й","1926-Й","1920-Й","19-Й","1080-Й","82-Й","63-Й","75-Й","1964-Й","50-Й","1988-Й","56-Й","38-Й","1955-Й","1953-Й","1954-Й","1940-Й","53-Й","1970-Й","2004-Й","2009-Й","36-Й","1998-Й","2005-Й","83-ИЙ","87-Й","58-Й","2006-Й","55-Й","85-Й","54-Й","69-Й","28-Й","211-Й","1999-Й","98-Й","95-Й","1944-Й","2007-Й","1990-ЫЙ","1990-Е","1970-Е","1963-Й","60-Е","4-Й","12-Й","53-ИЙ","1930-Е","1924-Й","70-Е","1962-Й","1966-Й","1972-Й","1991-Й","72-Й","1994-Й","11-Й","90-ЫЙ","2010-Й","2011-Й","1994-ЫЙ","2008-ОЙ","90ОК-КОЛИЧ","1990ОК-ПОРЯДК","1977-Й","2012-Й","1989-Й","89-Й","1979-ЫЙ","60-ЫЕ","1970-Х","2002-Й","9-ЫЙ","2004-ЫЙ","1900-Й","5-Й","6-Й","23-Й","37-Й","35-Й","18-Й","24-Й","17-Й","1992-Й","1997-Й","16-Й","1995-Й","1816-Й","1819-Й","1775-Й","1732-Й","1830-Й","1788-Й","1791-Й","1821-Й","1851-Й","120-Й","124-Й","4-ЫЙ","1616-Й","78-Й","10-Й","400-Й","770-Й","90-Е","7-Й","31-Й","8-Й","21-Й","5-ЫЙ","1942-Й","1961-Й","1968-Й","1939-Й","1945-Й","1952-Й","64-Й","52-Й","1987-Й","1979-Й","68-Й","1982-Й","1860-Й","1870-Й","1890-Й","1880-Й","1773-Й","1789-Й","1812-Й","1937-Й","1820-Й","1933-Й","9-Й","62-Й","79-Й","71-Й","295-Й","1938-Й","47-Й","43-Й","45-Й","46-Й","40-Й","1996-Й","1-ОЙ","118-Й","17-ЫЙ","1917-Й"]

PI = ['ЧЕЙ','КТО','ЧТО','КАКОЙ']

PR = ['КОТОРЫЙ']

DU = ['ГДЕ','КАК','КУДА','СКОЛЬКО','ЛИ','ОТКУДА','ПОЧЕМУ','ОТЧЕГО','КОГДА']

PX = ['КТО-ТО','КТО-НИБУДЬ','КТО-ЛИБО','КАКОЙ-ТО','КАКОЙ-НИБУДЬ','КАКОЙ-ЛИБО','НИКТО','НЕКТО','НИКАКОЙ','ВЕСЬ','КАЖДЫЙ','ВСЯКЫЙ','НИЧТО','НЕЧТО','ВСЕ','ЧТО-НИБУДЬ','ЧТО-ТО','ЧТО-ЛИБО'] #кто, что have to be indefinite pronouns sometimes, at least with угодно. We should consider Py (quantifier) for весь. There are probably more items that should be on this list. Note that ничего, нечего are adverbs.

COORD = ['сент-соч','сочин','соч-союзн','ком-сочин']

CONJS = ['А','АН','ДА','ЗАТО','И','ИЛИ','ИЛЬ','ИНАЧЕ','ЛИБО','ЛИ','НО','ПРИЧЕМ','ТОЛЬКО','НИ','А ТО И','ТАК И','ТО','НЕ ТО','А ТАКЖЕ','А ТО']

NONARG = ["БИОГРАФИЯ","ГРЕХ","КАРТИНА","ПРАВИТЕЛЬСТВО","СИМВОЛ","УЧЕБНИК","ИСТОРИЯ","ЛЕГЕНДА","ОБЩЕЖИТИЕ","СТУДЕНТ","ШАНС","ПРАВДА","ЗАМДИРЕКТОРА","КЛИЕНТ","ДОСКА","ДЕПУТАТ","ВИД","ТЕМА","СЛУЧАЙ","ПРЕЗИДЕНТ","ВАРИАНТ","ХРАМ","МИНИСТЕРСТВО","СУБЪЕКТ","СПЕЦИАЛИСТ","ФУНКЦИЯ","ТЕНДЕНЦИЯ","ПРИНЦИП","ПРОТОТИП","МОДЕЛЬ","ТЕХНИКА","ТЕОРИЯ","ПРИМЕР","ИНСТРУМЕНТ","БИОЛОГИЯ","ИМПУЛЬС","КОНЦЕПЦИЯ","СПОСОБ","АНАЛОГ","ОБРАЗЕЦ","ПРЕДМЕТ","ТЕХНОЛОГИЯ","СТАДИЯ","ПРОФЕССОР","МИНИСТР","ПРАВО","КОНКУРС","УРОК","НАСЕЛЕНИЕ","ЭКСПЕРИМЕНТ","МЕХАНИЗМ","ПРОБЛЕМА","ДАННЫЕ","КОРОЧКА","ПРОГНОЗ","ПЛАН","ИНФОРМАЦИЯ","ФИЛИАЛ","ЗАКОН","МОМЕНТ","ГРАФИК","МЕРОПРИЯТИЕ","КОНФЕРЕНЦИЯ","БЕСПОМОЩНОСТЬ","АКАДЕМИК","ДОКТОР","ЛАБОРАТОРИЯ","ИНСТИТУТ","КОЛЛЕГА","ПУТЬ","ВРЕМЯ","МАСШТАБ","МЕТОД","ПЕРСПЕКТИВА","СЦЕНАРИЙ","ЦЕЛЬ","РЕБЕНОК","СТОРОННИК","ВЕРСИЯ","ПРОТОКОЛ","ПРОЕКТ","СХЕМА","АВТОРИТЕТ","ОТДЕЛ","НИИ","РАЗНИЦА","ЦЕНТР","ПРИЧИНА","ТРАДИЦИЯ","СИТУАЦИЯ","ГЛАВА","ИНТЕРВЬЮ","АДМИНИСТРАЦИЯ","ЛОГИКА","АНАЛОГИЯ","ЧЛЕН","КУРАТОР","МАТЕРИАЛ","ИДЕЯ","АГЕНТСТВО","РОЛЬ","ТЕЗИС","РЕФОРМА","ОБЯЗАТЕЛЬСТВО","ИДЕОЛОГИЯ","ФИЛОСОФИЯ","РЫНОК","ПЕРИОД","ИДЕОЛОГ","КАНДИДАТ","СИСТЕМА","АВТОР","ПРОГРАММА","ЛИЦЕНЗИЯ","ПОРА","РОДИТЕЛЬ","ДРУГ","ПОРТРЕТ","ОПАСНОСТЬ","МУЗЕЙ","РИСК","ЦЕНА","САЛОН","СЕВЕРО-ЗАПАД","КОЗЫРЬ","ПРЕСС-СЕКРЕТАРЬ","ДЕПАРТАМЕНТ","ПРИЗНАК","РАНГ","ХОЗЯИН","НОРМА","ЛЬГОТА","МЕТОДИКА","ЛИБО","ДЕЛО","ЯЗЫК","АННАЛЫ","ФАРАОН","СЫН","ДЯДЯ","КОНТАКТ","БАНК","СТАТУЯ","ЖЕНА","ОТЕЦ","БРАТ","АЛЬТЕРНАТИВА","СРЕДСТВО","АЛГОРИТМ","ЦЕЛЕСООБРАЗНОСТЬ","ФЕНОМЕН","КЛЮЧ","КАТЕГОРИЯ","ПРЕДОК","ЗАЛОГ","ШИРИНА","ГОСТЬ","ГЛУБИНА","КНИГА","ВЕТЕРАН","ПОДРУГА","КУРС","ФАКТ","ЭКОНОМИКА","ЗАМГЛАВЫ","БРОСАТЬ.pf","ЛАУРЕАТ","ВИЦЕ-ПРЕЗИДЕНТ","ТАРИФ","КАНАЛ","ПАМЯТНИК","КОМИССИЯ","НУЖДА","МЕСТО","РОДСТВО","ШЕФ","СЕКРЕТАРЬ","ЦК","МИФ","ФИГУРА","РОДСТВЕННИК","МЕРА","ПОСОЛ","НАРКОМ","РЕКОРД","АКАДЕМИЯ","РЕЖИМ","АРХИТЕКТОР","ЗАПАД","КАРТА","КЛАДБИЩЕ","КОЛЕЯ","РАССТОЯНИЕ","ПИОНЕР","ТОРЖЕСТВО","ПЛОЩАДЬ","ДИАЛОГ","СТУДИЯ","ИНТЕРЕС","ЭКСПОНАТ","ИНИЦИАТИВА","ЭКСПОЗИЦИЯ","ВЕБ-СЛУЖБА","МОНОГРАФИЯ","СТРАСТЬ","ПРИТЯГАТЕЛЬНОСТЬ","НОВИЧОК","ГРОБНИЦА","ФОРМА","МАТЬ","ПЕРЕЛИВАТЬ.ipf","СЕСТРА","ХАН","ПОТОМОК","ЭКС-ПРЕМЬЕР-МИНИСТР","УНИВЕРСИТЕТ","ДИСПУТ","ТРУД","ПОВОД","ПРИНОСИТЬ.pf","ЗАПИСЬ","РИСУНОК","СТАТЬЯ","ПАКТ","СОБРАТ","ПОТОМСТВО","СТЕРЕОТИП","ЧАСТЬ","НАУКА","НАЛОГ","ТАЙНА","ГРАЖДАНИН","СОГРАЖДАНИН","ОСТАВАТЬСЯ.ipf","ПРЕДЕЛ","ДУПЛО","ТЕСТЬ","РЕЦЕПТ","РОБОСТЬ","МУЖЕСТВО","ГИДРОДИНАМИКА","СПУТНИК","СВОЙСТВО","ХАРАКТЕРИСТИКА","ПРЕМИЯ","МОЩНОСТЬ","АКТИВИСТ","ЧЕЛОВЕК","ОЧЕРЕДЬ","БИЛЕТ","САМОЛЕТ","ВЛАДЫКА","КВОТА","ДИПЛОМ","ВЫГОДА","ДОКУМЕНТ","ПОЛЬЗА","КОНТРАКТ","ОБЪЕКТ","СТАТИСТИКА","КУЛЬТ","МОТИВ","СВЕРСТНИК","СЕКРЕТ","СЕВЕР","ПУТЕВОДИТЕЛЬ","ЗНАК","СТЕНКА","УЗЕЛ","ВИДЕОЗАПИСЬ","ПОТОК","ПРОФЕССИОНАЛ","ЭКОНОМИЯ","КАМПАНИЯ","СТИЛЬ","ТРИГЛИЦЕРИД","ВОСТОК","ГЕНДИРЕКТОР","ЛИМИТ","ПРАВИЛО","АКЦИЯ","СЕРВИС","СИГНАЛ","АРХИВ","СИМПОЗИУМ","ФОНД","РИТУАЛ","СВОБОДА","ЗАБОТА","ПАТРИАРХ","КОМАНДИРОВКА","ИЛЛЮСТРАЦИЯ","КОНТОРА","ПИСЬМО","РОМАН","СЛОВАРЬ","СПАСИБО","КОНСПЕКТ","УГОЛ","ЦЕРКОВЬ","НАРОД","СТАТУС","СТАНЦИЯ","КАРТОЧКА","ГРАНТ","АРГУМЕНТ","ВОЙСКА","ГРАЖДАНСТВО","ЗАМРУКОВОДИТЕЛЯ","РЕФЕРЕНДУМ","ПОЛПРЕД","РОДОНАЧАЛЬНИК","ГЕНЕРАЦИЯ","ТОПОЛОГИЯ","КОМАНДА","ИНДУСТРИЯ","ПРЕПАРАТ","СИМПТОМ","ЗАКОНОПРОЕКТ","КОМИТЕТ","ПОЛИТИКА","СОБСТВЕННОСТЬ","МУЖ","ПАПА","ДОКЛАД","ШАГ","ШЕФСТВО","ЭКЗАМЕН","БРЕМЯ","ЧИНОВНИК","РЕВОЛЮЦИЯ","ШЕДЕВР","ЦЕХ","ГИПОТЕЗА","ВРАГ","ЭКСПЕДИЦИЯ","СПЕКТРОСКОПИЯ","СОСЕД","НИТРАТ","ФИЗИКА","ВИЗИТ","ВЛАСТЕЛИН","ПРОДЮСЕР","ПРЕМЬЕРА","ЯРМАРКА","ФРАЗА","СКОЛЬКО","СИНТЕЗ","ВКУС","СОВРЕМЕННИК","ШКОЛА","СЧАСТЬЕ","УРОВЕНЬ","БИОХИМИЯ","ДОЗА","ОЧЕРК","ВОЛЯ","ИЗОЛЯТ","ОБЫЧАЙ","ПОСТ","БЕССИЛИЕ","МОНОПОЛИЯ","ИНСТИНКТ","СОПРЕДСЕДАТЕЛЬ","ПРОК","КАФЕДРА","ГЕОФИЗИКА","ВЫСОТА","ДЕФИЦИТ","ШТАБ-КВАРТИРА","ДОРОГА","ЛИЧИНКА","РАЗМЕР","ПРЕЗИДИУМ","ЛЮБИМИЦА","БЮДЖЕТ","ЛОЗУНГ","ОРУДИЕ","ЭКОЛОГИЯ","ФРАКЦИЯ","ЧИН","ПЛЕМЯННИЦА","ПРАДЕД","СУПРУГА","ПРАВНУЧКА","ДИРЕКЦИЯ","РОДСТВЕННИЦА","ДИАСПОРА","ВЕХА","ЛИДЕРСТВО","ЭНЦИКЛОПЕДИЯ","ДОГОВОРЕННОСТЬ","КРЕДИТ","СУММА","ГОСДЕПАРТАМЕНТ","ТРЕНИНГ-ЦЕНТР","ЦИТАТА","КОНДУКТОР","ПАРТИТУРА","ДОЛЖНОСТЬ","АРМИЯ","ПУЛЬТ","НОУ-ХАУ","ЭНТУЗИАСТ","ЦАРЬ","ВМС","СТАНДАРТ","РЭНКИНГ","КОМАНДИР","ОГОНЬ","ТОВАРИЩ","ПРЕИМУЩЕСТВО","ЦЕРЕМОНИЯ","МЕТАФИЗИКА","РЕСУРС","ПОДПРОСТРАНСТВО","НЕРАВЕНСТВО","ПУТЫ","ИДЕАЛ","ЛЕЙТМОТИВ","ДОЛЯ","ДЫРА","МЭР","ПОЛИТСОВЕТ","СОРАТНИК","КОМПЛИМЕНТ","ЗАМПРЕД","ПОШЛИНА","АКЦИЗ","ФИРМА","ПИЛОТ","КОЛЛЕГИЯ","СПРАВКА","АКЦИОНЕР","КЛАСС","БЛОК","РАЗДЕЛ","ТАКТИКА","РЕПУТАЦИЯ","ЗАСЕДАНИЕ","ЮГО-ЗАПАД","УДОБСТВО","АРЕНДА","ДИЗАЙНЕР","ПСИХОЛОГИЯ","РЕКЛАМА","ИДОЛ","СОН","ПРОЕКЦИЯ","ПРИЯТЕЛЬ","ДВОЙНИК","МОНОПОЛИЗАЦИЯ","ДЕБАТЫ","ВНУЧКА","ДОЧКА","МЕНЕДЖЕР","ГУБЕРНАТОР","ГОСКОМИТЕТ","ДОЛГ","ВИЦЕ-СПИКЕР","СВЕРХДОХОД","ЗНАКОМЫЙ","ЛОКОМОТИВ","СТИПЕНДИЯ","ВЕДОМСТВО","ШТАБ","ПОРЯДОК","САНКЦИЯ","КОМИССАР","КУРСАНТ","ПРОКУРАТУРА","ПОДНАЕМ","АТТАШЕ","ВИНОВНИЦА","УЛЬТИМАТУМ","СЕНАТ","МАРШ","КОАЛИЦИЯ","НАРКОМАТ","РЕГЕНТ","ГЛАВАРЬ","ПОЛИТБЮРО","ГЕНСЕК","АССАМБЛЕЯ","СОЮЗ","МУЗА","ПРИОРИТЕТ","КАВАЛЕР","ОФИЦЕР","КАДРЫ","ДОКТРИНА","ВС","МОРАТОРИЙ","ЦЕЛЕНАПРАВЛЕННОСТЬ","ЧЕСТЬ","ПЕНСИЯ","ГЕНОЦИД","ДЕД","МЕДЖЛИС","ВИЦЕ-ПРЕМЬЕР","ХРОНОЛОГИЯ","ПАССАЖИР","ПАРАДОКС","БЕЗУМИЕ","ПОЛЕМИКА","ПРИМАТ","ЗАМ","ДОЧЬ","НОЖ","МУСУЛЬМАНИН","ДИТЯ","ГЕРОЙ","ДЕЛЕГАТ","СКАЗКА","БЫЛЬ","ЧЛЕН-КОРРЕСПОНДЕНТ","РЕКТОР","ФОТО","НЕЙРОХИМИЯ","ТИТУЛ","НЕВОЛЬНИК","ЦЕПКОСТЬ","КОНГЛОМЕРАТ","ИЛЛЮЗИЯ","МОНИТОР","СОАВТОР","ТЕРРОР","ПРОКЛАДЫВАТЬ.pf","ФОРПОСТ","ДИСТАНЦИЯ","КУЛЬТУРА","АВТОМАТ","ГЕОХИМИЯ","ПРЕЛЮДИЯ","РЕЙТИНГ","ТОСТ","АНЕКДОТ","НРАВ","ЗЯТЬ","ЕДИНОМЫШЛЕННИК","СЮЖЕТ","АДВОКАТ","МАКЕТ","СКУЛЬПТУРА","САМКА","ВДОВА","ТОМОГРАФИЯ","ТОМОГРАММА","ПАНАЦЕЯ","БОЛЬНОЙ","КОНТРАСТ","ПАРК","ИНТЕРВАЛ","ЮГ","СПИКЕР","МИФОЛОГИЯ","ДОТАЦИЯ","РЕНТГЕН","КОНГРЕСС","УЗИ","СМЕРТНОСТЬ","КОЛЛЕКТИВ","АППАРАТУРА","ПОВЕСТКА","СЛОВО","ДОППЛЕРОГРАФИЯ","ДИССЕРТАЦИЯ","ГЕОМЕТРИЯ","ИНДИКАТОР","РУПОР","АССИСТЕНТ","ИСТИНА","НЕИЗБЕЖНОСТЬ","ПРОПАГАНДА","ЗАВОД","КРАЙКОМ","СТОИМОСТЬ","ПАРТНЕРСТВО","ГОСЗАКАЗ","ГОСГАРАНТИЯ","БАЗА","БАРЬЕР","ПРИПРАВА","ЧЕТВЕРТЬФИНАЛ","ГОЛ","КОНВЕНЦИЯ","ПРОРОЧЕСТВО","СОСЕДСТВО","ФАЗА","ЭКС-МИНИСТР","СЕРТИФИКАТ","ЭМБАРГО","ТРАНЗИТ","КАЗУС","ПАЦИЕНТ","ЧЕМПИОНКА","МИФОЛОГЕМА","АГЕНТ","ТРАКТАТ","ФАНТАЗИЯ","ЧЕМПИОН","ФИЛЬМ","МИГ","ФОРВАРД","ЭКС-ГЛАВА","СБ","ДРУЖБА","ЛЮБИМЕЦ","ПАРТНЕР","ЛЕКАРСТВО","ПРАРОДИТЕЛЬ","ЧЕМПИОНАТ","МАГАЗИН","ЗАПЧАСТЬ","ПРИЗ","ПЕРВЕНСТВО","ИГРУШКА","ШОУ","ГОТОВИТЬ.ipf","ДИЗАЙН","НАБРОСОК","ОТРЫВОК","РЕЦИДИВ","СТАРТ","ТОПЛИВО","ГЕРОИНЯ","ПРОФЕССИЯ","ДЕВИЗ","ПАТРИОТ","ЧЛЕНСТВО","ЗАМНАЧАЛЬНИКА","КОДЕКС","КОМИССАРИАТ","МИГРАНТ","ПАУЗА","ДОБРОЖЕЛАТЕЛЬ","КНОПКА","РАСПИЛ","ЦАРАПИНА","МОРОКА","АСТРОНАВТ","МОНОКСИД","ОКСИД","ЭЛЕКТРОЛИЗ","ПИЩА","НАСТОЙ","СИМПАТИЯ","ВЕС","НЕВЕСТА","ГЛАВНОКОМАНДОВАНИЕ","АНШЛЮС","ШТРАФ","ФУНКЦИОНЕР","ЭРЗАЦ","ПАНЕГИРИК","ОБСТОЯТЕЛЬСТВО","БЛИЗКИЕ","НОТКА","ИНКУБАТОР","ИСКУССТВО","ПРИЧЕМ","ДЕКАН","ОБЩЕСТВО","УФСБ","КОРОЛЬ","ФАКТУРА","ИГЛА","ОКРАСКА","ПАРОДИЯ","ОБЪЕКТИВ","НЕБЫЛИЦА","СМЫСЛ","КОММЕНТАРИЙ","ПАССАЖ","ПРОГРЕСС","ПОЕДИНОК","ПРИБЛИЖЕННЫЙ","ТАКТ","ДОРОЖКА","ПОЕЗД","ПРОТЕКТОР","МОСТ","ФИГУРКА","МОДА","ЦВЕТ","СРЕДНЕЕ","ТЕСТ-ДРАЙВ","СБОРНИК","ОТЕЦ1","ПРОКУРОР","ТОП-МЕНЕДЖМЕНТ","ШОК","ВЫВЕСКА","РОДИЧ","ПЕЙЗАЖ","АЛЛЕРГИЯ","ЗЕРКАЛО","ПРОЕКТИРОВЩИК","МАСТЕР","КАНДИДАТУРА","ВРАЧ","ПСИХОФИЗИОЛОГИЯ","СТАРОЖИЛ","ЦИКЛОГРАММА","ТОЛК","ГЛОТОК","ФЕСТИВАЛЬ","РЕЗОЛЮЦИЯ","СУБСИДИЯ","НЕТ","ШКВАЛ","ГОСПРОГРАММА","ЕГЭ","БЮРО","ОРИЕНТИР","ПРИЗРАК","ГЕОГРАФИЯ","МАНЕРА","МИНУТА","КОЛЫБЕЛЬ","ФАКУЛЬТЕТ","РЕФЕРАТ","РЕДКОЛЛЕГИЯ","ЖУРНАЛИСТ","ЭССЕ","ГЛАВРЕД","ШЕФ-РЕДАКТОР","ВЛАСТИТЕЛЬ","ОФИС","КОНЪЮНКТУРА","ФЬЮЧЕРС","ТОРГИ","ПРОДОЛЖИТЕЛЬНОСТЬ","МОГИЛА","ЗАММИНИСТРА","ПРОРЕКТОР","ДЕТЕНЫШ","ЗАВКАФЕДРОЙ","ФОРУМ","АДЕПТ","СУРРОГАТ","ПОДКОНТРОЛЬНОСТЬ","ПРЕМЬЕР-МИНИСТР","КОМПАНИЯ","ТЕЛЕМОСТ","ПИАР-АТАКА","АЖИОТАЖ","МАТЧ","ВРАТАРЬ","МАМА","КОРОЛЕВА","ВВС","ПРОМЕЖУТОК","ФАНАТ","ЗАВУЧ","СРОК","РАПОРТ","ОЛИМПИАДА","ПОСОЛЬСТВО","ТУРНИР","МАШИНИСТ","БОСС","МЕНЕДЖМЕНТ","ЛОЯЛЬНОСТЬ","ПРОФБОСС","ЦЕНТРИЗБИРКОМ","СЕМИНАР","ТАЛОН","ПОРОГ","ТЕЛЛУРИД","ПАРЛАМЕНТ","КОНФЛИКТ","ЗАРПЛАТА","ЗАВ","ПИКА","ТОПМЕНЕДЖЕР","ОДНОКЛАССНИК","НЕОЖИДАННОСТЬ","МАГИСТРАТУРА","ОСЛОЖНЯТЬ.pf","МАНИФЕСТ","ПАРАЛЛЕЛЬ","РЕНТА","ДИСКОНТ","ПОДКОМИТЕТ","ДИАБЕТ","ЭКС-ЛИДЕР","БИРЖА","ЛОГОТИП","ФЛАГ","УНИЖЕННОСТЬ","ИО","ГОСЭКЗАМЕН","ГД","ЗАМПРЕЗИДЕНТА","ГРАФА","СОБКОР","РЕКОРДСМЕН","СМС","ДРУЖОК","АБОРИГЕН","ФАВОРИТ","РАЦИОН","ИДТИ.ipf","ГОРМОН","СКАНДАЛ","ШАБЛОН","ГЕНЕРАЛ-ГУБЕРНАТОР","ЭКСПЕРТИЗА","БАТЬКА","ОТКРЫВАТЬ.ipf","РАЗНОВИДНОСТЬ","КЛАССИКА","АКСИОМА","МАТЕМАТИКА","ОРФОГРАФИЯ","МОРФОЛОГИЯ","ФОНЕТИКА","ЖЮРИ","ПРЕЙСКУРАНТ","КНИЖКА","ЭФИР","КАРТИНКА","ФАСОН","ЭКСПЕРТ","ДОБРО","СОЛЬ","ЦНИИ","ДЛИНА","ТРАВЕРС","МАРШРУТ","ЦИК","СЕКЦИЯ","МАСТЕРСТВО","ПРИЗЕР","ИНТЕРНАТ","ТЕХНОЛОГ","ПЕДАГОГИКА","СКЕПСИС","РЕЗЕРВ","ПОДРУЖКА","КРОХА","ТЕЛЕСЕРИАЛ","НОТА","ПРИТЧА","ТЕНДЕР","ЧАСТОТА","КАТАЛОГ","ХАРАКТЕР","ЙОДИД","УСТРАИВАТЬ.ipf","ОТЧИМ","БАБУШКА","ПРАДЕДУШКА","ДИАМЕТР","ЭСКИЗ","ДЕТАЛЬ","АНТИПОД","ДАЧА","ПАТЕНТ","ФИЛЬТР","СЕКТОР","АДЪЮНКТ","СТЕПЕНЬ","КЛАССИК","ФАБРИКА","КОМПРОМИСС","МАСТЕРСКАЯ","САЙТ","ТЕНЬ","МОНОПОЛИСТ","ХАДИС","ПРИНЦЕССА","КИНЕТИКА","ДИАПАЗОН","ПОТОЛОК","ТОРМОЗ","МОЗАИКА","ЭКОСИСТЕМА","ЗНАЧОК","СТАВИТЬ.pf","ВЕРСТКА","РУИНА","ЭТАП","ТЕОРЕТИК","ПРИОР","ПРАПРАДЕД","БРАК","ГЕРЦОГ","НОВОСТЬ","ВНУК","ПРАХ","ПЕДАГОГ","ПОЛИС","ГОРСОВЕТ","СПЕЦКОР","ИЗБИРКОМ","РЕДАКТУРА","ДУМА","ПРОЖЕКТ","ПРОФСОЮЗ","ОКЕАНОГРАФИЯ","ЛОЦИЯ","ФЛАГМАН","ГЕНЕРАЛ","МЕМОРАНДУМ","СОЛДАТ","УПРАВДЕЛ","ВОЗРАСТ","ПЛАНТАЦИЯ","МУНИЦИПАЛИТЕТ","ДЦП","ГЕНПЛАН","КРЕДИТОР","ДЕКРЕТ","БОГАТСТВО","СЕМЕЙСТВО","КАНЦЛЕР","ЦИТАДЕЛЬ","ВМФ","НАПРАСЛИНА","МОСТИК","ЧЕЛОБИТНАЯ","ОРГКОМИТЕТ","ЗАВОРГОТДЕЛОМ","ГОРКОМ","ЭМБРИОН","ОДНОСЕЛЬЧАНИН","ПРОСТРАНСТВО","ТЕРРИТОРИЯ","ОРГАНИЧНОСТЬ","СЛОВЕЧКО","МАНДАТ","ВОТУМ","ОРИГИНАЛ","НЕСЧАСТЬЕ","СИНОНИМ","КНЯЗЬ","БРИГАДИР","АТАМАН","ВОЙСКО","ФЕЛЬДМАРШАЛ","ПОЧЕСТЬ","ЭКСКУРС","ШАНСИК","БИБЛИОТЕКА","БЕНЕФИЦИАР","ЭЛЕМЕНТ","ТРАНСЛЯТОР","РОДНЫЕ","СХОЛАСТИКА","ЭПИГРАФ","НЕТОЧНОСТЬ","ВИДЕОМАТЕРИАЛ","ГОРЕЧЬ","РАССАДНИК","РАЗВЕДДАННЫЕ","ИНТЕРЕСЫ","ПРАПРАДЕДУШКА","КУМИР","БОЛЬШИНСТВО","КЛАСТЬ.pf","ОБРЯД","ПРАЗДНИК","КОСМОЛОГИЯ","ПРЕДИСЛОВИЕ","КОНСЕНСУС","ПОДМАСТЕРЬЕ","ПРАВОТА","ВАКЦИНА","ОТКРЫВАТЬ.pf","БУМ","ТЕЛОХРАНИТЕЛЬ","КОМПРОМАТ","РЕЙД","ПОЛИТРУК","КАПИТАН","СПЕЦСООБЩЕНИЕ","СЕРЖАНТ","ТРЕЩИНА","ФИГУРАНТ","ЭНТУЗИАЗМ","ГУРУ","ГЛАВВРАЧ","ВРИО","БАТАЛИЯ","ТАКСИ","ГРАФИКА","ЛЕГКОСТЬ","САМЕЦ","ПТИЦА","ДИАЛЕКТ","ТРАНСИНДУСТРИЯ","ЭФФЕКТ","ЭКВИВАЛЕНТ","БОНУС","СТАТУТ","МЕДАЛЬ","КОМЕНДАНТ","РЯДОВОЙ","ЯМОЧКА","ОКНО","ГАУЛЯЙТЕР","КАРИКАТУРА","СЛАБОСТЬ","ПРОТЕЗ","ФСНП","ПОЛИЦИЯ","МЧС","ТРАВМА","ФЕТВА","ГОССОВЕТ","РУКОПИСЬ","ВДВ","ТЕРАКТ","НОРВЕГИЯ","МЕКСИКА","ОМАН","АНГОЛА","СЕКРЕТАРИАТ","ГРАНИЦА","ГОСДУМА","ГЕНПРОКУРАТУРА","СЕВЕРО-ВОСТОК","ОБОЧИНА","ТУРНЕ","ГЛАВКОМ","ХОЗЯЙКА","МИЛИЦИЯ","ФОТОРОБОТ","ПЕРСОНАЛ","БУРГОМИСТР","ЭКС-ЧЕМПИОН","ЭКС-ПРЕЗИДЕНТ","ГРУППА","РАЙОТДЕЛ","МЭРИЯ","ОРДЕН","УВД","ГУ","РЕЙС","ГО","ПРОЦЕНТ-ЗНАК","ХУРАЛ","ВЗЯТКА","МИД","ОРДЕР","ЮГО-ВОСТОК","ГИБДД","ВИЦЕ-МЭР","ТИП","АГРЕССИЯ","МВД","ПАСЫНОК","КРЕН","НЕУДОБСТВО","ГЕНШТАБ","РЯД","ПАНИКА","АВИАРЕЙС","ФРОНТ","КОРИДОР","ПАРАМЕТР","ЧРЕЗМЕРНОСТЬ","РЕБРО","ЖЕСТ","ГРЯДКА","СЛЕПОК","СПАЗМ","РАЗУМ","ДЕНЬ","УГОЛОК","СЕМЬЯ","НЕКРОЛОГ","ГОСПОДСТВО","ОБЛОЖКА","РУБЛЬ","ЛИЦО","ОМОНИМ","ПИРОГ","КУСОК","ЛЕПТА","ЛИНИЯ","МОЛОДОСТЬ","СОЛДАТИК","ИМЯ","ДУШОК","ДВЕРЬ","ТЕЛО","ПОЯСОК","СУДЬБА","ХВОСТ","ОБРАЗ","УХО","ЛУЖИЦА","ОСОБЕННОСТЬ","ДОМ","КРАЙ","СТОРОНА","ЭПОХА","ХЛОПЬЯ","КРОШКА","НОСОК","ГЛАЗ","МНОЖЕСТВО","ОСАНКА","ДВОРНИК","КАПЕЛЬКА","БОЧКА","ВЕЛИЧИНА","КРУЖКА","СПИНА","СТОЛБ","СКЛАДКА","РУКА","МАНЕР","ДУША","РЕЗУЛЬТАТ","СПИСОК","ЛИЧНОСТЬ","СФЕРА","УГОДА","ОБЛАСТЬ","КРЫША","МИНПРОС","ГОСКОМИТЕТА","ФРАГМЕНТ","ОКИСЕЛ","МЛН","ИСТОЧНИК","ОТРАСЛЬ","ЭВТРОФИКАЦИЯ","КОРПУНКТ","ГОРОД","СУДАК","ЭЛИКСИР","ОТСТОЙНИК","БЕДА","ОБКОМ","РАЙКОМ","КОНЕЦ","ВЕТВЬ","ИЗЪЯН","ПАРТКОМ","УДАРНИК","РЕГИОН","МИКРОВАРИАНТ","МАЯК","НЕУКОМПЛЕКТОВАННОСТЬ","ЗОНА","СУТЬ","КРУГ","ПОВЕРХНОСТЬ","УЧАСТОК","ПОРЦИЯ","СТРАНИЦА","СЛОЙ","МАССА","КУБОМЕТР","ЯКОРЬ","ТЬМА","ЗОЛЬНОСТЬ","СТРУЯ","ОЧАГ","АРСЕНИД","ФОСФОРИДА","ПРОПАГАНДИСТ","ПОДЛОЖКА","ЛИТР","МИКРОГРАММ","МЕТР","КГ","ИЗЛИШЕК","ТОРЕЦ","КАРБОНИТРИД","НИТРИД","25-ЛЕТИЕ","НЕДРА","ОБОЛОЧКА","ПРОЦЕНТ","СОВЕРШЕНСТВО","СО","ПУЗЫРЕК","БОРТ","ДЕТИЩЕ","УЙМА","КОМПЛЕКС","ЧАСТИЦА","ПОЛИОКСИСОЕДИНЕНИЕ","РЕЦЕПТУРА","МАРКА","ГИДРАТ","СРОДСТВО","ОКИСЬ","КАТИОН","СКОРОСТЬ","СУЩЕСТВО","ПАР","ПРИВИЛЕГИЯ","МЯГКОСТЬ","УНИСОН","ПАЛАЧ","ДОВЫБОРЫ","ВЕРХОВЕНСТВО","ДИАЛЕКТИКА","КРЕСТЬЯНИН","ИМПЕРАТОР","ГИМН","КУПОЛ","ОКОШКО","ЛИСТВА","КУСОЧЕК","ЗАДОК","ЛЕПЕШКА","БУТЫЛКА","БИДОН","БОТВА","ЧАША","ГИРЛЯНДА","ПЛОТЬ","ВОРОТНИЧОК","КОМОК","ОСКОЛОК","ВЕТКА","ЯГОДА","ПОДНОЖИЕ","СЕРДЦЕ","ПРИСТАНИЩЕ","МИР","ЦВЕТОК","БЕРЕГ","ЗАРОСЛЬ"]

def upcase?(string)
    !string[/[[:lower:]]/]
end

def find_number(w)
  lemma = w['LEMMA']
  if SING.include?(lemma)
    a = 's'
  elsif PLUR.include?(lemma)
    a = 'p'
  else
    #STDERR.puts "What number for #{lemma}?"
  end
  return a
end

def find_person(w)
  lemma = w['LEMMA']
  if FIRST.include?(lemma)
    a = '1'
  elsif SECOND.include?(lemma)
    a = '2'
  elsif THIRD.include?(lemma)
    a = '3'
  else
    #STDERR.puts "What person for #{w.inner_text.chomp}?"
  end
  return a
end


def casus(feats)
  ['ИМ','РОД','ПАРТ','ДАТ','ВИН','ТВОР','ПР','МЕСТН','ЗВ'].each do |c|
    if feats.include?(c)
      return c
    end
  end
end

def casus?(feats)
  ['ИМ','РОД','ПАРТ','ДАТ','ВИН','ТВОР','ПР','МЕСТН','ЗВ'].include?(casus(feats))
end

def gender(feats)
 ['МУЖ','ЖЕН','СРЕД'].each do |g|
    if feats.include?(g)
      return g
    end
  end
end

def gender?(feats)
  ['МУЖ','ЖЕН','СРЕД'].include?(gender(feats))
end

def number(feats) 
  ['ЕД','МН'].each do |n|
    if feats.include?(n)
      return n
    end
  end
end

def number?(feats)
 ['ЕД','МН'].include?(number(feats))
end


def degree(feats)
 ['СРАВ','ПРЕВ'].each do |d|
    if feats.include?(d)
      return d
    end
  end
end
#TODO! no marking for positive! Additional смяг marking for поумнее etc

def degree?(feats)
  ['СРАВ','ПРЕВ'].include?(degree(feats))
end

def strength(feats)
  if feats.include?('КР')
    return 'КР'
  end
end

def strength?(feats)
  strength(feats) == 'КР'
end
#TODO! no marking for LF!

def mood(feats)
['ИНФ','ПРИЧ','ДЕЕПР','ИЗЪЯВ','ПОВ'].each do |m|
    if feats.include?(m)
      return m
    end
  end
end

def mood?(feats)
  ['ИНФ','ПРИЧ','ДЕЕПР','ИЗЪЯВ','ПОВ'].include?(mood(feats))
end

def tense(feats)
 ['НЕПРОШ','ПРОШ','НАСТ'].each do |t|
    if feats.include?(t)
      return t
    end
  end
end
#TODO! наст is only for есть, суть

def tense?(feats)
  ['НЕПРОШ','ПРОШ','НАСТ'].include?(tense(feats))
end

def person(feats)
  ['1-Л','2-Л','3-Л'].each do |p|
    if feats.include?(p)
      return p
    end
  end
end

def person?(feats)
 ['1-Л','2-Л','3-Л'].include?(person(feats))
end

#medium rule probably slightly overgenerates, could capture non-reflexive gerunds and imperatives, I suppose
def voice(w,feats)
  if feats.include?('СТРАД')
    a = 'p'
  elsif ['ся','сь'].include?(w.inner_text.chomp[/..\z/])
    a = 'm'
  else a = 'a'
  end
  return a
end

def aspect(feats)
  if feats.include?('СОВ')
    a ="pf"
  elsif feats.include?('НЕСОВ')
    a = "ipf"
  else
    #STDERR.puts "no aspect for #{feats}" 
  end
  return a
end

def asplem(w,feats)
  if ['pf','ipf'].include?(aspect(feats))
    a = "#{w['LEMMA']}.#{aspect(feats)}"
  else
    a = w['LEMMA']
  end
  return a
end
#=begin #2019CORR
varnouns = File.open('posfreq.csv')

LEMMAFREQ = []

varnouns.each_line do |l|
  f = l.split(',')
  LEMMAFREQ << [f[0], f[1].to_i, f[2].chomp.to_i]
end

#this function checks every sentence-initial noun against a frequency list, going by the majority ruling to decide if it's Ne or Nb (Nb as default)
def firstnoun(w)
  LEMMAFREQ.each do |f|
    if w['LEMMA'] == f[0]
      if f[1] == 0
        @a = 'Ne'
      elsif f[2] == 0
        @a = 'Nb'
      elsif f[2] > f[1]
        @a = 'Ne'
      else
       @a = 'Nb'
      end
    else #RIGHT?
	  @a = 'Nb'
	end
  end
  return @a
end
#=end CORR2019

def pos(w,s)
  feats = w['FEAT'].to_s.split
  form = w.inner_text.chomp
  if feats[0] == 'S'
    if PP.include?(w['LEMMA'])
      a = 'Pp'
    elsif PI.include?(w['LEMMA'])
      a = 'Pi'
    elsif PR.include?(w['LEMMA'])
      a = 'Pr'
    elsif PK.include?(w['LEMMA'])
      a = 'Pk'
    elsif PX.include?(w['LEMMA'])
      a = 'Px'
    elsif PD.include?(w['LEMMA'])
      a = 'Pd'
	elsif PSEUDONUMERALS.include?(w['LEMMA'])  
	  a = 'Ma'
    elsif w['ID'] != '1' and w['NODETYPE'] != 'FANTOM' and upcase?(form.split(//).first) 
      a = 'Ne'
    elsif w['ID'] == '1' and w['NODETYPE'] != 'FANTOM'
      a = firstnoun(w)
    else
      a = 'Nb'
    end
  elsif feats[0] == 'A'
    if PS.include?(w['LEMMA'])
      a = 'Ps'
    elsif PT.include?(w['LEMMA'])
      a = 'Pt'
    elsif PD.include?(w['LEMMA'])
      a = 'Pd'
    elsif MO.include?(w['LEMMA'])
      a = 'Mo'
    elsif PI.include?(w['LEMMA'])
      a = 'Pi'
    elsif PX.include?(w['LEMMA'])
      a = 'Px'              
    else
      a = FT[feats[0]]
    end
  elsif feats[0] == 'ADV'
    if DU.include?(w['LEMMA']) and not(w['LEMMA']=="СКОЛЬКО" and w['LINK']=="сочин")
      a = 'Du'
	elsif (w['LEMMA']=="СКОЛЬКО" and w['LINK']=="сочин")  #сколько is actually treated as a conjunction in a construction сколько-столько
      a = 'C-'      	
    else
      a = FT[feats[0]]
    end
  elsif feats[0] == 'CONJ'
    if (w['LEMMA']=="ТО" and w['LINK']=="соотнос")
	  a = "Df"
	elsif CONJS.include?(w['LEMMA']) or (w['LEMMA']=="КАК" and w['LINK']=="соотнос") #Redefined in this way, since the syntactic definition gives false positives (и чтобы левая рука не знала -- чтобы becomes a "C-") 
      a = FT[feats[0]] #conjunction
	elsif w['LEMMA']=="КОГДА" #TODO2016: add more lemmas here
      a = "Dq"	
	else
      a = 'G-' #subjunction
    end
  else
    a = FT[feats[0]]
  end
  return a
end

#TODO: all comparatives now come out as weak, is that OK?
#TODO: tease out ordinals from adjective class - done up to сотый
#TODO: tease out proper nouns from noun class - mostly done
#TODO: when I tried the script on "I slepye prozreyut" it threw an unexplained validation error ("invalid tag"), so there is something not quite right here - maybe a syntactic tag? 
#gerunds have mood, tense, voice in rus_morphology.yml
#eliminated tense for infinitives in rus_morphology.yml
#note that ordinals don't have strength in rus_morphology.yml, nor in orv. Reasonable for rus, but maybe not for orv.
#Df: currently setting all adverbs that are unmarked for degree as non-inflecting (this looks less silly than having all of them as positive) - or is the PART category good enough to allow us to let the remaining Df be positive if unmarked?
#Dq: currently introducing no relative adverbs, we need to think about the syntax here. Are there obvious candidates that can't also be interrogative adverbs? In the morphology it should just go directly to else > non-inflecting.
#G-: currently just stated that every CONJ except those that don't have the LINK attribute (sentence-initial conjunctions) and those that have one of the coordinating relationships are subjunction (G-). need to add the sootnos relation AB: Changed that, see above
#Pc: currently ignoring reciprocal pronouns (друг друга), they need to be captured by word order pattern. We wouldn't die if they remained nouns either. #DONE, convert_vspom converts them to Pc
#Ma: currently only NUMs, тысяча, for instance, is still a noun. We may want to keep it like that. Gender and number set to unspecified unless otherwise stated. Note that несколько is a numeral in the syntagrus analysis, we'd want it to be a quantifier, perhaps.
#Py: currently not in use, but consider (and consider introducing it in TOROT, too!)


def morphtag(w,s)
  feats = w['FEAT'].to_s.split
  tag =[]
  if ['Nb','Ne'].include?(pos(w,s))
    tag << '-'
    tag << (number?(feats) ? FT[number(feats)] : 'x')
    tag << '---'
    tag << (gender?(feats) ? FT[gender(feats)] : 'x')
    tag << (casus?(feats) ? FT[casus(feats)] : 'x')
    tag << '--i'
  elsif pos(w,s) == 'V-'
    if FT[mood(feats)] == 'i' 
      if FT[tense(feats)] == 'u'
        tag << '-'
        tag << (number?(feats) ? FT[number(feats)] : 'x')
        tag << 's'
        tag << 'p' #sic?!
        tag << voice(w,feats)
        tag << (gender?(feats) ? FT[gender(feats)] : 'x')
        tag << 'n-si'
      elsif w['LEMMA'] == 'БЫТЬ'
        tag << (person?(feats) ? FT[person(feats)] : 'x')
        tag << (number?(feats) ? FT[number(feats)] : 'x')
        if feats.include?('НЕПРОШ')
          tag << 'f'
        else
          tag << (tense?(feats) ? FT[tense(feats)] : 'x')
        end
        tag << 'i'
        tag << voice(w,feats)
        tag << '----i'
      else
      tag << (person?(feats) ? FT[person(feats)] : 'x')
      tag << (number?(feats) ? FT[number(feats)] : 'x')
      tag << (tense?(feats) ? FT[tense(feats)] : 'x')
      tag << 'i'
      tag << voice(w,feats)
      tag << '----i'
      end
    elsif FT[mood(feats)] == 'm'
      tag << (person?(feats) ? FT[person(feats)] : 'x')
      tag << (number?(feats) ? FT[number(feats)] : 'x')
      tag << 'pm'
      tag << voice(w,feats)
      tag << '----i'
    elsif FT[mood(feats)] == 'n'
      tag << '---n'
      tag << voice(w,feats)
      tag << '----i'
    elsif FT[mood(feats)] == 'd'
      tag << '--'
      tag << (tense?(feats) ? FT[tense(feats)] : 'x')
      tag << 'd'
      tag << voice(w,feats)
      tag << '----i'
    elsif FT[mood(feats)] == 'p'
      tag << '-'
      tag << (number?(feats) ? FT[number(feats)] : 'x')
      tag << (tense?(feats) ? FT[tense(feats)] : 'x')
      tag << 'p'
      tag << voice(w,feats)
      tag << (gender?(feats) ? FT[gender(feats)] : 'x')
      if strength?(feats)
	    tag << 'n'
	  else
	    tag << (casus?(feats) ? FT[casus(feats)] : 'x') #x>n
      end
	  tag << '-'
      tag << (strength?(feats) ? FT[strength(feats)] : 'w')
      tag << 'i'
    else 
	  tag << '---------n'
	end
  elsif pos(w,s) == 'A-'
    tag << '-'
    tag << (number?(feats) ? FT[number(feats)] : 's')
    tag << '---'
    tag << (gender?(feats) ? FT[gender(feats)] : 'x')
    if strength?(feats)
	  tag << 'n'
	else
	  tag << (casus?(feats) ? FT[casus(feats)] : 'x') 
	end	
	  
    tag << (degree?(feats) ? FT[degree(feats)] : 'p')
    tag << (strength?(feats) ? FT[strength(feats)] : 'w')
    tag << 'i'
  elsif ['Mo','Pr','Px','Pd','Pi'].include?(pos(w,s))
    tag << '-'
    tag << (number?(feats) ? FT[number(feats)] : 'x')
    tag << '---'
    tag << (gender?(feats) ? FT[gender(feats)] : 'x')
    tag << (casus?(feats) ? FT[casus(feats)] : 'x') #x>n
    tag << '--i' 
  elsif pos(w,s) == 'Df'
    if degree?(feats)
      tag << '-------'
      tag << FT[degree(feats)]
      tag << '-i'
    else
      tag << '---------n'
    end
  elsif ['Ps','Pt'].include?(pos(w,s))
    tag << find_person(w)
    tag << (number?(feats) ? FT[number(feats)] : 'x')
    tag << '---'
    tag << (gender?(feats) ? FT[gender(feats)] : 'x')
    tag << (casus?(feats) ? FT[casus(feats)] : 'x') #x>n
    tag << '--i'
  elsif ['Pp','Pk'].include?(pos(w,s))
    tag << find_person(w)
    tag << find_number(w)
    tag << '---'
    tag << (gender?(feats) ? FT[gender(feats)] : 'x')
    tag << (casus?(feats) ? FT[casus(feats)] : 'x') #x>n
    tag << '--i'
  elsif pos(w,s) == 'Ma'
    tag << '-'
    tag << (number?(feats) ? FT[number(feats)] : 'x')
    tag << '---'
    tag << (gender?(feats) ? FT[gender(feats)] : 'x')
    tag << (casus?(feats) ? FT[casus(feats)] : 'x') #x>n
    tag << '--i'
  else
    tag << '---------n'
  end
return tag.join   
end

def reltag1(rel) #converts the relation, given the relation tag as an argument
  RELATIONS1[rel]
end


OGRANADV = ["УЖЕ","ВОТ","ВСЕ","ВСЕГО","ОЧЕНЬ","КАК БУДТО","ТАК","ПРОСТО","ВОВСЕ","ВПОЛНЕ","КАК РАЗ",'ВСЕМИРНО','ДОВОЛЬНО','ДЕЙСТВИТЕЛЬНО','ДАЛЕКО','ВСЕ-ТАКИ','ИСКЛЮЧИТЕЛЬНО','СОВЕРШЕННО','ЧАСТИЧНО','ФАКТИЧЕСКИ','НАИБОЛЕЕ','ТО ЕСТЬ','СЛЕГКА','СКОЛЬ','ТО ЕСТЬ','СОВСЕМ','ПРАКТИЧЕСКИ','ОСОБЕННО','ВЕСЬМА','ДОСТАТОЧНО','ОТНОСИТЕЛЬНО','РАНЕЕ','НАПРИМЕР','СКОЛЬКО-НИБУДЬ','РАЗВЕ ЧТО','ИМЕННО','СУЩЕСТВЕННО','БОЛЕЕ','РАНЕЕ','МАКСИМАЛЬНО','ДАВНО','ПРИМЕРНО','БУКВАЛЬНО','НЕМНОГО','КАК МИНИМУМ','АБСОЛЮТНО','ПРЕЖДЕ ВСЕГО','ПРЕДЕЛЬНО','СЛИШКОМ','ПО МЕНЬШЕЙ МЕРЕ','НЕОГРАНИЧЕННО','ВСЕ РАВНО','ПРИНЦИПИАЛЬНО','НАСТОЛЬКО','ЧАСТИЧНО','СКОРЕЕ','СМЕРТЕЛЬНО','ПОПРОСТУ','НЕОТЪЕМЛЕМО','РОВНО','СПЕЦИАЛЬНО','СТРАШНО','ПОСТОЯННО','ТОЛЬКО-ТОЛЬКО','ХИМИЧЕСКИ','КАРДИНАЛЬНО']
#this is silly, must make inventory of aux candidates instead, they are closed-class

PSEUDONUMERALS = ["ТЫСЯЧА", "МИЛЛИОН", "СОТНЯ", "МИЛЛИАРД", "БИЛЛИОН", "ТРИЛЛИОН", "ДЮЖИНА", "ДЕСЯТОК", "ДЕСЯТКА", "ДВАДЦАТОК", "ДВАДЦАТКА", "КВАДРИЛЛИОН"]
#noun-like numerals. If these have kvaziagent, it should go to PART, not to ATR

NOMINALS = ['Nb','Ne','Pp','Pd','Px','Pi','Pk','Ps','Pt','Pc','Pr','A-','Ma','Mo','F-'] #add more

XVERBS = ['ЯВЛЯТЬСЯ.ipf','КАЗАТЬСЯ.ipf','ОПАЛЯТЬСЯ.pf','НАЗЫВАТЬ.ipf','НАЗЫВАТЬ.pf','ДЕЛАТЬ.ipf','ДЕЛАТЬ.pf','СЧИТАТЬ.ipf','СЧИТАТЬ.pf','ДЕРЖАТЬ.ipf','НАЗНАЧАТЬ.pf','ПРОЗЫВАТЬ.pf','ЗВАТЬ.ipf','ПРИЗНАВАТЬ.pf','ПРИЗНАВАТЬ.ipf','ПРИЗНАВАТЬ.pf','ХАРАКТЕРИЗОВАТЬ.ipf','ПРОВОЗГЛАШАТЬ.pf','ОБЪЯВЛЯТЬ.ipf','ДИСКРЕДИТИРОВАТЬ.pf','ПРЕДСТАВЛЯТЬ.ipf','ПРЕДСТАВЛЯТЬ.pf','ОБОЗНАЧАТЬ.pf','СТАВИТЬ.pf'] #verbs that take instrumental XOBJ, lots added to capture the non-1-kompls

QUANT = ['СКОЛЬКО','СТОЛЬКО','МНОГО','МАЛО','БОЛЬШЕ','НЕМАЛО','СТОЛЬКО-ТО','МНОГО']

GENVERBS = ['КАСАТЬСЯ','ЖДАТЬ.ipf','ОЖИДАТЬ.ipf','КАСАТЬСЯ.ipf','ПРИДЕРЖИВАТЬСЯ.ipf','ДОСТИГАТЬ.pf','ТРЕБОВАТЬ.ipf','НАБИРАТЬСЯ.pf','ТРЕБОВАТЬ.pf','НАБИРАТЬ.pf','ДОЖИДАТЬСЯ.pf','НАПИВАТЬСЯ.pf','ЛИШАТЬСЯ.pf','ДОБИВАТЬСЯ.pf','ИЗБЕГАТЬ.pf','БОЯТЬСЯ.ipf','ИЗБЕГАТЬ.ipf','ДОБИВАТЬСЯ.ipf','СТРАШИТЬСЯ.ipf','ЖАЛЕТЬ.pf','НАЧИТЫВАТЬСЯ.pf','ДОИСКИВАТЬСЯ.ipf','СТОИТЬ.ipf','ДОСТИГАТЬ.ipf','ДОЖИДАТЬСЯ.ipf','ЖЕЛАТЬ.ipf','КАСАТЬСЯ.pf','ЖАЖДАТЬ.ipf','ЛИШАТЬ.pf','ХОТЕТЬСЯ.ipf','ЛИШАТЬ.ipf','УДОСТАИВАТЬ.pf','ДОВЕРЯТЬ.pf']

#true_dep method currently not in use and also insufficient

def true_dep(id,daughterid,dpos,allthedaughters)
  if dpos[daughterid] == 'C-'
    td = allthedaughters[daughterid]
  else
    td = allthedaughters[id]
  end
end

def true_head(id,dpos,dhead_id)
  if dpos[dhead_id[id]] == 'C-'
    th = true_head(dhead_id[id],dpos,dhead_id)
  else
    th = dhead_id[id]
  end
end

def morph_features(id,dmorph)
  dmorph[id].split(//) if dmorph[id]
end

def cas(id,dmorph)
  morph_features(id,dmorph)[6]
end

def md(id,dmorph)
  morph_features(id,dmorph)[3]
end

def tns(id,dmorph)
  morph_features(id,dmorph)[2]
end

def negated?(id,dpos,dlemma,dhead_id,allthedaughters,dmorph)
  allthedaughters[id].select {|d| ['НИ','НЕ'].include?(dlemma[d])}.any? or (true_head(id,dpos,dhead_id) and dpos[true_head(id,dpos,dhead_id)] == 'V-' and md(id,dmorph) == 'n' and allthedaughters[true_head(id,dpos,dhead_id)].select { |hd| ['НИ','НЕ'].include?(dlemma[hd])}.any?) or (allthedaughters[id].select {|d| ['НИКТО','НЕЧЕГО','НИЧТО'].include?(dlemma[d])}.any?)
end

#tree-changing things (not yet implemented) in the 1-kompl conversion:
#direct speech (separate sentence or PARPRED) #AB: note that this has already been done for direct speech utterances beginning with conjunctions (dirspeech_conj)
#вместе с: if we are to emulate OCS коупьно съ, вместе should be an ADV on the preposition. We could choose to be lazy and just allow вместе to be OBL - it makes perfect sense – that's what I've currently done
#should we default около to OBJ? at least when coordinated with an accusative? Same for до?
#coordinating как ... так и: made так и a conjunction, but am reluctant to make all CONJ как conjunctions, since the comparison ones are also in this group

def reltag2(rel,id,daughterid,dlemma, sentence_id,dmorph, empty_tokens,did,dhead_id,drel,dpos,allthedaughters,drel_old) #id is the outgoing node, daughterid is the incoming one
    case rel
    when "квазиагент" then
      if PSEUDONUMERALS.include?(dlemma[id])
        rel="part"
      else
        rel =  RELATIONS2[rel]
      end
    when "соч-союзн" then
      @flags.puts "#{sentence_id}, 1B, loose соч-союзн"
	  if !@excluded_sentences.include?(sentence_id)
		@excluded_sentences << sentence_id
	  end
      rel =  RELATIONS2[rel]
    when "огранич" then
      if OGRANADV.include?(dlemma[daughterid]) or (dpos[daughterid] == 'C-' and (OGRANADV & allthedaughters[daughterid].map {|d| dlemma[d]}).any?)  #used intersection of arrays + any?, works, see Byt_modnym.48 - don't think we need to use the conjunct method here, these are unlikely to be stacked
        if ['Ne','Nb'].include?(dpos[id])
          rel = 'atr'
        else
          rel = 'adv'
        end
      else
        rel = 'aux'
      end
    when "1-компл", "2-компл", "3-компл", "4-компл", "5-компл" then
      feats = dmorph[daughterid].split(//) if dmorph[daughterid]
      conjuncts = return_all_conjuncts(godown=[],check=[],daughterid,dpos,allthedaughters,sentence_id,drel) if dpos[daughterid] == 'C-'
      if dpos[id] == 'V-'
        if NOMINALS.include?(dpos[daughterid]) or (dpos[daughterid] == 'C-' and (conjuncts.map {|c| dpos[c]} & NOMINALS).any?) #include more in NOMINALS?
          if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.map {|c| dpos[c]}.reject { |p| NOMINALS.include?(p)}.any?
		    @flags.puts "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl" 
		    if !@excluded_sentences.include?(sentence_id)
		      @excluded_sentences << sentence_id
		    end
		  end
		  
          casus = cas(daughterid,dmorph)
          if casus == 'a' or (conjuncts and conjuncts.map {|c| cas(c,dmorph)}.include?('a'))
             
            if rel == '1-компл' #пролежать год is OBL
              rel = 'obj'
            else rel = 'obl'
            end
          elsif casus == 'i' or (conjuncts and conjuncts.map {|c| cas(c,dmorph)}.include?('i'))
            if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.map {|c| dpos[c]}.reject { |p| NOMINALS.include?(p)}.any?
			  @flags.puts "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl"
			  if !@excluded_sentences.include?(sentence_id)
         	    @excluded_sentences << sentence_id
		      end
			end
			
            if XVERBS.include?(dlemma[id])
              rel = 'xobj'
            else
              rel = 'obl'
            end
          elsif casus != 'g' or (conjuncts and !conjuncts.map {|c| cas(c,dmorph)}.include?('g'))
            if (casus == 'x' or (conjuncts and conjuncts.map {|c| cas(c,dmorph)}.include?('x'))) and rel == '1-компл' and !GENVERBS.include?(dlemma[id])
                #mostly numerals - could erroneously include some dative or instrumental verb 1-kompls, but this will do for now
                rel = 'obj'
              else
                rel = 'obl'
              end
          elsif negated?(id,dpos,dlemma,dhead_id,allthedaughters,dmorph) and !GENVERBS.include?(dlemma[id]) and rel == '1-компл' #filter for genitive verbs is perhaps a bit rigid, but tried to leave the variation verbs out.
            rel = 'obj'
          elsif GENVERBS.include?(dlemma[id])
            rel = 'obl'
          else
            @flags.puts "#{sentence_id}, #{dlemma[id]} has genitive object #{dlemma[daughterid]}"
           
            #includes some partitives, some misannotated genitive-accusatives, some variation verbs
            rel = 'obj'
          end
        elsif dpos[daughterid] == 'R-' or (dpos[daughterid] == 'C-' and conjuncts.map { |c| dpos[c]}.include?('R-'))
		  if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.map {|c| dpos[c]}.reject { |p| ['R-','Df'].include?(p)}.any?          
            @flags.puts "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl"
		    if !@excluded_sentences.include?(sentence_id)
		      @excluded_sentences << sentence_id
		    end
		  end
		  
          rel = 'obl' #overgenerates slightly, things like "во сне не сохранилось"
        elsif (1000..1030).to_a.include?(daughterid) and dpos[daughterid] == 'V-' #not checking for coordinations here, since coordinated null verbs will hopefully normally have a full verb conjunct?
           #STDERR.puts "#{sentence_id}, #{dlemma[id]} has a null verb daughter #{daughterid}"
          if ['МОЧЬ.ipf','СТАТЬ.pf'].include?(dlemma[id]) #more verbs here?
            rel = 'xobj' 
          elsif allthedaughters[daughterid].select { |d| ['Pi','Du'].include?(dpos[d])}.any?
            rel = 'comp' #this should get most of the indirect questions
          else
            @flags.puts "#{sentence_id}, null verb direct speech #{daughterid} after #{dlemma[id]}"
            rel = 'parpred' #the rest should mostly be direct speech
          end
        elsif dpos[daughterid] == 'V-' or (dpos[daughterid] == 'C-' and conjuncts.map { |c| dpos[c]}.include?('V-'))
          
          mood = feats[3]
          dmood = conjuncts.map { |d| md(d,dmorph)} if conjuncts
          tense = feats[2]
          dtense = conjuncts.map { |d| tns(d,dmorph)} if conjuncts
          if mood == 'n' or (conjuncts and dmood.include?('n'))
		    if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.reject { |c| dpos[c] == 'V-'}.any?
              @flags.puts "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl" 
              if !@excluded_sentences.include?(sentence_id)
		        @excluded_sentences << sentence_id
		      end
			end
            rel = 'xobj'
          elsif (mood == 'p' and tense != 's') or (conjuncts and dmood.include?('p') and !dtense.include?('s'))
            rel = 'obj' #no flagging of mixed conjuncts since coordinated examples are extremely rare
          elsif allthedaughters[daughterid].select { |p| ['Pi','Du'].include?(dpos[p])}.any? or (conjuncts and conjuncts.map { |c| allthedaughters[c]}.flatten.select { |cd| ['Pi','Du'].include?(dpos[cd]) }.any?) #not checking for mixed conjuncts
            #STDERR.puts "#{sentence_id}, #{dlemma[id]} has #{dlemma[daughterid]} with verbal COMP conjuncts" if dpos[daughterid] == 'C-'
            rel = 'comp'
           else
            @flags.puts "#{sentence_id}, #{dlemma[id]} has above-1-kompl PARPRED #{dlemma[daughterid]} (presumed direct speech)" unless rel == '1-компл'
            #STDERR.puts "#{sentence_id}, #{dlemma[id]} has #{dlemma[daughterid]} with verbal PARPRED conjuncts" if dpos[daughterid] == 'C-' #not checking for mixed conjuncts
            rel = 'parpred' #assumed to be direct speech
          end
        elsif dpos[daughterid] == 'G-' or (dpos[daughterid] == 'C-' and conjuncts.map { |c| dpos[c]}.include?('G-'))
		  if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.reject {|c| dpos[c] == 'G-'}.any?
		    @flags.puts  "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl" 
 		    if !@excluded_sentences.include?(sentence_id)
		      @excluded_sentences << sentence_id
		    end
		  end	
          rel = 'comp'
        elsif ['Du','Df'].include?(dpos[daughterid]) or (dpos[daughterid] == 'C-' and conjuncts.select {|c| ['Du','Df'].include?(dpos[c])}.any?)
		  if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.reject {|c| ['Du','Df'].include?(dpos[c])}.any?	
		    @flags.puts  "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl" 
  		    if !@excluded_sentences.include?(sentence_id)
		      @excluded_sentences << sentence_id
		    end
		  end
          if rel == '1-компл' and (QUANT.include?(dlemma[daughterid]) or (conjuncts and conjuncts.select {|c| QUANT.include?(dlemma[c]) }.any?)) #1-kompl quantifiers like мало, сколько are taken as OBJs, the rest defaulted to OBL #no check for mixed conjuncts necessary
            rel = 'obj'
          else
            rel = 'obl'
          end
        elsif dpos[daughterid] == 'I-' or (dpos[daughterid] == 'C-' and conjuncts.select { |c| dpos[c] == 'I-'}.any?)
          rel = 'voc'
        else
          #STDERR.puts "#{sentence_id}, #{dlemma[id]} has #{dpos[daughterid]} #{dlemma[daughterid]} defaulted to OBJ" #currently nothing goes here #AB: Now some things do (это дает им от 10 до 20 процентов прибыли)
          rel = RELATIONS2[rel]
        end
      elsif ['Ne','Nb'].include?(dpos[id])
        if dpos[daughterid]=="G-"
		  rel = "comp"
		elsif NONARG.include?(dlemma[id])
          rel = 'atr'
        else
          rel = 'narg' 
        end
      elsif QUANT.include?(dlemma[id]) #reason to be suspicious of the above-1-kompls again, but there are very few
         
        rel = 'part'
      elsif dpos[id] == 'Df' 
        #STDERR.puts dlemma[id]
        if NOMINALS.include?(dpos[daughterid]) or (dpos[daughterid] == 'C-' and conjuncts.select { |c| NOMINALS.include?(dpos[c])}.any?)

		  if dpos[daughterid] == 'C-' and conjuncts.any? and conjuncts.map {|c| dpos[c]}.reject { |p| NOMINALS.include?(p)}.any? 
		   @flags.puts "#{sentence_id}, #{daughterid} heads a #{conjuncts.map {|c| dpos[c]}.join('+')} coordination in n-kompl" 
		   if !@excluded_sentences.include?(sentence_id)
		     @excluded_sentences << sentence_id
		   end
		  end	

          rel = 'obl'
        elsif dpos[daughterid] == 'R-' or  (dpos[daughterid] == 'C-' and conjuncts.select { |c| dpos[c] == 'R-'}.any?) #no mixed conjunct check needed
          rel = 'obl' #does вместе с without conversion
        else 
          #STDERR.puts "#{dlemma[daughterid]} (#{dpos[daughterid]}) in #{sentence_id} is an unconvincing comp daughter of #{dlemma[id]}!" unless dpos[daughterid] == 'G-' or (dpos[daughterid] == 'C-' and conjuncts.select {|c| dpos[c] == 'G-'}.any?)
          rel = 'comp' #apart from subjunctions, there are a few infinitives  (вправе игнорировать)
        end
      elsif dpos[id] == 'Pd' #this solution seems mostly OK
        #STDERR.puts "#{dlemma[daughterid]} in #{sentence_id} is an unconvincing comp!" unless dpos[daughterid] == 'G-'
        rel = 'comp' #таким образом, что
      else #almost all are adjectives with arguments
        if ['V-','G-'].include?(dpos[daughterid]) or (conjuncts and conjuncts.select {|c| ['V-','G-'].include?(dpos[c])}.any?)
          #STDERR.puts "#{sentence_id}, #{dlemma[id]} has #{dlemma[daughterid]} COMP"
           rel = 'comp'
         else
          rel = 'obl' 
         end
      end
    when "обст" then
	  if dmorph[daughterid][3]=="d" or check_conjunct([],"substring",3,3,"yes",0,dmorph,"d",daughterid,dpos,allthedaughters,sentence_id) #check_conjunct_morphtag(allthedaughters,daughterid,dmorph,3,"d",dpos) #if it's a gerund 
        rel = "xadv"
      elsif dmorph[daughterid][3]=="n" or check_conjunct([],"substring",3,3,"yes",0,dmorph,"n",daughterid,dpos,allthedaughters,sentence_id) #if it's an infinitive 
        rel = "xadv"
      else
        rel = RELATIONS2[rel]
      end 	
    when "аналит" then	
      if (dlemma[id][0..3]=="БЫТЬ" and dmorph[id][2]=="f") or check_conjunct_new2(method1="equals",method2="substring",position11=0,position12=3,position21=2,position22=2,check_conflict="yes",check=[],dlemma,dmorph,"БЫТЬ","f",id,dpos,allthedaughters,sentence_id)
	    if dmorph[daughterid][3]!="n" and !check_conjunct([],"substring",3,3,"yes",0,dmorph,"n",daughterid,dpos,allthedaughters,sentence_id)
	      @flags.puts "#{sentence_id}, 1D, БЫТЬ-fut is governing not the infinitive, but something else (via analit)"
	    end
	    rel = "xobj"
      else  
	    rel = RELATIONS2[rel]
	  end
	when "сравнит" then	
      if dpos[id]=="V-" or  check_conjunct([],"equals",0,0,"yes",0,dpos,"V-",daughterid,dpos,allthedaughters,sentence_id)
	    rel = "adv"
	  elsif dpos[id]=="Ne" or dpos[id]=="Nb" or check_conjunct([],"equals",0,0,"yes",0,dpos,"Ne",daughterid,dpos,allthedaughters,sentence_id) or check_conjunct([],"equals",0,0,"yes",0,dpos,"Nb",daughterid,dpos,allthedaughters,sentence_id)		
	    rel = "atr"
      else  
	    rel = RELATIONS2[rel]
	  end  
	when "неакт-компл" then	
      if dpos[id]=="Ne" or dpos[id]=="Nb" or check_conjunct([],"equals",0,0,"yes",0,dpos,"Ne",daughterid,dpos,allthedaughters,sentence_id) or check_conjunct([],"equals",0,0,"yes",0,dpos,"Nb",daughterid,dpos,allthedaughters,sentence_id)
        if NONARG.include?(dlemma[id])
          if dpos[id] == 'V-'
            #STDERR.puts "#{dlemma[daughterid]} is OBL to #{dlemma[id]}"
            rel = 'obl'
          else
             #STDERR.puts "#{dlemma[daughterid]} is ATR to #{dlemma[id]}"
            rel = 'atr'
          end
        else
          rel = "narg"
        end
      else  
	    rel = RELATIONS2[rel]
	  end    
	else	#convert by default
      rel = RELATIONS2[rel]
    end  
end
	
def check_conjunct_new(godown=[],method="equals",position1=0,position2=0,check_conflict="no",check=[],darray,value,conj_id,dpos,allthedaughters,sentence_id)

  if dpos[conj_id]=="C-" and allthedaughters[conj_id][0]!=nil
    i=0
	begin
	  if method=="equals"
	    if darray[allthedaughters[conj_id][i]]==value
	      check << allthedaughters[conj_id][i]
	    end	
	  elsif method=="includes"
	    if darray[allthedaughters[conj_id][i]].include?(value)
		  check << allthedaughters[conj_id][i]
	    end	
	  elsif method=="substring"
	    if darray[allthedaughters[conj_id][i]][position1..position2]==value
		  check << allthedaughters[conj_id][i]
		end
	  end
		
	  if dpos[allthedaughters[conj_id][i]]=="C-"
	    godown << allthedaughters[conj_id][i]
	  end
	  i=i+1
	end until allthedaughters[conj_id][i]==nil
	
		
	if godown.length > 0
	  t=godown.shift
	  check_conjunct_new(godown,method,position1,position2,check_conflict,check,darray,value,t,dpos,allthedaughters,sentence_id)
	end
  end
  
  
  
  return check
  
end

def return_all_conjuncts(godown=[],check=[],conj_id,dpos,allthedaughters,sentence_id,drel)  
  if dpos[conj_id]=="C-" and allthedaughters[conj_id].any?
    i=0
	begin
	  if dpos[allthedaughters[conj_id][i]]=="C-" 
	    godown << allthedaughters[conj_id][i]		
	  else 
        if not(dpos[allthedaughters[conj_id][i]]=="Df" and drel[allthedaughters[conj_id][i]]=="aux")
		  check << allthedaughters[conj_id][i]	  
	    end	 
	  end
	  i=i+1
	end until allthedaughters[conj_id][i]==nil
	if godown.length > 0
	  t=godown.shift
	  return_all_conjuncts(godown,check,t,dpos,allthedaughters,sentence_id,drel)
	end
  end
  return check
end



def check_conjunct_new2(method1="equals",method2="equals",position11=0,position12=0,position21=0,position22=0,check_conflict="no",check=[],darray1,darray2,value1,value2,conj_id,dpos,allthedaughters,sentence_id)
  check2 = []
  res = check_conjunct_new([], method1, position11, position12,check_conflict,check,darray1,value1,conj_id,dpos,allthedaughters,sentence_id)
  res.each do |conjunct|
    if method2=="equals"
      if darray2[conjunct]==value2
	    check2 << conjunct
	  end	
	elsif method2=="includes"
	  if darray[conjunct].include?(value2)
	    check2 << conjunct
	  end	
    elsif method2=="substring"
	  if darray[conjunct][position21..position22]==value2
	    check2 << conjunct
      end
    end
  end
  
  if check2.length > 0
    return true
  else
    return false
  end
end

#BEWARE: empty verbs are not considered finite by this method, you'd have to check separately (check_empty_tokens and check_conjunct_empty_verb). Can be changed.
def finite(id,dpos,dmorph)
  check=false
  if dpos[id]=="V-" 
    if (dmorph[id][3]=="i" or (dmorph[id][2]=="s" and dmorph[id][3]=="p"))
	  check=true
	end
  end
  return check
end

def add_empty_token(original_id=nil,empty_tokens,sort,dpos,dmorph,dlemma) #optimize: incorporate arguments like did,dhead_id,emptyhead,emptyrel,emptydaughter,emptydaughtersrel, change all the calls accordingly
  
  if empty_tokens[0].last==-10
    newid = 1000
  else
    newid = empty_tokens[0].last+1
  end
  empty_tokens[0] << newid
  empty_tokens[1] << sort[0] #C or V
  empty_tokens[2] << original_id #remember the original id so that other arrays can be restructured
  dpos[newid] = sort+"-"
  dmorph[newid] = "---------n"
  dlemma[newid] = "empty"
return empty_tokens	
end

def checkalldaughters(control="yes",daughters_row,rel1,rel2,drel,sentence_id) 
  i=0
  double_check=0
  chosen=nil
  while daughters_row[i]!=nil
    
    if drel[daughters_row[i]]==rel1 or drel[daughters_row[i]]==rel2
	  chosen=daughters_row[i] #the node that also has the same relation
	  double_check=double_check+1
	end  
	i=i+1
  end
  if double_check>1 and control=="yes"
    @flags.puts "#{sentence_id}, 2A, siblings have some of these relations: #{rel1} #{rel2}. If predik and 1-kompl, check kolich-pred, if sub, check add_x_slashes, otherwise check coordination"
	if ["сочин", "сент-соч", "соч-союзн"].include?(rel1) or ["сочин", "сент-соч", "соч-союзн"].include?(rel2)
	  if !@excluded_sentences.include?(sentence_id)
		@excluded_sentences << sentence_id
	  end
	end
  end 
  return chosen
end

def checkalldaughters2(daughters_row,rels_to_check,drel,sentence_id) #returns all the immediate daughters that have a given relation
  i=0
  chosen=[]
  while daughters_row[i]!=nil
    
    if rels_to_check.include?(drel[daughters_row[i]])
	  chosen << daughters_row[i] #the node that also has the same relation
	end  
	i=i+1
  end
  return chosen
end



 #checkalldaughters uses the daughters array that is being destroyed in the course of the recursion (other methods have a backup array daughters2). But it seems it doesn't create any problems here: any relevant relation is handled at once, it cannot be left over
def coord(id,backup,daughters,drel,dhead_id,empty_tokens,did,dpos,sentence_id,dmorph,dlemma)
  chain=[]
  
  if daughters[id][0]!=nil  #if there is where to go now
	backup << id #mark where we are going
	if drel[daughters[id][0]]=="сочин" 
	  tt=checkalldaughters(daughters[id],"сочин","сочин",drel,sentence_id)  
	  headconj=nil
	  if chain.last==nil #adding first conjunct
	    chain << id
	  end 	  
	  chain << daughters[id][0] #adding second conjunct
	  drel[daughters[id][0]]="temp" #avoid counting the same element twice
	  newid=daughters[id][0]
	  if dpos[newid]=="C-"
	    headconj=newid
	  end
	  flag=false
	  begin
	    t=checkalldaughters(daughters[newid],"сочин","соч-союзн",drel,sentence_id)
	    if t!=nil
		  if dpos[t]=="C-" and headconj==nil
		    headconj=t
		  end
		  chain << t
		  newid=t
		  drel[t]="temp"
		else
		  flag=true
		end
	  end until flag
	  incoming_head=dhead_id[chain.first]
	  incoming_rel=drel[chain.first]
	  
	  if headconj==nil 
	    empty_tokens=add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
	    did[empty_tokens[0].last]=empty_tokens[0].last #so that the new empty token gets printed in the final output cycle
	    chain.each do |k|
	      dhead_id[k]=empty_tokens[0].last #empty token is the head now
		  drel[k]="fff1" #incoming_rel
	    end
	    dhead_id[empty_tokens[0].last]=incoming_head
	    drel[empty_tokens[0].last]=incoming_rel
		
	  else
	    chain.each do |k|
	      dhead_id[k]=headconj unless k==headconj
		  if k!=headconj and dpos[k]=="C-" 
		    drel[k]="aux" 
		  elsif k==headconj	#to roll back: merge these two conditions and just make drel[k]=incoming_rel
			drel[k]=incoming_rel 
		  else 	
			drel[k]="fff1" 
		  end	 
	    end
		dhead_id[headconj]=incoming_head
	  end 
 	  chain=[]
	  headconj=nil
	   
    elsif drel[daughters[id][0]]=="сент-соч" 
      tt=checkalldaughters(daughters[id],"сент-соч","сент-соч",drel,sentence_id)  
	  headconj=nil
	  if chain.last==nil #adding first conjunct
	    chain << id
	  end 	  
	  chain << daughters[id][0] #adding second conjunct
	  drel[daughters[id][0]]="temp" #avoid counting the same element twice
	  newid=daughters[id][0]
	  if dpos[newid]=="C-"
	    headconj=newid
	  end
	  flag=false
	  begin
	    t=checkalldaughters(daughters[newid],"сент-соч","соч-союзн",drel,sentence_id)
	    if t!=nil
		  if dpos[t]=="C-" and headconj==nil
		    headconj=t
		  end
		  chain << t
		  newid=t
		  drel[t]="temp"
		else
		  flag=true
		end
	  end until flag	
	  incoming_head=dhead_id[chain.first]
	  incoming_rel=drel[chain.first]
	  if headconj==nil 
	    empty_tokens=add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
	    did[empty_tokens[0].last]=empty_tokens[0].last #so that the new empty token gets printed in the final output cycle
	    chain.each do |k|
	      dhead_id[k]=empty_tokens[0].last #empty token is the head now
		  drel[k]="fff1" #incoming_rel 
	    end
	    dhead_id[empty_tokens[0].last]=incoming_head
	    drel[empty_tokens[0].last]=incoming_rel
	  else
	    chain.each do |k|
	      dhead_id[k]=headconj unless k==headconj
		  
		  if k!=headconj and dpos[k]=="C-" 
		    drel[k]="aux"
		  elsif k==headconj	#to roll back: merge these two conditions and just make drel[k]=incoming_rel
			drel[k]=incoming_rel 
		  else 	
			drel[k]="fff1" 
		  end	 
		  		  
	    end
		dhead_id[headconj]=incoming_head
      end 
	  chain=[]
	  headconj=nil
	
	elsif drel[daughters[id][0]]=="аддит" 
      tt=checkalldaughters(daughters[id],"аддит","аддит",drel,sentence_id)  
	  
	  if chain.last==nil #adding first conjunct
	    chain << id
	  end 	  
	  chain << daughters[id][0] #adding second conjunct
	  drel[daughters[id][0]]="temp" #avoid counting the same element twice
	  newid=daughters[id][0]
	  
	  flag=false
	  begin
	    t=checkalldaughters(daughters[newid],"аддит","аддит",drel,sentence_id)
	    if t!=nil
		
		  chain << t
		  newid=t
		  drel[t]="temp"
		else
		  flag=true
		end
	  end until flag	
	  incoming_head=dhead_id[chain.first]
	  incoming_rel=drel[chain.first]
	  empty_tokens=add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
	  did[empty_tokens[0].last]=empty_tokens[0].last #so that the new empty token gets printed in the final output cycle
	  chain.each do |k|
	    dhead_id[k]=empty_tokens[0].last #empty token is the head now
		drel[k]="fff1" #incoming_rel
	  end
	  dhead_id[empty_tokens[0].last]=incoming_head
	  drel[empty_tokens[0].last]=incoming_rel
	  
	  chain=[]
	  
	elsif drel[daughters[id][0]]=="кратн" #TODO!!! Deal separately with кратн in 10 на 15
      tt=checkalldaughters(daughters[id],"кратн","кратн",drel,sentence_id)  
	  
	  if chain.last==nil #adding first conjunct
	    chain << id
	  end 	  
	  chain << daughters[id][0] #adding second conjunct
	  drel[daughters[id][0]]="temp" #avoid counting the same element twice
	  newid=daughters[id][0]
	  
	  flag=false
	  begin
	    t=checkalldaughters(daughters[newid],"кратн","кратн",drel,sentence_id)
	    if t!=nil
		
		  chain << t
		  newid=t
		  drel[t]="temp"
		else
		  flag=true
		end
	  end until flag	
	  incoming_head=dhead_id[chain.first]
	  incoming_rel=drel[chain.first]
	  empty_tokens=add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
	  did[empty_tokens[0].last]=empty_tokens[0].last #so that the new empty token gets printed in the final output cycle
	  chain.each do |k|
	    dhead_id[k]=empty_tokens[0].last #empty token is the head now
		drel[k]="fff1" #incoming_rel
	  end
	  dhead_id[empty_tokens[0].last]=incoming_head
	  drel[empty_tokens[0].last]=incoming_rel
	  
	  chain=[]  
	  
	elsif drel[daughters[id][0]]=="колич-вспом" 
      tt=checkalldaughters(daughters[id],"колич-вспом","колич-вспом",drel,sentence_id)  
	  
	  if chain.last==nil #adding first conjunct
	    chain << id
	  end 	  
	  chain << daughters[id][0] #adding second conjunct
	  drel[daughters[id][0]]="temp" #avoid counting the same element twice
	  newid=daughters[id][0]
	  
	  flag=false
	  begin
	    t=checkalldaughters(daughters[newid],"колич-вспом","колич-вспом",drel,sentence_id)
	    if t!=nil
		
		  chain << t
		  newid=t
		  drel[t]="temp"
		else
		  flag=true
		end
	  end until flag	
	  incoming_head=dhead_id[chain.first]
	  incoming_rel=drel[chain.first]
	  empty_tokens=add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
	  did[empty_tokens[0].last]=empty_tokens[0].last #so that the new empty token gets printed in the final output cycle
	  chain.each do |k|
	    dhead_id[k]=empty_tokens[0].last #empty token is the head now
		drel[k]="fff1" #incoming_rel
	  end
	  dhead_id[empty_tokens[0].last]=incoming_head
	  drel[empty_tokens[0].last]=incoming_rel
	  
	  chain=[]    

		
	end
	
	id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  
  if backup.length>0 
    coord(id,backup,daughters,drel,dhead_id,empty_tokens,did,dpos,sentence_id,dmorph,dlemma)
  end
  if daughters[0].length>0 
    coord(0,[],daughters,drel,dhead_id,empty_tokens,did,dpos,sentence_id,dmorph,dlemma)
  end
end

def from_above(id=0,backup=[],daughters,daughters2,drel,dlemma,sentence_id,dmorph,empty_tokens,did,dhead_id,dpos,drel_old) #go recursively through the tree and convert relations
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
		
    if RELATIONS1.include?(drel[daughters[id][0]]) #actual conversion 
	  drel_old[daughters[id][0]]=drel[daughters[id][0]]
	  drel[daughters[id][0]]=reltag1(drel[daughters[id][0]]) 
	elsif RELATIONS2.include?(drel[daughters[id][0]])
	  drel_old[daughters[id][0]]=drel[daughters[id][0]]
      drel[daughters[id][0]]=reltag2(drel[daughters[id][0]],id,daughterid,dlemma,sentence_id,dmorph, empty_tokens,did,dhead_id,drel,dpos,daughters2,drel_old) 
    elsif not(RELATIONS0.include?(drel[daughters[id][0]])) and not(drel[daughters[id][0]][0..2]=="fff") and not(RELATIONS_AFTER.include?(drel[daughters[id][0]]))
      #STDERR.puts id, drel[daughters[id][0]],"Relation not found!"
    end 
    
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end

  if backup.length>0 
    from_above(id,backup,daughters,daughters2,drel,dlemma,sentence_id,dmorph,empty_tokens,did,dhead_id,dpos,drel_old)
  end
  if daughters[0].length>0 
    from_above(0,[],daughters,daughters2,drel,dlemma,sentence_id,dmorph,empty_tokens,did,dhead_id,dpos,drel_old)
  end
end

def convert_kolichest(id=0,backup=[],daughters,	drel,dlemma,sentence_id,dmorph,dhead_id,dpos) #TODO!!! Deal with dependent relocation (empty verbs inserted between numeral and noun under PART)
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid] == "количест" or drel[daughterid] == "аппрокс-колич" #and dpos[id]!="C-" #No longer needed since fff1 are introduced
	  if dlemma[daughterid] == "ОДИН" or check_conjunct([],"equals",0,0,"yes",0,dlemma,"ОДИН",daughterid,dpos,daughters,sentence_id) 
	    drel[daughterid] = "atr"
	  elsif (dmorph[id][6] == "g" or check_conjunct([],"substring",6,6,"yes",0,dmorph,"g",id,dpos,daughters,sentence_id)) and !(dmorph[daughterid][6] == "g" or check_conjunct([],"substring",6,6,"yes",0,dmorph,"g",daughterid,dpos,daughters,sentence_id)) and not(GENPREPS.include?(dlemma[dhead_id[id]]) or dmorph[dhead_id[id]][7]=="c" or check_conjunct([],"substring",7,7,"yes",0,dmorph,"c",dhead_id[id],dpos,daughters,sentence_id)) #the first condition not covered by check_conjunct. Hardly will be relevant, though!
	    if dmorph[daughterid][6] == "x" or check_conjunct([],"substring",6,6,"yes",0,dmorph,"x",daughterid,dpos,daughters,sentence_id) and not(ACCPREPS.include?(dlemma[dhead_id[id]]))
          @flags.puts "#{sentence_id}, 3B, #{id}, Numeral case unknown, check whether it should be the head (alternative: make it dependent via ATR)"
		end
		dhead_id[daughterid] = dhead_id[id]
		drel[daughterid] = drel[id]
		dhead_id[id] = daughterid
		drel[id] = "part"
	  else 	
	    drel[daughterid] = "atr"
	  end
		
    end 
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_kolichest(id,backup,daughters,drel,dlemma,sentence_id,dmorph,dhead_id,dpos)
  end
  if daughters[0].length>0 
    convert_kolichest(0,[],daughters,drel,dlemma,sentence_id,dmorph,dhead_id,dpos)
  end
end

def go_up_until(id,pos,dhead_id,dpos,drel)
  d = id
  begin 
    d = dhead_id[d] 
  end until dpos[d]==pos #or drel[d]=="pred" #the second condition is a safeguard so that the script does not crash if there is no verb. Looks like we can live without it, though.
  return d
end


def convert_adr_prisv(id=0,backup=[],daughters,	drel,sentence_id,dhead_id,dpos) 
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid] == "адр-присв"
	  dhead_id[daughterid] = go_up_until(id,"V-",dhead_id,dpos,drel) 
	  drel[daughterid] = "obl"
		
    end 
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_adr_prisv(id,backup,daughters,	drel,sentence_id,dhead_id,dpos)
  end
  if daughters[0].length>0 
    convert_adr_prisv(0,[],daughters,	drel,sentence_id,dhead_id,dpos)
  end
end

def convert_sootnos(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma,dmorph,empty_tokens,did) 
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid] == "соотнос" 
	  if dpos[daughterid]=="R-" #осмотрел с головы до ног: до ног goes under осмотрел and gets the same relation as с головы, the internal bond gets lost
	    if dpos[id]!="R-"
		  @flags.puts "#{sentence_id}, 2B, sootnos to a preposition from NOT a preposition; #{id},#{daughterid}"
		end
		
		#delete the conjunction later, if the relations is not a SINGLE_REL
		add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
		did[empty_tokens[0].last]=empty_tokens[0].last
		drel[empty_tokens[0].last]=drel[id]
		dhead_id[empty_tokens[0].last]=dhead_id[id]
		dhead_id[daughterid] = empty_tokens[0].last
		dhead_id[id] = empty_tokens[0].last
		drel[daughterid] = "fff2"
		drel[id] = "fff2"
	  elsif id > daughterid #a first conjunction in a double-conjunction construction, including не столько, сколько
	    if dpos[id]!="C-"
		  @flags.puts "#{sentence_id}, STAY. 4D, sootnos from right to left from NOT a conjunction; #{id},#{daughterid}"
		end
		drel[daughterid] = "aux"
	  else	
	    if (dlemma[id]=="ЧЕМ" or check_conjunct([],"equals",0,0,"no",0,dlemma,"ЧЕМ",id,dpos,daughters2,sentence_id)) and (dlemma[daughterid]=="ТЕМ" or check_conjunct([],"equals",0,0,"no",0,dlemma,"ТЕМ",daughterid,dpos,daughters2,sentence_id)) #Чем больше он о них думал, тем яснее видел детали.
		  id2=id #since it can be changed below
		  
		  #if чем is under a conjunction that also has another чем-daughter
		  if dpos[dhead_id[id2]]=="C-" and check_conjunct_new([],"equals",0,0,"no",[],dlemma,"ЧЕМ",dhead_id[id2],dpos,daughters2,sentence_id).length>1
		    id2=dhead_id[id2]
			dhead_id[daughterid]=id2
		  end 
		 
          chem = []
		  tem = [] 
		  chem_verb = []
		  tem_verb = []
		  overall_head = dhead_id[id2] #doesn't matter if id is a C- or a "CHEM"
		  		  
		  if dpos[id2]!="C-" 		  
		    chem << id2
		  else
            chem = return_all_conjuncts([],[],id2,dpos,daughters2,sentence_id,drel)  
		  end 	
		  if dpos[daughterid]!="C-" 		  
		    tem << daughterid
		  else
            tem = return_all_conjuncts([],[],daughterid,dpos,daughters2,sentence_id,drel)  
		  end 	
		  hang_chem_on = tem[0] #the CHEM-group will go on the first tem anyway
		  		  
		  if dpos[id2]!="C-" 
		    chem_verb << checkalldaughters(daughters2[chem[0]],"сравн-союзн","сравн-союзн",drel,sentence_id) #думал
			chem_group_head = chem[0]
		  else 
		    chem.each do |chemnode|
			  chem_verb << checkalldaughters(daughters2[chemnode],"сравн-союзн","сравн-союзн",drel,sentence_id)
			end
			chem_group_head = id2
		  end
		  		  
		  if dpos[daughterid]!="C-" 		  
			tem_verb << checkalldaughters(daughters2[tem[0]],"сравн-союзн","сравн-союзн",drel,sentence_id) #видел
			tem_group_head = tem_verb[0]
		  else 
		    tem.each do |temnode|
			  tem_verb << checkalldaughters(daughters2[temnode],"сравн-союзн","сравн-союзн",drel,sentence_id)
			end
			tem_group_head = daughterid
		  end
		  	 		  		  
		  #tem-verb
		  dhead_id[tem_group_head]=overall_head #becomes the head
		  drel[tem_group_head]=drel[chem_group_head] #inherits the relation of the former head (usually pred)
		  		  
		  #tem
		  i=0
		  begin 
		    dhead_id[tem[i]]=tem_verb[i] #goes under its verb
		    drel[tem[i]]="adv"
		    dpos[tem[i]]="Df" #adverb
			if dpos[daughterid]=="C-"
			  dhead_id[tem_verb[i]]=tem_group_head
			  drel[tem_verb[i]]="fff1"
			end
			i=i+1
		  end until tem[i]==nil
		  		  
		  i=0
		  begin
		    if finite(chem_verb[i],dpos,dmorph) or check_conjunct_finite([],daughters2,chem_verb[i],dpos,dmorph) or check_empty_tokens(empty_tokens,chem_verb[i],"V") or check_conjunct_empty_verb([],daughters2,chem_verb[i],empty_tokens,dpos)
		      dhead_id[chem[i]]=chem_verb[i] #goes under its verb
			  if dpos[id2]!="C-" 
			    chem_group_head=chem_verb[i] #the verb becomes the head, not chem
			  else
				dhead_id[chem_verb[i]]=chem_group_head
				drel[chem_verb[i]]="fff1"
			  end
			  
		      drel[chem[i]]="adv"
		      dpos[chem[i]]="Dq" #relative adverb
		    else
		      dpos[chem[i]]="Df" #adverb
			  if dpos[id2]=="C-" 
			    dhead_id[chem[i]]=chem_group_head
				drel[chem[i]]="fff1"
			  end
			  
			  if dmorph[chem_verb[i]][6]=="n" or  check_conjunct([],"substring",6,6,"no",0,dmorph,"n",chem_verb[i],dpos,daughters2,sentence_id)
			    drel[chem_verb[i]] = "sub"
			  elsif dmorph[chem_verb[i]][3]=="n" or check_conjunct([],"substring",3,3,"no",0,dmorph,"n",chem_verb[i],dpos,daughters2,sentence_id)
		        drel[chem_verb[i]] = "comp"  
		      elsif dmorph[chem_verb[i]][6]=="a" or check_conjunct([],"substring",6,6,"no",0,dmorph,"a",chem_verb[i],dpos,daughters2,sentence_id)
		        drel[chem_verb[i]] = "obj"
		      elsif (dmorph[chem_verb[i]][6]!="-" and !check_conjunct([],"substring",6,6,"no",0,dmorph,"-",chem_verb[i],dpos,daughters2,sentence_id)) or dpos[chem_verb[i]]=="R-" or check_conjunct([],"equals",0,0,"no",0,dpos,"R-",chem_verb[i],dpos,daughters2,sentence_id)
		        drel[chem_verb[i]] = "obl"
		      else
		        drel[chem_verb[i]] = "adv"
		      end
		    end	
		    i=i+1
		  end until chem[i]==nil
		  		  
		  dhead_id[chem_group_head] = hang_chem_on
		  drel[chem_group_head] = "apos"
		  
		elsif dlemma[id]=="ЧТО" and dlemma[daughterid]=="ТО" #что каcается меня, то я приду
		  drel[daughterid] = "aux" #maybe just leave it that way? or put то under a verb (which one, then: in the main sentence or in the adv clause?)
		else #left dislocation
		  if dlemma[daughterid]=="КАК" and dlemma[id]=="ЕДВА"
		    dpos[daughterid] = "Df"
		  end
		  
		  dhead_id[daughterid] = go_up_until(id,"V-",dhead_id,dpos,drel)  #the second conjunction went under the main verb 
	      drel[daughterid] = drel[id] #inheriting the relation of the first conjunction (~adv)
	      dhead_id[id] = daughterid #the second conjunction went under the first...
		  drel[id] = "apos" #...and under apos
		end
	  end
    end 
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_sootnos(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma,dmorph,empty_tokens,did)
  end
  if daughters[0].length>0 
    convert_sootnos(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma,dmorph,empty_tokens,did)
  end
end


def convert_vspom(id=0,backup=[],daughters,drel,sentence_id,dhead_id,dpos,dlemma,dfeats,slash_rel,slash_target) 
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid] == "вспом" 
	  if ["I","V","X"].include?(dlemma[daughterid][0]) #Александр II
	    drel[daughterid] = "atr"
	  elsif dlemma[daughterid][-1]=="." and dfeats[daughterid].include?("ОД") #А. С. Пушкин
	    drel[daughterid] = "apos" #Syntagrus's head-dependent structure is kept, no conversion to TOROT left-to-right principle yet.
	  elsif dlemma[daughterid]=="СЕБЯ"
	    drel[daughterid] = "adv"
	  elsif dlemma[daughterid]=="ДРУГ"
		dhead_id[daughterid] = go_up_until(id,"V-",dhead_id,dpos,drel) 
		drel[daughterid] = "xadv"
	    dpos[daughterid] = "Pc"
		dpos[id] = "Pc"
		slash_rel[daughterid] = "xsub"
		slash_target[daughterid] = dhead_id[daughterid]
	  else
        drel[daughterid] = "aux" #TODO: sort 
	  end
    end 
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_vspom(id,backup,daughters,drel,sentence_id,dhead_id,dpos,dlemma,dfeats,slash_rel,slash_target)
  end
  if daughters[0].length>0 
    convert_vspom(0,[],daughters,drel,sentence_id,dhead_id,dpos,dlemma,dfeats,slash_rel,slash_target)
  end
end

def convert_sravn_sojuzn(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,empty_tokens) 
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid] == "сравн-союзн" 
	  if dpos[id] != "G-"
	    @flags.puts "#{sentence_id}, 1A, misannotation: sravn-sojuzn not from a conjunction"
	    if !@excluded_sentences.include?(sentence_id)
		  @excluded_sentences << sentence_id
	    end
		drel[daughterid] = "expl" #just a meaningless dummy solution
	  else
	    if finite(daughterid,dpos,dmorph) or check_conjunct_finite([],daughters2,daughterid,dpos,dmorph) or check_empty_tokens(empty_tokens,daughterid,"V") or check_conjunct_empty_verb([],daughters2,daughterid,empty_tokens,dpos)
	      dhead_id[daughterid]=dhead_id[id]
		  drel[daughterid]=drel[id] #most likely сравнит
		  dhead_id[id] = daughterid
		  dpos[id] = "Dq"
		  drel[id]= "adv"	
	    elsif dmorph[daughterid][3]=="n" or check_conjunct([],"substring",3,3,"yes",0,dmorph,"n",daughterid,dpos,daughters2,sentence_id)
	      drel[daughterid] = "comp"
		  dpos[id] = "Df"
	    else
	      dpos[id] = "Df"
		  if dmorph[daughterid][6]=="n"
		    drel[daughterid] = "sub"
		  elsif dmorph[daughterid][6]=="a"
		    drel[daughterid] = "obj"
		  elsif dmorph[daughterid][6]!="-" or dpos[daughterid]=="R-"
		    drel[daughterid] = "obl"
		  else
		    drel[daughterid] = "adv"
		  end
	    end
	  end	
    end 
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_sravn_sojuzn(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,empty_tokens)
  end
  if daughters[0].length>0 
    convert_sravn_sojuzn(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,empty_tokens)
  end
end

#Just a pattern to build real methods.
def convert_dummy(id=0,backup=[],daughters,daughters2, drel,sentence_id,dhead_id) #go recursively through the tree and convert relations
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="RELNAME"
	  #DO WHAT HAS TO BE DONE
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_dummy(id,backup,daughters,daughters2,drel,sentence_id,dhead_id)
  end
end

def convert_prisvjaz(id=0,backup=[],daughters,daughters2, drel,sentence_id,dhead_id,dpos) #go recursively through the tree and convert relations
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="присвяз"
	  if dpos[id]!="V-"
	    @flags.puts "#{sentence_id}, 2B, присвяз not from a verb" #just flagging these cases instead of trying to understand them
	    if !@excluded_sentences.include?(sentence_id)
		  @excluded_sentences << sentence_id
	    end
		drel[daughterid]="expl" #dummy
	  else
	    drel[daughterid]="xobj"
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_prisvjaz(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos)
  end
end



#TODO: check the three flags, deal with them
def convert_kolich_kopred(id=0,backup=[],daughters,daughters2, drel,sentence_id,dhead_id) #go recursively through the tree and convert relations
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="колич-копред"
	  t=checkalldaughters(daughters2[id],"предик","1-компл",drel,sentence_id) 
	  if t!=nil
	    dhead_id[daughterid]=t 
		drel[daughterid]="количест" 
	  else
	    drel[daughterid]="предик"
		@flags.puts "#{sentence_id}, 1A, #{daughterid}, Neither subject nor direct object found for kolich-kopred, check and change"
		if !@excluded_sentences.include?(sentence_id)
		  @excluded_sentences << sentence_id
	    end
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_kolich_kopred(id,backup,daughters,daughters2,drel,sentence_id,dhead_id)
  end
end

def convert_op_opred(id=0,backup=[],daughters,drel,sentence_id,dhead_id,dpos,dmorph) #go recursively through the tree and convert relations
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="оп-опред"
	  if dmorph[daughterid][3]=="p" or check_conjunct([],"substring",3,3,"yes",0,dmorph,"p",daughterid,dpos,daughters,sentence_id)
        dhead_id[daughterid] = go_up_until(id,"V-",dhead_id,dpos,drel) 
	    drel[daughterid] = "xadv"
	  else
	    drel[daughterid] = "atr"
		@flags.puts "#{sentence_id}, 3D, op-opred converted to atr, but might be xadv or apos"
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_op_opred(id,backup,daughters,drel,sentence_id,dhead_id,dpos,dmorph)
  end
  if daughters[0].length>0
    convert_op_opred(0,[],daughters,drel,sentence_id,dhead_id,dpos,dmorph)
  end
end

def convert_sub_kopr(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma)
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="суб-копр"
      if dpos[id]!="V-"
	    @flags.puts " #{sentence_id}, sub-kopr not under a verb, #{id}, #{daughterid}"
		if !@excluded_sentences.include?(sentence_id)
		  @excluded_sentences << sentence_id
	    end
	  end
	  if dlemma[daughterid]=="САМ"
	    if checkalldaughters("yes",daughters2[id],"sub","sub",drel,sentence_id)==nil
		  drel[daughterid]="sub"
		else
		  dhead_id[daughterid]=checkalldaughters("yes",daughters2[id],"sub","sub",drel,sentence_id)
		  drel[daughterid]="atr"
		end
	  else
	    drel[daughterid]="xadv"
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_sub_kopr(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma)
  end
  if daughters[0].length>0
    convert_sub_kopr(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma)
  end
end

def convert_ob_kopr(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma,drel_old)
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="об-копр"
	  if dpos[id]!="V-"
		@flags.puts "#{sentence_id}, 2B, ob-kopr not under a verb, #{id}, #{daughterid}"
		if !@excluded_sentences.include?(sentence_id)
		  @excluded_sentences << sentence_id
	    end
	  end
	  if dlemma[daughterid]=="САМ"
	    if checkalldaughters("yes",daughters2[id],"1-компл","1-компл",drel,sentence_id)==nil
		  drel[daughterid]="obj"
		  @flags.puts "#{sentence_id}, 2B, no 1-kompl from a verb governing an ob-kopr, check if there is something else, #{id}, #{daughterid}"
		  if !@excluded_sentences.include?(sentence_id)
		    @excluded_sentences << sentence_id
	      end
		else
		  dhead_id[daughterid]=checkalldaughters("yes",daughters2[id],"1-компл","1-компл",drel,sentence_id)
		  drel[daughterid]="atr"
		end
	  else
	    if dlemma[id].include?("ipf")
		  verblemma=dlemma[id].gsub(".ipf","")
		else  
		  verblemma=dlemma[id].gsub(".pf","")
		end
		if PERCVERBS.include?(verblemma)
		  drel[daughterid]="xobj"
		else 
		  drel[daughterid]="xadv"
		end  
		drel_old[daughterid]="об-копр"
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_ob_kopr(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma,drel_old)
  end
  if daughters[0].length>0
    convert_ob_kopr(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dlemma,drel_old)
  end
end




def check_empty_tokens(empty_tokens,id,sort) #checks whether a node with a given id is an empty node of a given sort
  
  i=1
  flag=false
  check=false
 
  if id > 999
    check=false
    begin
      if empty_tokens[0][i]==id
	    flag=true
	    if empty_tokens[1][i]==sort
	      check=true
	    end
	  end 
      i=i+1
    end until empty_tokens[0][i]==nil or flag
 
  end	
  
  return check

end

def add_x_slashes(id=0,backup=[],daughters,daughters2,drel,dpos,dhead_id,empty_tokens,slash_rel,slash_target,sentence_id,drel_old) #TODO: not always gets the xsub right (на ней, ставшей экраном, появляется фотография). Do manual check on a sample?
  if daughters[id][0]!=nil  #if there is where to go now
    newid=daughters[id][0]
	if (drel[newid]=="xobj" or drel[newid]=="xadv") and dpos[id]!="C-" and not(check_empty_tokens(empty_tokens,id,"C")) and slash_rel[newid]==nil
	  slash_rel[newid]="xsub"
	  if drel_old[newid]!="об-копр" # xsub= subject
        if checkalldaughters(daughters2[id],"дат-субъект","дат-субъект",drel_old,sentence_id)==nil #TODO: not only subjects and дат-субъект? Reverse the order?
	      if checkalldaughters(daughters2[id],"sub","sub",drel,sentence_id)==nil
		    if checkalldaughters(daughters2[id],"предик","предик",drel_old,sentence_id)==nil
			  slash_target[newid]=id
			else
			  slash_target[newid]=checkalldaughters(daughters2[id],"предик","предик",drel_old,sentence_id)
			end  
		  else
	        slash_target[newid]=checkalldaughters(daughters2[id],"sub","sub",drel,sentence_id)		  
		  end	
	    else
		  slash_target[newid]=checkalldaughters(daughters2[id],"дат-субъект","дат-субъект",drel_old,sentence_id)	
	    end
	  else #xsub = object
		if checkalldaughters(daughters2[id],"obj","obj",drel,sentence_id)==nil
		  slash_target[newid]=id
		else
	      slash_target[newid]=checkalldaughters(daughters2[id],"obj","obj",drel,sentence_id)		  
		end	
      end	  
    end
	backup << id #mark where we are going
	id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end

  if backup.length>0 
    add_x_slashes(id,backup,daughters,daughters2,drel,dpos,dhead_id,empty_tokens,slash_rel,slash_target,sentence_id,drel_old)
  end
  if daughters[0].length>0
    add_x_slashes(0,[],daughters,daughters2,drel,dpos,dhead_id,empty_tokens,slash_rel,slash_target,sentence_id,drel_old)
  end

  
end

def conj_root(did,dhead_id,drel,sentence_id) 
  did2=did.compact
  i=1
  begin
    currentdaughter=did2[i]
    currenthead=dhead_id[did2[i]]
    if drel[currentdaughter]=="соч-союзн" and drel[currenthead]!="сочин" and drel[currenthead]!="сент-соч"
	  dhead_id[currentdaughter]=dhead_id[currenthead] #conjunction's daughter becomes the root. It might lose this status later, if it's not a verb
	  dhead_id[currenthead]=currentdaughter #conjunction is being adopted by its former daughter
	  drel[currentdaughter]=drel[currenthead]
	  drel[currenthead]="aux"
	end  
	i=i+1
  end until did2[i]==nil	
end

def kill_subconj_root(did,dhead_id,drel,dpos,sentence_id,dlemma) 
  did2=did.compact
  i=1
  begin
    currentdaughter=did2[i]
    currenthead=dhead_id[did2[i]]
    if dpos[currenthead]=="G-" and (dhead_id[currenthead]==0 or drel[currenthead]=="вводн") and dlemma[currenthead]!="ЧЕМ"
	  dhead_id[currentdaughter]=dhead_id[currenthead] #conjunction's daughter becomes the root. It might lose this status later, if it's not a verb
	  dhead_id[currenthead]=currentdaughter #conjunction is being adopted by its former daughter
	  drel[currentdaughter]=drel[currenthead] #PRED
	  if dlemma[currenthead]=="КАК"
	    drel[currenthead]="adv"
	  else
	    drel[currenthead]="aux"
	  end
	end  
	i=i+1
  end until did2[i]==nil	
end



def dirspeech_conj(did,drel,dpos) 
  did2=did.compact
  i=1
  begin
    if drel[did2[i]][-5..-1]=="компл" and dpos[did2[i]]=="C-"
	  drel[did2[i]]="parpred"
	end
    i=i+1
  end until did2[i]==nil	
end

def convert_vocative(did,dmorph,drel)
  did2=did.compact[1..-1]
  did2.each do |node|
    if dmorph[node][6]=="v"
	  drel[node]="voc"
	end  
  end
end

def convert_coms(did,drel,dpos,dhead_id,empty_tokens,dmorph,allthedaughters,sentence_id) 
  did2=did.compact
  i=1
  begin
    id=did2[i]
	head=dhead_id[id]
    if dpos[id]=="COM"
	  if dpos[head]=="C-" or check_empty_tokens(empty_tokens,head,"C") #if this is a coordination, i.e. a group like микро- и макроциркуляция
		id_index=allthedaughters[head].index(id)
		if allthedaughters[head][id_index+1]!=nil
		  sibling_id=allthedaughters[head][id_index+1] #choose nearest sibling to the right if there is one
		elsif allthedaughters[head][id_index-1]!=nil 
		  sibling_id=allthedaughters[head][id_index-1] #choose nearest sibling to the left if there is one
		else  
		  #STDERR.puts "No siblings, and that's weird" 
		end
		dpos[id]=dpos[sibling_id] #inherit the pos
		
		if allthedaughters[head].length>2 
		  test=dpos[allthedaughters[head][0]]
		  for j in 1..(allthedaughters[head].length-1) do
		    if dpos[allthedaughters[head][j]]!=test
              @flags.puts "#{sentence_id}, 2D, COM had several coordinated siblings with different POSs, check that the correct one was selected"			
			end
		  end
		end
				
	  else	
		dpos[id]="Df"
		if drel[id]!="atr"
		  @flags.puts "#{sentence_id}, 2D, single COM was not under ATR, but under #{drel[id]}, check whether it makes sense"			
		  if !@excluded_sentences.include?(sentence_id)
		    @excluded_sentences << sentence_id
	      end
		end
		
	  end
	  dmorph[id]="---------n"
	end
    i=i+1
  end until did2[i]==nil	
end

def debug_array(did,array) 
  did2=did.compact
  i=1
  STDERR.puts "#{did2[i]} #{array[0]}"
  begin
    STDERR.puts "#{did2[i]} #{array[did2[i]]}"
	i=i+1
  end until did2[i]==nil	
end


def put_under_root(did,dhead_id,drel,dpos) 
  did2=did.compact
  i=1
  begin
    if drel[did2[i]]=="parpred" or drel[did2[i]]=="voc" and not(dpos[dhead_id[did2[i]]]=="C-" and drel[dhead_id[did2[i]]]==drel[did2[i]])
	  dhead_id[did2[i]]=0
	end
    i=i+1
  end until did2[i]==nil	
end

def conjunction?(id,dpos,empty_tokens) #NOT USED, CAN BE REMOVED
  dpos[id]=="C-" or check_empty_tokens(empty_tokens,id,"C") 
end 

def check_conjunct(godown=[],method="equals",position1=0,position2=0,check_conflict="no",check=0,darray,value,conj_id,dpos,allthedaughters,sentence_id)

  if dpos[conj_id]=="C-" and allthedaughters[conj_id][0]!=nil
    i=0
	begin
	  if method=="equals"
	    if darray[allthedaughters[conj_id][i]]==value
	      check=check+1
	    end	
	  elsif method=="includes"
	    if darray[allthedaughters[conj_id][i]].include?(value)
		  check=check+1
	    end	
	  elsif method=="substring"
	    if darray[allthedaughters[conj_id][i]][position1..position2]==value
		  check=check+1
		end
	  end
		
	  if dpos[allthedaughters[conj_id][i]]=="C-"
	    godown << allthedaughters[conj_id][i]
	  end
	  i=i+1
	end until allthedaughters[conj_id][i]==nil
	
	
	
	if godown.length > 0
	  t=godown.shift
	  check_conjunct(godown,method,position1,position2,check_conflict,check,darray,value,t,dpos,allthedaughters,sentence_id)
	end
  end
  
  if check>0 
    return true
  else
    return false
  end	
end


def check_conjunct_finite(godown=[],allthedaughters,conj_id,dpos,dmorph)
  check=false
  if dpos[conj_id]=="C-" and allthedaughters[conj_id][0]!=nil
    i=0
	begin
	  if finite(allthedaughters[conj_id][i],dpos,dmorph) 
	    check=true
	  elsif dpos[allthedaughters[conj_id][i]]=="C-"
	    godown << allthedaughters[conj_id][i]
	  end
	  i=i+1
	end until allthedaughters[conj_id][i]==nil or check
	if godown.length > 0
	  t=godown.shift
	  check_conjunct_finite(godown,allthedaughters,t,dpos,dmorph)
	end
  end
  return check
end

def check_conjunct_morphtag(godown=[],allthedaughters,conj_id,dmorph,position,value,dpos)
  check=false
  if dpos[conj_id] == "C-" and allthedaughters[conj_id][0]!=nil
    i=0
	begin
	  if dmorph[allthedaughters[conj_id][i]][position]==value #if a first-level conjunct is a given pos
        check=true	    	  	
	  elsif dpos[allthedaughters[conj_id][i]] == "C-"
        godown << allthedaughters[conj_id][i]        
	  end
	  i=i+1
	end until allthedaughters[conj_id][i]==nil or check
	if godown.length > 0
	  t=godown.shift
	  check_conjunct_morphtag(godown,allthedaughters,t,dmorph,position,value,dpos)
	end
  end
  return check
end

def check_conjunct_empty_verb(godown=[],allthedaughters,conj_id,empty_tokens,dpos)
  check=false
  if dpos[conj_id]=="C-" and allthedaughters[conj_id][0]!=nil
    i=0
	begin
	  #STDERR.puts sentence_id,conj_id,allthedaughters[conj_id][i]
	  if check_empty_tokens(empty_tokens,allthedaughters[conj_id][i],"V") #if a first-level conjunct is a given pos
	    check=true
	  elsif dpos[allthedaughters[conj_id][i]]=="C-"
	    godown << allthedaughters[conj_id][i]
	  end
	  i=i+1
	end until allthedaughters[conj_id][i]==nil or check
	if godown.length > 0
	  t=godown.shift
	  check_conjunct_empty_verb(godown,allthedaughters,t,empty_tokens,dpos)
	end
  end
  return check
end

def add_empty_verb(verb_head,verb_rel,verb_daughters,verb_daughters_rels,empty_tokens,did,dhead_id,dpos,dmorph,dlemma,drel)
  add_empty_token(empty_tokens,"V",dpos,dmorph,dlemma) #create a verb
  verb_id=empty_tokens[0].last
  did[verb_id]=verb_id #insert it into did
  dhead_id[verb_id]=verb_head #find a head for it
  drel[verb_id]=verb_rel #find a relation for it
  for i in 0..verb_daughters.length-1 do
    dhead_id[verb_daughters[i]]=verb_id
	drel[verb_daughters[i]]=verb_daughters_rels[i]
  end
end

def convert_predik(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="предик"
	  drel_old[daughterid]="предик"
	  rel_to_predicate="xobj" #defaults. Can be overridden by tests below. If the predicate is finite, rel_to_predicate won't be used
	  rel_to_subject="sub"
	  relocate=[]
	  
	  if finite(id,dpos,dmorph) or check_conjunct_finite([],daughters,id,dpos,dmorph) or check_empty_tokens(empty_tokens,id,"V") or check_conjunct_empty_verb([],daughters,id,empty_tokens,dpos) 
        predicate_finite=true
      else
        predicate_finite=false
      end
	  
	  if dmorph[daughterid][3]=="n" or check_conjunct([],"substring",3,3,"yes",0,dmorph,"n",daughterid,dpos,daughters,sentence_id) #if the dependent is an infinive...
        rel_to_subject = "comp" 
	  elsif dpos[daughterid]=="G-" or check_conjunct([],"equals",0,0,"yes",0,dpos,"G-",daughterid,dpos,daughters,sentence_id) #if the dependent is a subjunction
		rel_to_subject = "comp"			
	  end
	  if dlemma[id]=="У" or check_conjunct([],"equals",0,0,"yes",0,dlemma,"У",id,dpos,daughters,sentence_id) #if the head is у, then it's most likely a possessive construction and should be treated in this way
	    rel_to_predicate="obl"
	  elsif dlemma[id]=="ВОТ" or dlemma[id]=="ВОН" or check_conjunct([],"equals",0,0,"yes",0,dlemma,"ВОТ",id,dpos,daughters,sentence_id)  or check_conjunct([],"equals",0,0,"yes",0,dlemma,"ВОН",id,dpos,daughters,sentence_id)
        rel_to_predicate="voc"
		daughters[id].each do |node| #all the daughters of voc (apart from the subject) will have to go under the empty verb
		  if node!=daughterid
		    relocate << node 
		  end	
		end
	  end	
	  
	  if predicate_finite
        drel[daughterid] =  rel_to_subject
      else 
        verb_daughters = []
		verb_daughters_rels = []
		verb_head=dhead_id[id]
        verb_rel=drel[id]
		verb_daughters << id #the former head becomes an (xobj by default) daughter
        verb_daughters_rels << rel_to_predicate
        verb_daughters << daughterid #the former daughter becomes a (sub by default) daughter
        verb_daughters_rels << rel_to_subject
				
		checkalldaughters2(daughters2[id],RELATIONS_TO_RELOCATE,drel,sentence_id).each do |node|
		  relocate << node
		end
		checkalldaughters2(daughters2[daughterid],RELATIONS_TO_RELOCATE_SUB,drel,sentence_id).each do |node|
		  relocate << node
		end
		
		
		relocate.each do |node|
		  if node 
		    verb_daughters << node
		    verb_daughters_rels << drel[node] 
		  end	
		end
		
		add_empty_verb(verb_head,verb_rel,verb_daughters,verb_daughters_rels,empty_tokens,did,dhead_id,dpos,dmorph,dlemma,drel)
		@non_v_roots.puts "#{sentence_id},#{empty_tokens[0].last},#{id},#{daughterid},#{dlemma[daughterid]} predik"
      end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_predik(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  end
  if daughters[0].length>0
    convert_predik(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  end
end

def convert_dat_subjekt(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
    if drel[daughterid]=="дат-субъект"
	  if dmorph[id][3]=="n" or check_conjunct([],"substring",3,3,"yes",0,dmorph,"n",id,dpos,daughters,sentence_id) #if from infinitive
	    drel[daughterid]="sub"
	  elsif dpos[id]=="V-" or check_conjunct([],"equals",0,0,"yes",0,dpos,"V-",id,dpos,daughters,sentence_id) #if from a verb (not infinitive)
	    drel_old[daughterid]=drel[daughterid]
		drel[daughterid]="obl"
	  elsif drel[id]=="присвяз" or drel[id]=="пасс-анал" #if the head is a daughter of a copular verb (strictly speaking, there is a handful of cases when these relations come not from a verb)
	    drel_old[daughterid]=drel[daughterid]
		dhead_id[daughterid]=dhead_id[id]
		drel[daughterid]="obl"
	  else #otherwise insert an empty verb
	    drel_old[daughterid]=drel[daughterid]

 		
		relocate=[]
		verb_daughters = []
		verb_daughters_rels = []
		verb_head=dhead_id[id]
        verb_rel=drel[id]
		verb_daughters << id #the former head becomes an xobj daughter
        verb_daughters_rels << "xobj"
        verb_daughters << daughterid #the former daughter becomes an obl daughter
        verb_daughters_rels << "obl"
		
		checkalldaughters2(daughters2[id],RELATIONS_TO_RELOCATE,drel,sentence_id).each do |node|
		  relocate << node
		end
		checkalldaughters2(daughters2[daughterid],RELATIONS_TO_RELOCATE_SUB,drel,sentence_id).each do |node|
		  relocate << node
		end
		
		relocate.each do |node|
		  if node 
		    verb_daughters << node
		    verb_daughters_rels << drel[node] 
		  end	
		end
		
			
		add_empty_verb(verb_head,verb_rel,verb_daughters,verb_daughters_rels,empty_tokens,did,dhead_id,dpos,dmorph,dlemma,drel)
	    @non_v_roots.puts "#{sentence_id},#{empty_tokens[0].last},#{id},#{daughterid},#{dlemma[daughterid]} dat-subjekt"		
	  end	
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_dat_subjekt(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  end
  if daughters[0].length>0
    convert_dat_subjekt(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  end
end

def insert_verb?(daughterid,drel,dpos,dmorph,empty_tokens,sentence_id,daughters)
  (drel[daughterid]=="pred" or drel[daughterid]=="parpred") and !finite(daughterid,dpos,dmorph) and not(check_empty_tokens(empty_tokens,daughterid,"V")) and not(check_conjunct_empty_verb([],daughters,daughterid,empty_tokens,dpos)) and not (check_conjunct_finite([],daughters,daughterid,dpos,dmorph)) and not dmorph[daughterid][3] == "n" and not check_conjunct([],"substring",3,3,"yes",0,dmorph,"n",daughterid,dpos,daughters,sentence_id) #the last pair of conditions excluded чтобы вспыхнуть
end

#TODO: the problem of сколько грусти and null verbs under 1-kompls
#BEWARE: unlike in convert_predik etc., in this method daughterid = the id of the "quasi"-verb that will be governed by a new verb. In other words, daughterid here is ~the same as id there
def add_root_verb(id=0,backup=[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  if daughters[id][0]!=nil  #if there is where to go now
    daughterid = daughters[id][0]
	toinsert = false
    if insert_verb?(daughterid,drel,dpos,dmorph,empty_tokens,sentence_id,daughters) 
      toinsert = true
	  daughters[id].each do |node|
	    if dpos[node]=="C-" and insert_verb?(node,drel,dpos,dmorph,empty_tokens,sentence_id,daughters) #if there is an immediate daughter conjunction that governs a verbless predication where a verb WILL be inserted then don't insert here
		  toinsert = false
		  #These leads to the "суть да дело" effect (Bez_epokhi.126), but renders the Bessonnitsa.31 correctly
		end
	  end
	  if dlemma[daughterid]=="ЧЕМ"
	    if checkalldaughters(daughters2[daughterid],"соотнос","соотнос",drel,sentence_id)
		  toinsert = false
		elsif dpos[id]=="C-"
		  ttt=return_all_conjuncts([],[],id,dpos,daughters2,sentence_id,drel)  
		  ttt.each do |sister|
		    if checkalldaughters(daughters2[sister],"соотнос","соотнос",drel,sentence_id)
			  toinsert = false
			end
		  end
		end	
		#to exclude чем-тем 
	  end
	  
	  if toinsert
	    
        
		relocate=[]
		verb_daughters = []
		verb_daughters_rels = []
	    if drel[daughterid]=="pred"
	      verb_head=dhead_id[daughterid] #PARPREDS under root, PREDS under the id's head
	    elsif drel[daughterid]=="parpred"
		  verb_head=0
	    end
        verb_rel=drel[daughterid]
		verb_daughters << daughterid #the former daughter becomes a daughter
		if (checkalldaughters("no",daughters2[daughterid],"sub","sub",drel,sentence_id)!=nil or checkalldaughters("no",daughters2[daughterid],"предик","предик",drel_old,sentence_id)!=nil or checkalldaughters("no",daughters2[daughterid],"дат-субъект","дат-субъект",drel_old,sentence_id)!=nil) #TODO: add more? 
	      
		  verb_daughters_rels << "xobj" 
		elsif dpos[daughterid]=="Nb" or dpos[daughterid]=="Ne" #example of an error: Somnambula_v_tumane.272, свернулись -- увечье. But how to catch it?
          verb_daughters_rels << "sub" 
		else 
		  verb_daughters_rels << "xobj"
	    end
		
		checkalldaughters2(daughters2[daughterid],RELATIONS_TO_RELOCATE,drel,sentence_id).each do |node|
		  relocate << node
		end
		
		relocate.each do |node|
		  if node 
		    verb_daughters << node
		    verb_daughters_rels << drel[node] 
		  end	
		end
				
		add_empty_verb(verb_head,verb_rel,verb_daughters,verb_daughters_rels,empty_tokens,did,dhead_id,dpos,dmorph,dlemma,drel)
		@non_v_roots.puts "#{sentence_id},#{empty_tokens[0].last}, #{id}, #{daughterid}, add_root_verb" #for the record
				
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    add_root_verb(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  end
  if daughters[0].length>0
    add_root_verb(0,[],daughters,daughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  end
end

def refill_daughters(dhead_id,did)
  allthedaughters=Array.new(1100) {Array.new(1,-10)} 
  did2=did.compact
  i=1
  begin
    if dhead_id[did2[i]]!=0	    
   		allthedaughters[dhead_id[did2[i]]] << did2[i]
			  else 
	    allthedaughters[0] << did2[i]
	end  
	i=i+1
  end until did2[i]==nil
  
  for r in 0..1099 #remove all the -10s
	allthedaughters[r].shift
  end
  
  return allthedaughters
end


def verify_coordination(id=0,backup=[],daughters,daughters2,drel,sentence_id,dpos, did, dhead_id) #checks whether there any coordinated groups where the conjunction has relation A, but the conjuncts have (an old) relation B (can emerge in e.g. convert_kolichest)
  if daughters[id][0]!=nil  #if there is where to go now
    
	daughterid = daughters[id][0]
	
	if drel[daughterid] == "fff2"
      if !SINGLE_RELS.include?(drel[id])
	    #the fff2 conjuncts get their old head and relation
		daughters2[id].each do |node|
		  dhead_id[node] = dhead_id[id]
		  drel[node] = drel[id]
		end
		did[id]=nil #the conjunction is erased
		drel[id]=nil #extra caution
		dhead_id[id]=nil 
	  end
	end  
	
	if (drel[daughterid][0..2] == "fff")
      drel[daughterid] = drel[id]	   
	end
    
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end

  if backup.length>0 
    verify_coordination(id,backup,daughters,daughters2,drel,sentence_id,dpos, did, dhead_id)
  end  
  if daughters[0].length>0
    verify_coordination(0,[],daughters,daughters2,drel,sentence_id,dpos,did, dhead_id)
  end
end

def choose_head_for_nesobst(daughters2,drel,sentence_id,id,daughterid,dlemma,dhead_id)
  choice = nil
  prisv = checkalldaughters2(daughters2[id],"присвяз",drel,sentence_id)[0]
  kompl1 = checkalldaughters2(daughters2[id],"1-компл",drel,sentence_id)[0]
  kompl2 = checkalldaughters2(daughters2[id],"2-компл",drel,sentence_id)[0]
  predik = checkalldaughters2(daughters2[id],"предик",drel,sentence_id)[0]
  
  if prisv 
    choice = prisv
  elsif kompl1 and !["БЫТЬ.ipf","ИЗ","ДО","У"].include?(dlemma[kompl1]) #У here means possessive construction, cf. Nadpisi_iz_doliny_Inda.53, we want to avoid them, the other two prepositions lead to wrong attachments, БЫТЬ to avoid не могло-1-kompl-быть и речи
    choice = kompl1 #sometimes it has to be predik, even if kompl1 is present, e.g. Faraony_sobstvennoi_personoi.7
  elsif kompl2 
    choice = kompl2 #just one case
  elsif predik 
    choice = predik
	
  else	#if the node in question does not have siblings that are plausible candidates
    id = dhead_id[id] #go up one level (often necessary for constructions with auxiliaries: быть, должен, можно etc.)
	if id!=0 #unless we reached the root
      choice = choose_head_for_nesobst(daughters2,drel,sentence_id,id,daughterid,dlemma,dhead_id) #repeat
	else  
  	  report_nesobst_error("head",sentence_id,dlemma[daughterid],"","",drel,daughterid)
	end  
  end
  
  return choice
  
end



def report_nesobst_error(type,sentence_id,lemma,head_lemma,head_pos,drel,daughterid)
  drel[daughterid] = "adv" #just as a dummy solution
  if !@excluded_sentences.include?(sentence_id)
    @excluded_sentences << sentence_id
  end
  if type == "head"
    @flags.puts "A1. Nesobst: Can't find a head going up. Sentence #{sentence_id}, token #{lemma}"
  elsif type == "pos"
    @flags.puts "A1. Nesobst: Sentence #{sentence_id}, token #{daughterid}, new head #{head_lemma} is #{head_pos}"
  else
    #STDERR.puts "Unknown type in report_nesobst_error"
  end

end


def convert_nesobst(id=0,backup=[],daughters,daughters2, drel,sentence_id,dhead_id,dlemma,dpos) #go recursively through the tree from top and convert relations
  if daughters[id][0]!=nil  #if there is where to go down now
    daughterid = daughters[id][0] 
    if drel[daughterid].include?("несобст") #covers nesobst-agent and 4 nesobst-kompls
	  if dlemma[daughterid] == "У"
	    choice = id #for possessive constructions: keep it on the verb	    
	  else
        choice = choose_head_for_nesobst(daughters2,drel,sentence_id,id,daughterid,dlemma,dhead_id) #Looking for a real head of the nesobst-relation
	  end
	  
	  if choice #if we managed to find the head
                
		#In some cases the  head definitely has to be changed
		if dpos[choice]=="R-" #Which actually means "В". We'll find the immediate daughter of the preposition and take it as the head
		  choice = checkalldaughters2(daughters2[choice],"предл",drel,sentence_id)[0]
		elsif dpos[choice]=="Df" and (dlemma[choice]=="МНОГО" or dlemma[choice]=="НЕМАЛО") #We'll find the immediate daughter of the adverb
		  choice = checkalldaughters2(daughters2[choice],"1-компл",drel,sentence_id)[0]
		elsif dpos[choice]=="Px" #Which means НИЧТО as in "НИЧЕГО ОБЩЕГО C...". We'll find общего -- RIGHT? Or should we keep on НИЧТО? 
		  temp = checkalldaughters2(daughters2[choice],"опред",drel,sentence_id)[0]
		  if temp #to prevent erroneous relocations in cases like Tranzit_18.74 (which has a source error anyway, but still)
		    choice = temp
		  end
		elsif dpos[choice]=="Ma" #один из, as in Ya_49.48
		  temp = checkalldaughters2(daughters2[choice],"электив",drel,sentence_id)[0]
		  choice = checkalldaughters2(daughters2[temp],"предл",drel,sentence_id)[0]
		end
		
		if choice #if the check above did not leave us without a head
          if dpos[choice]=="V-"
		    drel[daughterid] = "adv"
		  elsif dpos[choice]=="A-"  
		    drel[daughterid] = "obl" #RIGHT?
		  elsif dpos[choice]=="Df" #cases like НЕМАЛО and МНОГО already covered above
            drel[daughterid] = "adv"
		  elsif NONARG.include?(dlemma[choice]) 
		    drel[daughterid] = "atr"
            nesobstnargs = File.open("dub_nargs.txt","w") #Maybe it's worth to reconsider some of the NON-nargs? контакт, предел, вкус...
       	    nesobstnargs.puts "Sentence #{sentence_id}, token #{daughterid}, new head #{dlemma[choice]} does not take NARGs"
       	    nesobstnargs.close
		  elsif dpos[choice]=="Nb" or dpos[choice]=="Ne" or dpos[choice]=="Pr" or dpos[choice]=="Pi" or dpos[choice]=="Pp" #Pr means КОТОРЫЙ, cf. Okhota.29. We can find the noun which governs the head verb of the clause via релят and take it as a head. This makes sense semantically, but maybe not syntactically (we'll certainly cause non-projectivity). Should we do that instead of keeping КОТОРЫЙ as the head instead? (Pi means ЧТО, same reasoning applies, see Lunnye_kamni.242. Same problem/question for Pp, see Privatizatsiya_istorii.22.)
		    drel[daughterid] = "narg"
		  else #The head has an unusual POS and we do not really know what to do with it.
		    report_nesobst_error("pos",sentence_id,dlemma[daughterid],dlemma[choice],dpos[choice],drel,daughterid)
          end
		  dhead_id[daughterid] = choice #relocate the node in question
		else  
		  report_nesobst_error("head",sentence_id,dlemma[daughterid],"","",drel,daughterid)
		end
	  else
	    report_nesobst_error("head",sentence_id,dlemma[daughterid],"","",drel,daughterid)
	  end
	end
	
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  if backup.length>0 
    convert_nesobst(id,backup,daughters,daughters2,drel,sentence_id,dhead_id,dlemma,dpos)
  end
end

def verify_coordination_pred(id=0,backup=[],daughters,drel,sentence_id,dpos) 
  if daughters[id][0]!=nil  #if there is where to go now
    
	daughterid = daughters[id][0]
	if dpos[id] == "C-" and (drel[daughterid][0..2] == "fff") and (drel[id]=="parpred" or drel[id]=="pred")
      drel[daughterid] = drel[id]	 
	end
    
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end

  if backup.length>0 
    verify_coordination_pred(id,backup,daughters,drel,sentence_id,dpos)
  end  
  if daughters[0].length>0
    verify_coordination_pred(0,[],daughters,drel,sentence_id,dpos)
  end
end

def catch_multiple_rels(id=0,backup=[],daughters,daughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) 
  if daughters[id][0]!=nil  #if there is where to go now
    
	daughterid = daughters[id][0]
	if dpos[daughterid]=="V-"
	  SINGLE_RELS.each do |rel|
        t = checkalldaughters2(daughters2[daughterid],[rel],drel,sentence_id) 
		if t.length>1 
		  @flags.puts "#{sentence_id}, multiple relations! #{t[0]},#{t[1]} and maybe more have #{rel} under #{daughterid}"
		  if !@excluded_sentences.include?(sentence_id)
		    @excluded_sentences << sentence_id
		  end
		  
		  
		  
		  #add_empty_token(empty_tokens,"C",dpos,dmorph,dlemma)
		  #did[empty_tokens[0].last]=empty_tokens[0].last
		  #drel[empty_tokens[0].last]=rel
		  #dhead_id[empty_tokens[0].last]=daughterid
		  #t.each do |node|
		  #  dhead_id[node] = empty_tokens[0].last
		  #end
		end
	  end
	end
    
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end

  if backup.length>0 
    catch_multiple_rels(id,backup,daughters,daughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) 
  end  
  if daughters[0].length>0
    catch_multiple_rels(0,[],daughters,daughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) 
  end
end

def no_rel_heads(id=0,backup=[],daughters,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) #no adverbs, relative adverbs, pronouns should head the subordinate clauses
  if daughters[id][0]!=nil  #if there is where to go now
    
	daughterid = daughters[id][0]
	
	
	if drel[daughterid]=="pred" and (dpos[id]=="Df" or dpos[id]=="Pr" or dpos[id]=="Dq")
      dhead_id[daughterid] = dhead_id[id]
	  drel[daughterid] = drel[id]
	  dhead_id[id] = daughterid
	  
	end
	
	    
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end

  if backup.length>0 
    no_rel_heads(id,backup,daughters,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) 
  end  
  if daughters[0].length>0
    no_rel_heads(0,[],daughters,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) 
  end
end

DEPS = {"N"=>["adnom", "apos", "atr", "aux", "comp", "narg", "part", "rel"], "V"=>["adv", "ag", "apos", "arg", "aux", "comp", "nonsub", "obj", "obl", "per", "piv", "sub", "xadv", "xobj", "atr", "part"],"A"=>["adv", "apos", "atr", "aux", "comp", "obl", "part"],"P"=>["apos", "atr", "aux", "part", "rel"]}

def minas_tirith(id=0,backup=[],daughters,daughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id,slash_rel,slash_target) #the last filter to catch forbidden relation combinations
  if daughters[id][0]!=nil  #if there is where to go now
    
	daughterid = daughters[id][0]
	if drel[daughterid]=="expl"
      @flags.puts "Minas Tirith filter: #{sentence_id}, node #{did[daughterid]} has the dummy expl, a remnant of an incorrectly processed coordination"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	end
	
	#STDERR.puts dlemma[id], dlemma[daughterid]
	#STDERR.puts drel[daughterid]
	#STDERR.puts dpos[id]
	if DEPS.keys.include?(dpos[id][0]) and !DEPS[dpos[id][0]].include?(drel[daughterid])
      @flags.puts "Minas Tirith filter: #{sentence_id}, node #{did[id]} is a #{dpos[id][0]} and has a forbidden dependent: #{drel[daughterid]}"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. Forbidden dependent under #{dpos[id][0]}: #{drel[daughterid]}"
	  end
	  
	end
	
	if id==0 and drel[daughterid]!="pred" and drel[daughterid]!="parpred" and drel[daughterid]!="voc"
      @flags.puts "Minas Tirith filter: #{sentence_id}, the root #{dlemma[id]} has a forbidden dependent #{did[daughterid]}"
	  
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. Forbidden dependent under root"
	  end
	  
	  
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	end

	if id==0 
	  t = checkalldaughters2(daughters2[id],"pred",drel,sentence_id)
	  if t.length>1 
		@flags.puts "#{sentence_id}, multiple nodes  #{t[0]},#{t[1]} and maybe more have PRED under ROOT"
		if !@excluded_sentences.include?(sentence_id)
		  @excluded_sentences << sentence_id
		end
		if !@erase_trees.include?(sentence_id)
	      @erase_trees << sentence_id
		  @flags.puts "Tree erased: #{sentence_id}. Several PREDs under ROOT"
	    end
	  
	  end
	end
	
	if !(dpos[id]=="C-" and drel[id]=="pred")#id==0 or dpos[id]=="G-"
	  preddaughter = 0
	  daughters2[id].each do |daughty|
	    if drel[daughty]=="pred"
		  preddaughter +=1
		  if preddaughter > 1
		    break
		  end
		end
	  end
	  if preddaughter > 1
        @flags.puts "Minas Tirith filter: #{sentence_id}, the node #{did[id]} has more than one PRED dependent"
	    if !@excluded_sentences.include?(sentence_id)
	      @excluded_sentences << sentence_id
	    end
	  end
	end
	
	
	if (drel[daughterid]=="voc" or drel[daughterid]=="parpred") and id!=0 and dpos[id]!="C-"
	  @flags.puts "Minas Tirith filter: #{sentence_id}, the node #{did[daughterid]} is a VOC or PARPRED under an illegitimate head: #{dpos[id]}"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. VOC OR PARPRED under an illegitimate head"
	  end
	end
	
	if (drel[daughterid]=="xobj" or drel[daughterid]=="xadv" or drel[daughterid]=="piv") and dpos[id]!="V-" and dpos[id]!="C-"
	  @flags.puts "Minas Tirith filter: #{sentence_id}, the node #{dlemma[daughterid]} is an XADV, XOBJ or a PIV under an illegitimate head: #{dpos[id]}"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. XADV, XOBJ or a PIV under an illegitimate head"
	  end
	end

	if (drel[daughterid]=="xobj" or drel[daughterid]=="xadv") and slash_rel[daughterid]==nil and dpos[id]!="C-"
	  @flags.puts "Minas Tirith filter: #{sentence_id}, the node #{dlemma[daughterid]} is an XADV or XOBJ and does not have an outgoing slash edge"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. An XADV or XOBJ does not have an outgoing slash edge"
	  end
	end

	if drel[daughterid]=="pred" and dpos[id]!="G-" and dpos[id]!="C-" and dhead_id[daughterid]!=0
      @flags.puts "Minas Tirith filter: #{sentence_id}, node #{did[daughterid]} is a pred under an illegitimate head: #{dpos[id]}"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. PRED under illegitimate head"
	  end
	end
	
	if dpos[daughterid]=="G-" and !["comp","adv","aux","atr","apos"].include?(drel[daughterid])
	  @flags.puts "Minas Tirith filter: #{sentence_id}, node #{did[daughterid]} #{dlemma[daughterid]} is a subjunction under an illegitimate relation: #{drel[daughterid]}"
	  if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. A subjunction under an illegitimate relation"
	  end
	end
	
	
	if dpos[id]=="C-"
      rels = Hash.new(0)
	  
	  daughters2[id].each do |daughty|
	    rels[drel[daughty]]+=1
	  end
	  errorcode = 0
	  if rels.keys.length > 2 #more than two dependents. We disregard the exception obj-comp, obl-comp and adv-xadv
	    errorcode = 1
	  elsif	rels.keys.length == 2
	    if !rels.keys.include?("aux") 
		  errorcode = 1
	    else
		  if rels[drel[id]] < 2 #the coordinated relations should go to at least two dependents
		    errorcode = 2
		  end
	    end
	  else
	    if rels[drel[id]] < 2
		  errorcode = 2 #the coordinated relations should go to at least two dependents
		end
	  end
	  
	  if errorcode == 1
	    @flags.puts "Minas Tirith filter: #{sentence_id}, the conjunction  #{did[id]} has too many different relations"
	    if !@excluded_sentences.include?(sentence_id)
	      @excluded_sentences << sentence_id
	    end
	  elsif errorcode == 2	
	    @flags.puts "Minas Tirith filter: #{sentence_id}, the conjunction  #{did[id]} does not have two or more dependents with the same relation as itself"
	    if !@excluded_sentences.include?(sentence_id)
	      @excluded_sentences << sentence_id
	    end
	  end
	end


    if slash_rel[daughterid]!=nil
   #   STDERR.puts "Checking slash from #{daughterid}"
	  if !slash_target_head(slash_target[daughterid], id, dhead_id)
	#    STDERR.puts "Wrong slash"
		@flags.puts "Minas Tirith filter: #{sentence_id}, node #{did[daughterid]} #{dlemma[daughterid]} has a slash that does not target its head or a node dominated by the head: #{slash_target[daughterid]}"
	    if !@excluded_sentences.include?(sentence_id)
	      @excluded_sentences << sentence_id
	    end
	    if !@erase_trees.include?(sentence_id)
	      @erase_trees << sentence_id
		  @flags.puts "Tree erased: #{sentence_id}. A slash that does not target its head or a node dominated by the head"
	    end
	  end
	  
    end	

    if !RELATIONS0.include?(drel[daughterid])
      if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. An illegitimate relation #{drel[daughterid]}"
	  end
    end    
	
	if !POS_ALL.include?(dpos[daughterid])
      if !EMERGENCY_POS[dpos[daughterid]].nil?
        dpos[daughterid] = EMERGENCY_POS[dpos[daughterid]]
      else
        if !@excluded_sentences.include?(sentence_id)
	      @excluded_sentences << sentence_id
	    end
	    if !@erase_trees.include?(sentence_id)
	      @erase_trees << sentence_id
		  @flags.puts "Tree erased: #{sentence_id}. An illegitimate pos #{dpos[daughterid]}"
	  end
      end
    end    
	
		
    backup << id #mark where we are going
    id=daughters[id].shift #where to go
  else
    id=backup.pop #if not, prepare to go back where we were
  end
  
  
  if backup.length>0 
    minas_tirith(id,backup,daughters,daughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id,slash_rel,slash_target) 
  end  
  if daughters[0].length>0
    minas_tirith(0,[],daughters,daughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id,slash_rel,slash_target) 
  end
end

def minas_tirith2(did,dmorph,drel,sentence_id)
  did2=did.compact[1..-1]
  did2.each do |node|
    if !RELATIONS0.include?(drel[node])
      if !@excluded_sentences.include?(sentence_id)
	    @excluded_sentences << sentence_id
	  end
	  if !@erase_trees.include?(sentence_id)
	    @erase_trees << sentence_id
		@flags.puts "Tree erased: #{sentence_id}. An illegitimate relation #{drel[node]}"
	  end
    end    
  end
end



def slash_target_head(checkedid,currenthead,dhead_id)
  #outcome = false
  #STDERR.puts "slash target or its head #{checkedid}, desired head #{currenthead}"
  if currenthead == checkedid
    outcome = true
	#STDERR.puts outcome
	return outcome
  elsif checkedid == 0 
    outcome = false
	#STDERR.puts outcome
	return outcome
  else#if outcome==nil
    #STDERR.puts "check continued"
    outcome=slash_target_head(dhead_id[checkedid],currenthead,dhead_id)
  end
  #STDERR.puts "check done: #{outcome}"
  return outcome
end


def find_head_lemma(sentence,daughterid) #NOT USED, CAN BE REMOVED
  headlemma = "NOTFOUND"
  dlemma = {}
  dhead_id = {}
  
  sentence.children.each do |w|
	id=w['ID'].to_i
	if id!=0 
	  dlemma[id] = asplem(w,w['FEAT'].to_s.split) if w['LEMMA'] 
	  if dlemma[id]==nil 
	    dlemma[id]="PHANTOM"
	  end
	  dhead_id[id] = w['DOM'].to_i
	  
	end
  end
  headlemma = dlemma[dhead_id[daughterid]]
  return headlemma
end

def extract_meta(file,div)
  status = 0
  title = ""
  author = ""
  place = ""
  file.each_line do |line|
    line1 = line.strip
	if status == 1 
	  if line1 == "</inf>"
	    break
	  elsif line1[0..6]=="<title>"
	    title = line1[7..-9]
	  elsif line1[0..7]=="<author>"	
	    author = line1[8..-10]
	  elsif line1[0..7]=="<source>"	
	    place = line1[8..-10]
	  end
    elsif status == 0
	  if line1 == "<inf>"
	    status = 1
	  end	
	end
  end
  if title == ""
    title = "#{div}"
  end
  if place == ""
    if div.include?("Korp") or div.include?("Nagibin") or div.include?("Grekova") or div.include?("Bitov") 
	  place = "Уппсальский корпус"
	end
  end
  if author == ""
    if div.include?("Nagibin") 
	  author = "Ю. Нагибин"
	elsif div.include?("Grekova") 
      author = "И. Грекова"
	elsif div.include?("Bitov") 
	  author = "А. Битов"
	end
  end
  
  return [title, author, place]
end

#STDOUT.puts "<title>SynTagRus</title>"
#STDOUT.puts "<citation-part>SynTagRus</citation-part>"

@flags.puts "Warning levels: 1 - definitely an error, 2 - most probably an error, 3 - possibly an error, 4 - most probably not an error. A -- relevant for verb profiles, B -- probably relevant, C -- relevant, but currently considered irreparable, D -- most probably not relevant, but otherwise rather important, E -- not relevant and not really important anyway"
@flags.puts "Other C-level issues: no PID slashes; no shared-dependent slashes; probable lack of empty verbs (почему столько грусти); probable failure to relocate all the dependents to a proper place when the tree is being changed (e.g. with numerals)"

sentence_tag_status = ""
editorial_note = "The annotation was automatically converted from SynTagRus (http://ruscorpora.ru/search-syntax.html), with kind permission of Igor Boguslavsky and Leonid Iomdin. The conversion script was developed by Aleksandrs Berdicevskis and Hanne Eckhoff. We used the Syntagrus release of 2014-02-11. We corrected some minor errors in the release manually before conversion. The meaning of annotation statuses are as follows: Annotated -- the conversion went normally; Unannotated -- there are reasons to believe that the converted tree has at least one serious error; Reviewed -- the sentence was manually checked by a human annotator. The conversion accuracy is estimated as follows: LAS 93%, UAS 96%, POS 98%, morphological features 99%. These numbers come from on a manual check (by HE and AB) of 100 randomly sampled sentences with the \"Annotated\" status. See readme.txt for more information."

unique_sentence_id = 0
ids = [[],[]]
data = []
@div = nil
of = File.new("temp.txt","w")
of.close
#filelist = Dir.entries("syntagrus_all_files").reject{|a| a == "." or a == ".."}

nwords = 0
nwords_annotated = 0
nwords_unannotated = 0
nwords_no_syntax = 0
words_per_sentence = Hash.new(0)


(doc/"S").each do |s|
  sentence_id = s['ID']
  
  unique_sentence_id = unique_sentence_id+1
  ids[0] << unique_sentence_id
  ids[1] << sentence_id
  
  div = sentence_id.split('.')[0]
  STDERR.puts "now running on #{sentence_id}"
  
  if @div == div #the same text continues
    sentence_tag_status = "close_open"
	#of.puts "</sentence>\n<sentence id=\"#{unique_sentence_id}\">"
  elsif @div == nil
    #new file
	of = File.new("converted/#{div}.xml","w")
	of.puts '<proiel schema-version="2.0">'
    of.puts "<source id='#{div.downcase}' language='rus'>"
    
	if !testmode
	
	  info_source = File.open("syntagrus_all_files/#{div}.tgt","r:utf-8")
	  metadata = extract_meta(info_source,div)
	  title = metadata[0]
	  author = metadata[1]
	  place = metadata[2]
	  info_source.close
	else 
	  title = "title"
	  author = ""
	  place = ""
	end   
	
	of.puts "<title>#{title}</title>" #"<title>#{@div.gsub(/_/,' ')}</title>"	
	of.puts "<citation-part>Syntagrus</citation-part>" 
	  
	of.puts "<editorial-note>#{editorial_note}</editorial-note>" 
	if author !=""
	  of.puts "<author>#{author}</author>" 
	end
	if place !=""
	  of.puts "<printed-text-place>#{place}</printed-text-place>"	  
	end
		
    @div = div
    of.puts "<div>"
	of.puts "<title>Syntagrus #{title}</title>"

	sentence_tag_status = "open"
    #of.puts "<sentence id=\"#{unique_sentence_id}\">"
  else #old file finished, time to open new file
    
    of.puts "</sentence>"
    of.puts "</div>"
    of.puts "</source>"
    of.puts "</proiel>"
	of.close
	
	
	
	of = File.new("converted/#{div}.xml","w")
	of.puts '<proiel schema-version="2.0">'
    of.puts "<source id='#{div.downcase}' language='rus'>"
	
	if !testmode
	
	  info_source = File.open("syntagrus_all_files/#{div}.tgt","r:utf-8")
	  metadata = extract_meta(info_source,div)
	  title = metadata[0]
	  author = metadata[1]
	  place = metadata[2]
	  info_source.close
	else 
	  title = "title"
	  author = ""
	  place = ""
	end   
	
	of.puts "<title>#{title}</title>" #"<title>#{@div.gsub(/_/,' ')}</title>"
	of.puts "<citation-part>Syntagrus</citation-part>" 
	
	of.puts "<editorial-note>#{editorial_note}</editorial-note>" 
	if author !=""
	  of.puts "<author>#{author}</author>" 
	end
	if place !=""
	  of.puts "<printed-text-place>#{place}</printed-text-place>"	  
	end
	
	
	
	
	
	
    @div = div
    of.puts "<div>"
	of.puts "<title>Syntagrus #{title}</title>"
    sentence_tag_status = "open"
	#of.puts "<sentence id=\"#{unique_sentence_id}\">"
	
  end
  
  #defining arrays for keeping information about the whole sentence
  dfeats=Array.new(1,-10)
  dpos=	Array.new(1,-10)
  dform=Array.new(1,-10)
  dlemma=Array.new(1,-10)
  drel=Array.new(1,-10)
  drel_old=Array.new(1,-10)
  dhead_id=Array.new(1,-10)
  dprepunc=Array.new(1,-10)
  dpostpunc=Array.new(1,-10)
  #dsign_for_prepunc = Array.new(1,-10)
  #dsign_for_postpunc = Array.new(1,-10)
  did=Array.new(1,-10)
  slash_rel=Array.new(1,-10)
  slash_target=Array.new(1,-10)
  empty_tokens=Array.new(3) {Array.new(1,-10)}
  dmorph=Array.new(1,-10)
  allthedaughters=Array.new(1100) {Array.new(1,-10)} 
  
  #converting verbal phantoms to empty tokens
  s.children.each do |w| 
	if w['NODETYPE']=='FANTOM' and pos(w,s)=="V-"	  
	  id=w['ID'].to_i
	  empty_tokens=add_empty_token(id,empty_tokens, "V",dpos,dmorph,dlemma)
	  original_id=id
	  id=empty_tokens[0].last
	  did[id] = id
	  dhead_id[id] = w['DOM'].to_i
	  if empty_tokens[2].include?(dhead_id[id]) #if the head was a phantom, too, then use its old id to restore the new id it got as an empty token (>=1000)
	    dhead_id[id]=empty_tokens[0][empty_tokens[2].index(dhead_id[id])]	  
	  end
	  @non_v_roots.puts "#{sentence_id},#{empty_tokens[0].last} phantom"
    end	  
  end
  
  #this cycle fills the arrays with info about the sentence
  s.children.each do |w|
    if w.name == "W"
      nwords += 1
      words_per_sentence[sentence_id] += 1
    end
	id=w['ID'].to_i
	if id!=0 
      dhead_id[id] = w['DOM'].to_i
	  for j in 1..empty_tokens[2].length
	    if dhead_id[id]==empty_tokens[2][j]
		  dhead_id[id]=empty_tokens[0][j]		  
		end 
		if id==empty_tokens[2][j]
		  id=empty_tokens[0][j]
		end
	  end
	  
	  drel[id] = w['LINK']
	  if drel[id]==nil 
	    drel[id]="pred"
	  end	
	  
	  dfeats[id] = w['FEAT'].to_s.split
      dform[id] = w.inner_html.chomp
      dlemma[id] = asplem(w,dfeats[id]) if w['LEMMA'] #downcase not working on Cyrillic #can be amended by using UnicodeUtils
	  if dlemma[id]==nil #hopefully it will be deleted later
	    dlemma[id]="PHANTOM"
	  end
	  dlemma[id].gsub!(",",".") #Currently lemmas cannot have commas within (will not be imported)
	  did[id] = id
	  dmorph[id] = morphtag(w,s)
	  dpos[id] = pos(w,s)
	  
	  if dhead_id[id]!=0	    
		allthedaughters[dhead_id[id]] << id
	  else 
	    allthedaughters[0] << id
      end  
	  
      #TODO: why is there no space after question mark in the output?

      if w.previous_sibling.name != 'W' and w.previous_sibling.text =~ /\n./
        dprepunc[id] = w.previous_sibling.text.gsub(/.*\n/,'')
      else dprepunc[id] = ""
      end
 
      

      if w.next_sibling.name != 'W' and w.next_sibling.text =~ /.\n/
        dpostpunc[id] = w.next_sibling.text.gsub(/\n.*/,'')
      else dpostpunc[id] = ""
      end       

    end
  end 
    
  for r in 0..1099 #remove all the -10s
	allthedaughters[r].shift
  end
 
  s.children.each do |w| #converting non-verbal phantoms 
	if w['NODETYPE']=='FANTOM' and pos(w,s)!="V-"	  	  
	  id=w['ID'].to_i
	  did[id]=nil #the node erased	  
	  if allthedaughters[id][0]!=nil #if it didn't have daughters, we are done. if not:
		dhead_id[allthedaughters[id][0]]=dhead_id[id] #the first daughter is the heir
		drel[allthedaughters[id][0]]=drel[id] #it inherits the relation
		if allthedaughters[id][1]!=nil #if it has siblings...
	      @flags.puts "#{sentence_id}, 2B, deleted phantom had more than one daughter node, check that the correct one was promoted"	  #was she the legal heir?
		  jj=1
		  begin 
		    dhead_id[allthedaughters[id][jj]]=allthedaughters[id][0] #siblings bow to the crown princess
		    jj=jj+1
		  end until allthedaughters[id][jj]==nil
	    end   
	  end
	  dhead_id[id]=nil #erase the node from here too
	  allthedaughters=refill_daughters(dhead_id,did)
	end
  end
  

  dirspeech_conj(did,drel,dpos) #dealing with direct speech: converting n-kompls that govern conjunctions to parpred before such conjuctions stop being heads
  conj_root(did,dhead_id,drel,sentence_id)  	#dealing with single conjuctions that introduce clauses or sentences #TODO: if the head is not a verb, insert one?
  kill_subconj_root(did,dhead_id,drel,dpos,sentence_id,dlemma)
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did)
  convert_nesobst(0,[],allthedaughters,allthedaughters2, drel,sentence_id,dhead_id,dlemma,dpos) #predik, kompls and xobj have to be NOT converted
  allthedaughters=refill_daughters(dhead_id,did)
  coord(0,[],allthedaughters,drel,dhead_id,empty_tokens,did,dpos,sentence_id,dmorph, dlemma) #handling coordination
  convert_vocative(did,dmorph,drel)
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did)
  convert_kolich_kopred(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id) #must precede konvert_kolichest
  allthedaughters=refill_daughters(dhead_id,did)
  convert_kolichest(0,[],allthedaughters,drel,dlemma,sentence_id,dmorph,dhead_id,dpos)
  allthedaughters=refill_daughters(dhead_id,did)
  verify_coordination_pred(0,[],allthedaughters,drel,sentence_id,dpos) #pred gets a special treatment so that empty verbs can be inserted (otherwise add_root_verb won't find them)
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  convert_predik(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  convert_dat_subjekt(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  add_root_verb(0,[],allthedaughters,allthedaughters2, drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  convert_sub_kopr(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos,dlemma) #has to be after sub-creating methods (convert_predik, convert_dat_subjekt) and after add_root_verb
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  convert_ob_kopr(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos,dlemma,drel_old)
  allthedaughters=refill_daughters(dhead_id,did)
  convert_adr_prisv(0,[],allthedaughters,drel,sentence_id,dhead_id,dpos) 
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did)
  convert_sootnos(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos,dlemma,dmorph,empty_tokens,did) #has to be before sravn-sojuzn due to chem-tem
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did)
  convert_sravn_sojuzn(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos,dmorph,empty_tokens) 
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did)
  convert_prisvjaz(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dhead_id,dpos)
  allthedaughters=refill_daughters(dhead_id,did)
  from_above(allthedaughters,allthedaughters2,drel,dlemma,sentence_id,dmorph,empty_tokens,did,dhead_id,dpos,drel_old)  #converting relations 
  allthedaughters=refill_daughters(dhead_id,did)
  put_under_root(did,dhead_id,drel,dpos) #parpreds and vocs go under the root 
  allthedaughters=refill_daughters(dhead_id,did)
  verify_coordination_pred(0,[],allthedaughters,drel,sentence_id,dpos) #again, to cover parpreds created by put_under_root and preds and parpreds created by from_above
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  add_root_verb(0,[],allthedaughters,allthedaughters2, drel,sentence_id,dhead_id,dpos,dmorph,did,empty_tokens,dlemma,drel_old)
  allthedaughters=refill_daughters(dhead_id,did)
  convert_coms(did,drel,dpos,dhead_id,empty_tokens,dmorph,allthedaughters,sentence_id)
  allthedaughters=refill_daughters(dhead_id,did)
  convert_op_opred(0,[],allthedaughters,drel,sentence_id,dhead_id,dpos,dmorph) 
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  add_x_slashes(0,[],allthedaughters,allthedaughters2,drel,dpos,dhead_id,empty_tokens,slash_rel,slash_target,sentence_id,drel_old)
  allthedaughters=refill_daughters(dhead_id,did)
  convert_vspom(0,[],allthedaughters,drel,sentence_id,dhead_id,dpos,dlemma,dfeats,slash_rel,slash_target) #has to be used after add_x_slashes
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  
  
  verify_coordination(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dpos, did, dhead_id) 
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 

  no_rel_heads(0,[],allthedaughters,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id)  
  allthedaughters=refill_daughters(dhead_id,did)
  allthedaughters2=refill_daughters(dhead_id,did) 
  
  catch_multiple_rels(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id) 
  allthedaughters=refill_daughters(dhead_id,did)
    
  minas_tirith(0,[],allthedaughters,allthedaughters2,drel,sentence_id,dpos,empty_tokens,dmorph,dlemma,did,dhead_id,slash_rel,slash_target)
  minas_tirith2(did,dmorph,drel,sentence_id)
  
  if @erase_trees.include?(sentence_id) 
    erase_this_tree = true
    nwords_no_syntax += words_per_sentence[sentence_id]
  else
    erase_this_tree = false
  end    

  if !@excluded_sentences.include?(sentence_id) 
    annot_status = "annotated"
    annot_by = " annotated-by=\"17\""
    nwords_annotated += words_per_sentence[sentence_id]
  else
    annot_status = "unannotated"
    annot_by = ""
    nwords_unannotated += words_per_sentence[sentence_id]
  end    
	
	
  if sentence_tag_status == "close_open"
	of.puts "</sentence>\n<sentence id=\"#{unique_sentence_id}\" status=\"#{annot_status}\"#{annot_by}>"
  elsif sentence_tag_status == "open"
	of.puts "<sentence id=\"#{unique_sentence_id}\" status=\"#{annot_status}\"#{annot_by}>"
  else
	STDERR.puts "Unknown sentence tag status!"
  end
   
  #this cycle prints out the information
  did2=did.compact #remove all the nils so that the printing cycle can go uninterrupted
  i=1
  begin

	
	
    if did2[i]>999 #empty token?
	  empty=true
	else
	  empty=false
	end		
   
	if dhead_id[did2[i]]==0 #directly under root?
	  uroot=true
	else
	  uroot=false
	end  
	
	if slash_rel[did2[i]]!=nil #TODO: slash array will have to be more complex when we deal with elliptical slashes (more than one slash will be possible)
	  slash=true
	else
      slash=false
	end  

  #apostrophes should be enclosed in "", everything else in apostrophes
    if dprepunc[did2[i]].to_s.include?("\'")
      sign_for_prepunc = "\""
    else
      sign_for_prepunc = "\'"
    end
    if dpostpunc[did2[i]].to_s.include?("\'")
      sign_for_postpunc = "\""
    else
      sign_for_postpunc = "\'"
    end
    



    if !erase_this_tree	
	  if not(slash)	
	    if empty and uroot
	      of.puts "<token id=\"#{empty_tokens[0][did2[i]-999]}\" empty-token-sort=\"#{empty_tokens[1][did2[i]-999]}\" relation=\"#{drel[did2[i]]}\"/>" 
	    elsif empty and not(uroot)
	      of.puts "<token id=\"#{empty_tokens[0][did2[i]-999]}\" empty-token-sort=\"#{empty_tokens[1][did2[i]-999]}\" head-id=\"#{dhead_id[did2[i]]}\" relation=\"#{drel[did2[i]]}\"/>"
	    elsif not(empty) and uroot
	      of.puts "<token id=\"#{did2[i]}\" form=\"#{dform[did2[i]]}\" lemma=\"#{dlemma[did2[i]]}\" part-of-speech=\"#{dpos[did2[i]]}\" presentation-before=#{sign_for_prepunc}#{dprepunc[did2[i]]}#{sign_for_prepunc} morphology=\"#{dmorph[did2[i]]}\" relation=\"#{drel[did2[i]]}\" presentation-after = #{sign_for_postpunc}#{dpostpunc[did2[i]]}#{sign_for_postpunc}/>" # add token id
	    else
	      of.puts "<token id=\"#{did2[i]}\" form=\"#{dform[did2[i]]}\" lemma=\"#{dlemma[did2[i]]}\" part-of-speech=\"#{dpos[did2[i]]}\" presentation-before=#{sign_for_prepunc}#{dprepunc[did2[i]]}#{sign_for_prepunc} morphology=\"#{dmorph[did2[i]]}\" head-id=\"#{dhead_id[did2[i]]}\" relation=\"#{drel[did2[i]]}\" presentation-after = #{sign_for_postpunc}#{dpostpunc[did2[i]]}#{sign_for_postpunc}/>" # add token id
	    end    
	  else
	    if empty 
	      of.puts "<token id=\"#{empty_tokens[0][did2[i]-999]}\" empty-token-sort=\"#{empty_tokens[1][did2[i]-999]}\" head-id=\"#{dhead_id[did2[i]]}\" relation=\"#{drel[did2[i]]}\">" #add empty token sort (second row of the empty_tokens array, add token id
	  	of.puts "<slash target-id=\"#{slash_target[did2[i]]}\"	relation=\"#{slash_rel[did2[i]]}\"/>"
	  	of.puts "</token>"
	    else
	      of.puts "<token id=\"#{did2[i]}\" form=\"#{dform[did2[i]]}\" lemma=\"#{dlemma[did2[i]]}\" part-of-speech=\"#{dpos[did2[i]]}\" presentation-before=#{sign_for_prepunc}#{dprepunc[did2[i]]}#{sign_for_prepunc} morphology=\"#{dmorph[did2[i]]}\" head-id=\"#{dhead_id[did2[i]]}\" relation=\"#{drel[did2[i]]}\" presentation-after = #{sign_for_postpunc}#{dpostpunc[did2[i]]}#{sign_for_postpunc}>" # add token id
          of.puts "<slash target-id=\"#{slash_target[did2[i]]}\" relation=\"#{slash_rel[did2[i]]}\"/>"
	  	of.puts "</token>"
	    end    
      
      end	
	elsif erase_this_tree
      if !empty #TODO2017: removing all info about empty tokens and slashes
	    of.puts "<token id=\"#{did2[i]}\" form=\"#{dform[did2[i]]}\" lemma=\"#{dlemma[did2[i]]}\" part-of-speech=\"#{dpos[did2[i]]}\" presentation-before=#{sign_for_prepunc}#{dprepunc[did2[i]]}#{sign_for_prepunc} morphology=\"#{dmorph[did2[i]]}\" presentation-after = #{sign_for_postpunc}#{dpostpunc[did2[i]]}#{sign_for_postpunc}/>" # add token id
	  end    
	end
	i=i+1
  end until did2[i]==nil

end

of.puts "</sentence>"
of.puts "</div>"
of.puts "</source>"
of.puts "</proiel>"
of.close

ids[0].each_index do |ind|
  @sentence_ids.puts "#{ids[0][ind]}, #{ids[1][ind]}"
  if @excluded_sentences.include?(ids[1][ind])
    @crit_flags.puts "#{ids[0][ind]}, #{ids[1][ind]}"
  end
end


wordstat = File.open("wordstat.txt","w:utf-8")
wordstat.puts "Words in total: #{nwords}"
wordstat.puts "Words in annotated sentences: #{nwords_annotated}"
wordstat.puts "Words in sentences where the tree is present, but the status is \"unannotated\": #{nwords_unannotated-nwords_no_syntax}"
wordstat.puts "Words in sentences where the tree is not present: #{nwords_no_syntax}"



wordstat.puts "#{@erase_trees.length} sentences with erased trees"


__END__
#Must have or inherit one outgoing slash edge
#Root daughters may be PREDs, VOCs or PARPREDs
#There can only be one PRED node under the root
#The head of a PARPRED relation must be the root node or a valid coordination
#The head of a VOC relation must be the root node or a valid coordination
#The head of an XOBJ, XADV or PIV relation must be a verbal node or a valid coordination
#Slash must target the node's head or a node dominated by the head
#The head of a PRED relation must be the root node, a subjunction or a valid coordination
#A subjunction may only be the dependent in a COMP, ADV, AUX, ATR or APOS relation
?All slashes must point to tokens in the same sentence
