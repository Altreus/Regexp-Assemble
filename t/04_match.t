# 04_match.t
#
# Test suite for Regexp::Assemble
# Tests to see than an assembled regexp matches all that it is supposed to
#
# copyright (C) 2004 David Landgren

use strict;
use Test::Simple tests => 4190;
use Regexp::Assemble;

sub match {
    my $r = Regexp::Assemble->new;
    my $tag = shift;
    my $str;
    for $str (@_) {
        $r->insert(split //, $str);
    }
    my $re = $r->re;
    for $str (@_) {
        ok( $str =~ /^$re$/, "$tag $str" ) or print "# $str\n# $re\n";
    }
}

match( 'foo', qw[ foo bar rat quux ]);

match( '.[ar]it 1', qw[ bait brit frit gait grit tait wait writ ]);

match( '.[ar]it 2', qw[ bait brit gait grit ]);

match( '.[ar]it 3', qw[ bit bait brit gait grit ]);

match( '.[ar]it 4', qw[ barit bait brit gait grit ]);

match( 't.*ough', qw[ tough though trough through thorough ]);

match( 'g.*it', qw[ gait git grapefruit grassquit grit guitguit ]);

match( 'show.*ess', qw[ showeriness showerless showiness showless ]);

match( 'm[eant]+', qw[ ma mae man mana manatee mane manent manna mannan mant
    manta mat mate matta matte me mean meant meat meet meeten men met meta
    metate mete ]);

match( 'v.*meter', qw[ vacuometer vaginometer vaporimeter variometer velocimeter
    velometer ventometer vertimeter viameter viatometer vibrometer vinometer
    viscometer viscosimeter visuometer voltaelectrometer voltameter voltammeter
    voltmeter volumenometer volumeter volumometer votometer ]);

match( 's.*at 1', qw[ sat sweat sailbat ]);

match( 's.*at 2', qw[ sabbat sailboat salariat salat saltcat saltfat sandheat
    sat sauceboat savssat scapegoat scat sceat scelerat schochat scrat
    scratchcat seat secretariat seraskierat shat sheat shellycoat sheriat shoat
    shopocrat shortcoat shortschat shovegroat showboat siderostat skat skellat
    slat slavocrat slipcoat smoothcoat snobocrat snobscat sociocrat somewhat
    spat speedboat splat sprat sproat spyboat squat standpat stanechat
    starthroat steamboat stoat stoneboat stonechat stratocrat strikeboat subplat
    suclat superfat superheat supplicat surat surcoat surfboat swat sweat
    sweetmeat ]);

match( 'pro.*', qw[ proamendment proappropriation proapproval procompromise
    procrastinating procrastinatingly proctosigmoidectomy procuratorate
    prodproof proepiscopist profitproof promiseproof pronational pronationalism
    pronationalist pronationalistic proofroom prophilosophical prophototropic
    prophototropism proreciprocation prostatomyomectomy proterothesis
    proterotype protophilosophic protoproteose protoprotestant ]);

match( 'a.*(al|ic)', qw[ aal abactinal abasic abaxial abbatial abdal
    abdominocystic abdominothoracic abdominovesical aberrational abidal
    abietinic abiotic abiotrophic ablastemic ablatival abnerval aboral
    aboriginal abortional absinthismic absolutistic absorptiometric
    abstractional abterminal abuttal abyssal abyssopelagic academial academic
    academical acanonical acapnial acatalectic acatastatic acaudal accessional
    accidental accipitral acclinal accompanimental accretal accultural
    accusatival ]);

match( 'gh.*en[dt]', qw[ gabblement gangrenescent garment garnisheement
    garnishment gayment gazement gent gerent gigglement glabrescent glaucescent
    glent godparent godsend government gracilescent gradient grandiloquent
    grandparent graveolent gripment groupment grudgment guillotinement
    habiliment hangment haplocaulescent harassment hardiment harrowment
    hatchment haurient haustement havent headrent hederigerent hend hent
    heptavalent herbescent hereditament hexavalent hinderment hirrient horrent
    horrescent huddlement hustlement hutment hyalescent hyperconfident
    hyperexcitement hyperextend hypertranscendent ]);

match( 't.*(at|en)', qw[ tachygen taen taheen taimen taken talipat tannogen
    tanquen tapen tappen tarten tasten tat tauten tearcat tearthroat teat
    technocrat teen tegmen tegumen tekken ten tentamen termen thalassocrat
    thallogen that theat then theocrat thereat therebetween thermogen thermostat
    thestreen thicken thiocyanogen thiophen thirteen thissen thornen thoughten
    thrawneen threaden threat threaten thriven throat throdden thrombogen thysen
    ticken tien tighten tipcat titien tittlebat toadeat toat token tokopat
    tomcat tooken topcoat tormen toughen towboat traheen traneen transwritten
    trawlboat treat treen trichogen trichromat troat trodden trudgen trusten
    truvat trypsinogen tryptogen tubicen tugboat tungsten turbitteen tureen
    turfen turken turncoat twat tween twiggen twitten tyken ]);

match( '[aeinost]+', qw[ a aa ae aenean aeon aeonian aeonist aes ai ainoi aint
    aion ait aitesis aition an ana anan anana ananas anastasis anastate
    anatase anatine anenst anent anes anesis ani aniente anion anis anisate
    anise anisette anisoin ann anna annat annates annatto annet annite
    annona annotate annotation annotine anoa anoesia anoesis anoine anoint
    anon anostosis anotia anotta anotto ansa ansate ansation ant anta ante
    antenati antenna antennae antennate antenoon antes anti antiae antinion
    antinoise antisine antistate antistatist antistes as asana ase asiento
    asinine asitia asonant asonia ass assai assassin assassinate
    assassination assassinist assate assation asse assent assentation
    assentient assess assessee assession asset assets assi assientist
    assiento assis assise assist assistant assonant assonate ast asta
    astasia astatine asteatosis astint astite at ate ates atis atone
    atoneness atonia atta attain attaint attent attention attest attestant
    attestation e ea ean ease easiest easiness east eat eaten eats en
    enaena enantiosis enate enation enostosis ens ensaint ensate ense
    enseat ensete enstate enstatite entasia entasis entente entia entone
    eoan eon eosate eosin eosinate es esne ess essentia essoin essoinee
    essonite estate eta etesian etna i iao ie in inane inanition
    inattention inesite inion initiant initiate initiation initis inn
    innate innateness inness innest innet inone inosin inosite insane
    insaneness insanitation insatiate insatiateness insea insee insensate
    insensateness insense insentient inset insist insistent instant
    instantness instate intensate intensation intense intenseness intension
    intent intention intentness intestate intestation intestine
    intestineness intine into intonate intonation intone io ion ionone iota
    is isatate isatin iso isoionone isoseist isostasist isotonia issei
    issite ist it its n na naa nae naiant nain naio nais naissant nan nana
    nane nanes nant naos nasi nasion nasitis nasonite nast nastiness nat
    natant natation nates nation nattiness ne nea neat neaten neatness nee
    neese neet nei neist nenta neo neon neonate neossin neoteinia neotenia
    nese nesiote ness nest net nete neti ni niata nine nineteen ninon niota
    nisei nisnas nisse nit nito niton no noa noint noise noisette noisiness
    non nonane nonassent nonassentation nonattention nonattestation none
    nonene nonent nones nonet nonintent nonintention nonion nonnant nonnat
    nonostentation nonsane nonsense nonsentient nonsine nonsonant nontan
    nontannin nontenant noon noose nose nosean noseanite nosine not notan
    notate notation note notion notionate notionist notitia o oasean oases
    oasis oast oat oaten oe oenin oes oii oint oisin on ona onanist one
    oneness onion onionet ons onset onto oons oont os ose osone osse ossein
    ostein osteitis ostension ostent ostentate ostentation osteosis ostiate
    ostitis ostosis otate otiant otiose otioseness otitis otosis otosteon
    otto s sa saa sai sain saint saintess san sanai sane saneness sanies
    sanitate sanitation sanitationist sanitist sannaite sans sansei sansi
    sant santene santon santonin sao sasa sasan sasani sasin sasine sat
    satan satanist sate sateen satiate satiation satient satin satine
    satinette satinite se sea season seat see seen seenie seesee seine
    seise seit sen senaite senate senna sennet sennit sennite sensa sensate
    sensation sensationist sense sension sensist senso sent sentient
    sentition sess session sessions sestet sesti sestina sestine set seta
    setae setness seton setose sett settaine settee si sie sienna siesta
    sin sina sinaite sine sinnen sinnet sinsion sion sis sise sisi siss
    sissiness sissoo sist sit sitao site sitient sitio sittee sitten
    sittine snaste snee sneest snite snoose snoot snootiness snot
    snottiness so soe soiesette son sonant sonantina sonata sonatina
    sonation sonnet sonnetist sons soon soot sootiness soso soss sot sotie
    sotnia sots st staia stain staio stane stanine stannane stannate
    stannite stanno stases stasis statant state station statist stean
    steatin steatite steatosis steen stein sten stenion steno stenosis
    stent stenton stet stine stint stion stite stoa stoat stone stonen
    stoniness stoon stoot stoss stosston stot t ta taa tae taen taenia
    taenian taeniasis taeniate taenite taennin tai tain taint taise tait
    tan tana tanaist tanan tane tania tanist tannase tannate tannin tanoa
    tanti tao taotai tass tasse tasset tassie tassoo taste tasten tastiness
    tat tate tatie tatta tattoo tattooist te tea tean tease teasiness teat
    tee teen teenet teens teest teet teetan ten tenai tenant tenent tenet
    tenio tennantite tenne tennis tenon tenonitis tenonostosis tenontitis
    tenositis tenostosis tense tenseness tension tenson tent tentation
    tention teosinte test testa testata testate testation teste testee
    testes testiness testis teston testone testoon tetanine tete ti tiao
    tie tien tin tine tinea tinean tineine tininess tinnet tinniness tinosa
    tinstone tint tinta tintie tintiness tintist tisane tit titanate
    titania titanite titano tite titi titian titien tittie to toa toast
    toastee toastiness toat toatoa toe toetoe toi toise toit ton tonant
    tonation tone tonite tontine too toon toot toss tost toston tot
    totanine tote totient toto tsantsa tsetse tsia tsine tst ]);

match( '[pg].*(ess|ous)', qw[ 
    gaddishness gainfulness gainless gainlessness gainliness gaiterless
    galactophagous galactophorous galactophygous gallantness galliardness
    gallicolous galliferous gallinaceous gallingness gallivorous galloptious
    gallous gallowsness galumptious gamblesomeness gameless gameness gamesomeness
    gamestress gametogenous gaminess gamopetalous gamophyllous gamosepalous
    ganderess ganglionless gangrenous ganocephalous garbless gardenless garishness
    garlandless garmentless garnetiferous garrulous garrulously garrulousness
    garterless gaseous gaseousness gashliness gashouse gasless gasolineless
    gaspiness gassiness gasteromycetous gastightness gastrilegous gastriloquous
    gastrocentrous gastrolatrous gastropodous gatehouse gateless gaucheness
    gaudiness gaudless gaumless gauntness gauziness gawkiness gawkishness gayness
    gazeless geadephagous gearless geitonogamous gelatigenous gelatiniferous
    gelatinigerous gelatinous gelatinously gelatinousness gelidness geminiflorous
    geminous gemless gemmaceous gemmeous gemmiferous gemmiferousness gemminess
    gemmiparous gemmiparously gemmuliferous genderless generableness generalness
    generativeness genericalness generous generously generousness genetous
    genialness genteelness gentianaceous gentilesse gentilitious gentleheartedness
    gentlemanlikeness gentlemanliness gentleness gentlewomanliness genuflexuous
    genuineness geodiferous geogenous geophagous geophilous geraniaceous
    geratologous germaneness germanious germanous germigenous germless gerontogeous
    gesneraceous gesneriaceous gessamine gesso gesticulacious gesticularious
    gestureless ghastliness ghostess ghostless ghostliness ghoulishness giantess
    gibbous gibbously gibbousness giddiness giftedness giftless giganticness
    gigantostracous gigartinaceous gigmaness gimcrackiness gingerliness gingerness
    gingerous ginhouse ginkgoaceous girderless girliness girlishness givenness
    glabellous glabrous glacioaqueous gladfulness gladless gladness gladsomeness
    glaiketness glaireous glairiness glamorous glamorously glandaceous glandarious
    glanderous glandiferous glandless glanduliferous glanduligerous glandulous
    glandulousness glareless glareous glariness glaringness glasshouse glassiness
    glassless glaucomatous glauconiferous glaucophyllous glaucous glaucously
    glaziness gleaminess gleamless glebeless glebous gleefulness gleesomeness
    glegness glessite glibness glideless glideness glimmerous gliomatous
    globiferous globoseness globous globously globousness globulariaceous
    globularness globuliferous globulous globulousness glochideous gloominess
    gloomless glorious gloriously gloriousness gloryless glossiness glossless
    glossophorous gloveless gloveress glueyness gluishness glumaceous glumiferous
    glumness glumpiness glutenous glutinous glutinously glutinousness gluttoness
    gluttonous gluttonously gluttonousness glycogenous gnarliness gnathophorous
    gnathopodous gnathostomatous gnathostomous gnetaceous goalless goatherdess
    goatishness goddess goddesshood goddessship godless godlessly godlessness
    godlikeness godliness goitrous goldenness goldless goneness gonidiferous
    gonidiogenous gonimous goniotropous gonophorous gonystylaceous goodeniaceous
    goodheartedness goodishness goodliness goodness goodyness goofiness goosehouse
    goosishness gordiaceous gorgeous gorgeously gorgeousness gorgonaceous
    gorgoniaceous goriness gossaniferous gossipiness gourdiness goustrous gousty
    goutiness governableness governess governessdom governesshood governessy
    gowkedness gracefulness graceless gracelessly gracelessness gracileness
    gracious graciously graciousness gradualness grainedness graininess grainless
    grainsickness graminaceous gramineous gramineousness graminicolous
    graminiferous graminifolious graminivorous graminous grammarless
    grammaticalness grandfatherless grandiloquous grandisonous grandmotherliness
    grandness granitiferous granivorous granuliferous granulomatous granulous
    grapeless graphicalness graphicness graspingness graspless grasshouse
    grassiness grassless gratefulness grateless gratuitous gratuitously
    gratuitousness graveless gravelliness graveness gravidness grayness greaseless
    greaselessness greaseproofness greasiness greatheartedness greatness greediness
    greedless greenhouse greenishness greenless greenness greensickness
    greetingless gregarinous gregarious gregariously gregariousness gressorial
    gressorious greyness griefless grieflessness grievous grievously grievousness
    griminess grimliness grimmiaceous grimness gripless grippiness grippingness
    grippleness griseous grisliness gristliness gritless grittiness groceress
    grogginess grooveless grooviness grossness grossulaceous grossulariaceous
    grossularious grotesqueness grouchiness groundedness groundless groundlessly
    groundlessness groundliness groupageness grouse grouseberry grouseless grouser
    grouseward grousewards grousy groveless growingupness growthiness growthless
    grubbiness grubless grudgeless grudgingness gruesomeness gruffiness gruffness
    grumness grumous grumousness grumpiness guaniferous guardedness guardhouse
    guardianess guardianless guardless guerdonless guess guessable guesser guessing
    guessingly guesswork guessworker guesthouse guestless guideless guideress
    guilefulness guileless guilelessly guilelessness guiltiness guiltless
    guiltlessly guiltlessness gullishness gumless gummatous gummiferous gumminess
    gummous gumptionless gumptious gunhouse gunless gunneress gunpowderous
    gushiness gushingness gustativeness gustfulness gustiness gustless gutless
    guttiferous guttiness gutturalness gymnanthous gymnetrous gymnocarpous
    gymnoceratous gymnodiniaceous gymnogenous gymnogynous gymnolaematous
    gymnosporous gymnostomous gymnotokous gynandromorphous gynandrosporous
    gynandrous gynantherous gynecomorphous gynecophorous gynobaseous gynodioecious
    gynodioeciously gynomonecious gynomonoeciously gypseous gypsiferous
    gypsophilous gypsous gyrencephalous gyrous ]);


match( '[pg].*(ess|ous)', qw[ 
    pabulous pachycarpous pachycephalous pachycladous pachydactylous
    pachydermatous pachydermatously pachydermous pachyglossous
    pachyhaemous pachyhematous pachynathous pachyotous pachyphyllous
    pachypodous pachypterous pachyrhynchous pachysomous
    pachystichous pachytrichous packhouse packless packness
    pageless painfulness painless painlessly painlessness
    painstakingness paintableness paintedness paintiness
    paintingness paintless paintress pairedness palaceous
    palaeodictyopterous palaeognathous palatableness palatefulness
    palateless palatialness palatognathous palaverous paleaceous
    paledness paleness palladiferous palladious palladous
    pallidiflorous pallidness palliness pallioessexite palmaceous
    palmellaceous palmicolous palmiferous palmivorous palouser
    palpableness palpiferous palpigerous palpless paltriness
    paludicolous paludiferous paludinous paludous pamperedness
    pamphagous pamprodactylous pancreatogenous pandanaceous
    panderess panderous paneless pangamous pangamously pangless
    panglessly panhygrous panichthyophagous panivorous pantaletless
    pantheress pantophagous pantophobous pantopterous pantostomatous
    papaveraceous papaverous papayaceous paperiness papess
    papilionaceous papilliferous papillomatous papillous papless
    papolatrous pappiferous papuliferous papuloerythematous
    papulosquamous papulous papyraceous papyritious parabolicness
    parachromatophorous parachromoparous parachromophorous
    paraconscious paradeless paradoxicalness paragnathous
    paragonless parallelinervous parallelless parallelodromous
    parallepipedous paramorphous paramountness parapetalous
    parapetless paraphysiferous parasiticalness paratuberculous
    parchedness pardonableness pardonless parenchymatous
    parenchymatously parenchymous parentheticalness parentless
    parhomologous parliamentariness parlous parlously parlousness
    parmeliaceous parnassiaceous parochialness paroecious
    paroeciously paroeciousness paroicous paronymous parous
    parousia parousiamania parsimonious parsimoniously
    parsimoniousness parsoness partedness parthenocarpous
    parthenogenous parthenoparous partialness participatress
    particularness partless partnerless partyless parviflorous
    parvifolious pascuous passableness passibleness passifloraceous
    passingness passionateness passionfulness passionless
    passionlessly passionlessness passiveness passless passportless
    pastedness pastiness pastness pastoralness pastoress
    pastorless pastureless patchiness patchless patheticalness
    patheticness pathless pathlessness pathogenous pathophorous
    patientless patientness patinous patness patriarchess
    patriotess patristicalness patroclinous patroness patronessship
    patronless patternless patulous patulously patulousness
    pauciflorous paucifolious paunchiness pauperess paurometabolous
    pauropodous pauseless pauselessly pawkiness pawnbrokeress
    paxilliferous payableness paymistress peaceableness
    peacefulness peaceless peacelessness peachiness peacockishness
    peakedness peakiness peakishness peakless pearliness peartness
    peasantess peathouse pebrinous peccantness peckiness
    peckishness pectinaceous pectiniferous pectinous pectoriloquous
    pectous peculiarness pecunious pedaliaceous pedantess
    pedanticalness pedanticness peddleress pedetentous pediculous
    pediferous pedigerous pedigreeless pedimanous pedipalpous
    peeledness peelhouse peeress peerless peerlessly peerlessness
    peevedness peevishness pegless pelecypodous pellagrous
    pellucidness peltiferous peltifolious peltigerous peltless
    pemphigous penaeaceous penanceless penceless pendulous
    pendulously pendulousness penetrableness penetratingness
    penetrativeness pennaceous pennatulaceous penniferous
    pennigerous penniless pennilessly pennilessness pennycress
    pensefulness pensileness pensionless pensiveness pentacoccous
    pentadelphous pentagynous pentahedrous pentamerous pentandrous
    pentapetalous pentaphylacaceous pentaphyllous pentapterous
    pentasepalous pentaspermous pentastichous pentastomous
    penthouse penthouselike penumbrous penurious penuriously
    penuriousness peopleless pepperiness peppiness pepsiniferous
    pepsinogenous peptogenous perceivableness perceivedness
    perceivingness perceptibleness perceptiveness percomorphous
    percussiveness percutaneous percutaneously perdurableness
    peremptoriness perfectiveness perfectness perfervidness
    perfidious perfidiously perfidiousness perfumeless perfumeress
    perfunctoriness perfunctorious perfunctoriously pergameneous
    pergamentaceous periacinous perichylous peridiniaceous
    perigynous periligamentous perilless perilous perilously
    perilousness perimeterless perimorphous periodicalness
    periosteous peripetalous periproctous peripterous perisarcous
    perishableness perishless perisinuous perisporiaceous
    perissodactylous peristeromorphous peristeropodous peristrumous
    peritomous peritrematous peritrichous peritrichously
    peritropous perivenous perjuredness perjuress perjurious
    perjuriously perjuriousness perjurous perkiness perlaceous
    perligenous permanentness permeableness permissibleness
    permissiveness permutableness pernicious perniciously
    perniciousness pernicketiness peromelous peronosporaceous
    peropodous perpetratress perpetualness perplexedness
    perridiculous persecutiveness persecutress persistiveness
    personableness personalness perspectiveless perspicacious
    perspicaciously perspicaciousness perspicuous perspicuously
    perspicuousness persuadableness persuadedness persuasibleness
    persuasiveness pertinacious pertinaciously pertinaciousness
    pertinentness pertness perturbatious perturbatress perturbedness
    perukeless pervadingness pervasiveness perverseness
    pervertedness pervicacious pervicaciously pervicaciousness
    pervious perviously perviousness peskiness pess pessary
    pessimal pessimism pessimist pessimistic pessimistically
    pessimize pessimum pessomancy pessoner pessular pessulus
    pesterous pesthouse pestiferous pestiferously pestiferousness
    pestifugous pestilentialness petaliferous petalless
    petalocerous petaloideous petalous petiteness petricolous
    petroleous petroliferous petrophilous petrosiliceous
    petrosilicious petrosquamous petrous pettedness petticoatless
    pettiness pewless pezizaceous phaenantherous phaenogamous
    phaenozygous phaeochrous phaeophyceous phaeosporous phagedenous
    phallaceous phanerocephalous phanerogamous phaneromerous
    pharisaicalness pharyngognathous phascaceous phaseless
    phaseolous phasogeneous phenicious phenozygous philodestructiveness
    philogenitiveness philogynous philoprogenitiveness
    philorchidaceous philosopheress philosophicalness
    philosophicoreligious philoxygenous philydraceous
    phlegmaticalness phlegmaticness phlegmatous phlegmless
    phlegmonous phloeophagous phlogogenous phocaceous phocomelous
    phoenicaceous phoenicopterous phoenicurous phonophorous
    phosphoreous phosphoriferous phosphorous photerythrous
    photogenous photographeress photographess photoimpression
    photophilous photophobous photophygous photoprocess
    photoregression photosensitiveness phragmocyttarous phraseless
    phrasiness phreneticness phrymaceous phthirophagous
    phycochromaceous phycochromophyceous phycomycetous
    phylactolaematous phyllocladous phyllodineous phyllodinous
    phyllogenous phylloideous phyllophagous phyllophorous
    phyllopodous phyllospondylous phyllostomatous phyllostomous
    phyllous physicalness physicianess physicianless physiolatrous
    physocarpous physoclistous physonectous physophorous
    physostomatous physostomous phytiferous phytivorous phytogenous
    phytolaccaceous phytolatrous phytophagous phytophilous
    piacularness piazzaless picayunishness piceoferruginous
    piceotestaceous piceous pickableness pickedness picksomeness
    pickthankness pictorialness picturableness pictureless
    picturesqueness piebaldness pieceless piedness piehouse
    pieless pierceless piercingness pierless piggishness
    pigheadedness pigless pignoratitious pileous pilgrimess
    piliferous piligerous pilledness pillowless pilosebaceous
    pilothouse pilotless pilous pilulous pimpliness pimplous
    pinaceous pinchedness pinguedinous pinguiculaceous pinguiferous
    pinguitudinous pinheadedness pinicolous piniferous pinionless
    pinivorous pinkiness pinkishness pinkness pinless pinniferous
    pinnigerous pious piously piousness pipeless piperaceous
    piperitious pipingness pipless piquantness piratess
    piscatorious piscicolous pisciferous piscivorous pistillaceous
    pistilliferous pistilligerous pitchiness piteous piteously
    piteousness pithiness pithless pithlessly pitiableness
    pitiedness pitifulness pitiless pitilessly pitilessness
    pitless pittosporaceous pituitous pituitousness placableness
    placeless placelessly placentiferous placentigerous placidness
    plackless placodermatous plagiostomatous plagiostomous
    plagiotropous plagueless plaguesomeness plainness plaintiveness
    plaintless plaitless planeness planetless planfulness
    plangorous planifolious planipetalous planiphyllous plankless
    planless planlessly planlessness plantaginaceous plantagineous
    plantivorous plantless plasmatoparous plasmodiocarpous
    plasmophagous plasteriness platanaceous plateless platformless
    platiniferous platinous platitudinous platitudinously
    platitudinousness platurous platybrachycephalous platycarpous
    platycelous platycephalous platydactylous platydolichocephalous
    platypetalous platyphyllous platypodous platypygous
    platyrhynchous platystomous plausibleness playeress playfulness
    playhouse playless playsomeness playwrightess pleadableness
    pleadingness pleasableness pleasantness pleasedness
    pleasingness pleasurableness pleasureless pleasurelessly
    pleasurous pleatless plebeianness plecopterous plectognathous
    plectopterous plectospondylous pledgeless pleiomerous
    pleiophyllous plenariness plenitudinous plenteous plenteously
    plenteousness plentifulness pleochroous pleomorphous
    plesiomorphous plessigraph plessimeter plessimetric plessimetry
    plessor plethorous pleurenchymatous pleurocapsaceous
    pleurocarpous pleurococcaceous pleurodirous pleurodiscous
    pleurogenous pleurotropous pliableness pliantness plicateness
    pliciferous plinthless ploddingness plotless plotlessness
    plousiocracy pluckedness pluckiness pluckless plucklessness
    plugless plumaceous plumbaginaceous plumbaginous plumbeous
    plumbiferous plumbless plumbness plumbous plumeless plumeous
    plumigerous pluminess plumless plummetless plumoseness
    plumous plumpness plumulaceous plunderess plunderless
    plunderous pluperfectness pluriflorous pluriparous pluripetalous
    plurisporous plurivorous plushiness pluvious pneumatogenous
    pneumatophorous pneumococcous pneumonophorous poaceous
    poachiness pocketableness pocketless pockhouse pockiness
    podagrous podginess podilegous podocarpous podocephalous
    podophthalmatous podophthalmous podophyllous podosomatous
    podostemaceous podostemonaceous podostomatous poecilocyttarous
    poecilogonous poecilopodous poephagous poesiless poetastress
    poetess poeticalness poeticness poetless poetress poetryless
    pointedness pointfulness pointless pointlessly pointlessness
    poisonless poisonlessness poisonous poisonously poisonousness
    pokerishness pokiness poleless polemoniaceous policeless
    polishedness politeness politesse politicious polleniferous
    pollenigerous pollenivorous pollenless polliniferous
    pollinigerous pollinivorous pollutedness polyacoustic
    polyacoustics polyadelphous polyadenous polyandrious
    polyandrous polyanthous polyarthrous polybunous polycarpous
    polycephalous polychaetous polychotomous polychromous
    polychronious polycladous polycoccous polycotyledonous
    polycotylous polydactylous polydermous polydomous polyflorous
    polygalaceous polygamodioecious polygamous polygamously
    polygenous polyglottous polygonaceous polygonous polygynious
    polygynous polyhedrous polylepidous polymastigous polymerous
    polymorphous polymyodous polyoecious polyoeciously
    polyoeciousness polyoicous polyommatous polyonomous polyonymous
    polyparous polypetalous polyphagous polyphemous polyphonous
    polyphyllous polypiferous polypigerous polyplacophorous
    polypodiaceous polypodous polyporaceous polyporous polypous
    polypseudonymous polyrhizous polysarcous polysemous
    polysensuous polysensuousness polysepalous polysidedness
    polysiphonous polysomatous polysomous polyspermatous
    polyspermous polyspondylous polysporous polystachyous
    polystemonous polystichous polystomatous polystylous
    polythalamous polytocous polytokous polytomous polytrichaceous
    polytrichous polytrochous pomaceous pomiferous pomivorous
    pompelmous pompholygous pompless pompous pompously pompousness
    ponderableness ponderous ponderously ponderousness
    pontederiaceous pontificious poorhouse poorliness poorness
    popeless popess popishness popularness populationless
    populous populously populousness porcelainous porcelaneous
    porcelanous porchless porencephalous poriferous poriness
    porkless porogamous porophyllous poroseness porous porously
    porousness porphyraceous porphyrous porraceous porriginous
    portableness portalless portentous portentously portentousness
    porteous porteress porterhouse porthouse portionless portless
    portliness portress portulacaceous porulous positionless
    positiveness possess possessable possessed possessedly
    possessedness possessing possessingly possessingness
    possession possessional possessionalism possessionalist
    possessionary possessionate possessioned possessioner
    possessionist possessionless possessionlessness possessival
    possessive possessively possessiveness possessor possessoress
    possessorial possessoriness possessorship possessory
    possibleness postcartilaginous postdepressive posterishness
    posthouse posthumous posthumously posthumousness posticous
    postimpressionism postimpressionist postimpressionistic
    postless postliminious postliminous postmistress postmyxedematous
    postosseous postspinous poststertorous postvenous potableness
    potamogetonaceous potamophilous potassiferous potentialness
    potentness pothouse pothousey potteress pouchless poulteress
    poultryless poundless pouser poussette powderiness powerfulness
    powerhouse powerless powerlessly powerlessness practicableness
    practicalness practicedness praelectress pragmaticalness
    praisableness praisefulness praiseless praisworthiness
    prankfulness prankishness pranksomeness prasinous prasophagous
    pratincolous prayerfulness prayerless prayerlessly
    prayerlessness preaccess preaccessible preacheress preacherless
    preachiness preacidness preacuteness preaddress preaggression
    preaggressive preambitious prebarbarous prebless preblessing
    precancerous precarcinomatous precarious precariously
    precariousness precartilaginous precautious precautiously
    precautiousness precedentless precentress preceptress precess
    precession precessional precious preciously preciousness
    precipitantness precipitous precipitously precipitousness
    preciseness precocious precociously precociousness
    precompleteness precompress preconcertedness preconcession
    preconcessive preconfess preconfession precongressional
    preconscious preconsciously preconsciousness precontemporaneous
    precorrectness precoruptness predaceous predaceousness
    predarkness predatoriness predecession predecessor
    predecessorship predepression predesirous predicableness
    predictiveness predisadvantageous predisadvantageously
    predisastrous predisposedness predistress prefamous
    preferableness preferredness preferrous prefigurativeness
    preforgiveness prefrankness pregenerous pregenerously
    pregladness pregnantness pregracious preguess preguiltiness
    preharmonious preharmoniousness preharshness prehazardous
    prehensiveness preimpress preimpression preimpressive
    preindebtedness preinjurious preintercession prejudiceless
    prejudicialness prejudicious prejudiciously prelatess
    prelaticalness prelawfulness prelectress preliteralness
    preludious preludiously preluxurious premadness prematureness
    premeditatedness premieress premious premorbidness
    prenecessitate preobvious preobviously preobviousness
    preoccupiedness preodorous preoffensiveness preoppress
    preoppression preoppressor preparedness prepious preponderous
    preponderously prepossess prepossessed prepossessing
    prepossessingly prepossessingness prepossession prepossessionary
    prepossessor preposterous preposterously preposterousness
    preprofess preprofessional prereadiness prereligious
    prerighteous prerighteously prerighteousness presbyacousia
    presbycousis presbyteress prescriptiveness presenceless
    presentableness presentialness presentiveness presentness
    preserveress presession presidentess prespinous prespontaneous
    prespontaneously press pressable pressboard pressdom pressel
    presser pressfat pressful pressgang pressible pressing
    pressingly pressingness pression pressive pressman pressmanship
    pressmark pressor presspack pressroom pressurage pressural
    pressure pressureless pressureproof pressurize pressurizer
    presswoman presswork pressworker prestigious prestigiously
    prestigiousness prestress prestudious prestudiously
    prestudiousness presuccess presuccessful presuccessfully
    presumptious presumptiously presumptuous presumptuously
    presumptuousness presuperfluous presuperfluously
    presuppositionless presuppress presuppression presuspicious
    presuspiciously presuspiciousness pretardiness pretendingness
    pretenseless pretensionless pretensiveness pretentious
    pretentiously pretentiousness preteressential pretergress
    pretergression preteriteness preteritness preternaturalness
    preternotorious pretextuous prethoughtfulness pretimeliness
    prettiness pretuberculous prevailingness prevalentness
    preventiveness previctorious previous previously previousness
    prewillingness prewireless prewitness preworldliness
    preworthiness priceless pricelessness prickless prickliness
    pricklouse pridefulness prideless pridelessly priestess
    priestless priestliness priggess priggishness primariness
    primeness primevous primigenious primigenous primiparous
    primness primogenous primulaceous princeless princeliness
    princess princessdom princesse princesslike princessly
    principalness printableness printless prionodesmaceous
    prioress prisonous prissiness privateness privativeness
    priviness proaggressionist proangiospermous proassessment
    probableness probituminous proboscideous proboscidiferous
    probusiness procacious procaciously procellous process
    processal procession processional processionalist processionally
    processionary processioner processionist processionize
    processionwise processive processor processual proclivitous
    proclivous proclivousness procoelous proconcession proconfession
    proconfessionist procreativeness procreatress procuress
    prodigious prodigiously prodigiousness proditorious
    proditoriously prodromous produceableness producibleness
    productiveness productress profanableness profaneness
    profectitious profess professable professed professedly
    profession professional professionalism professionalist
    professionality professionalization professionalize
    professionally professionist professionize professionless
    professive professively professor professorate professordom
    professoress professorial professorialism professorially
    professoriate professorlike professorling professorship
    professory proficientness proficuous proficuously profitableness
    profitless profitlessly profitlessness profligateness
    profluvious profoundness profuseness profusiveness
    progenitiveness progenitress prognathous progress progresser
    progression progressional progressionally progressionary
    progressionism progressionist progressism progressist
    progressive progressively progressiveness progressivism
    progressivist progressivity progressor progymnospermous
    prohibitiveness projectress prolateness prolegomenous
    proletarianness proliferous proliferously prolificalness
    prolificness proligerous prolixness prolocutress prolongableness
    promenaderess promiscuous promiscuously promiscuousness
    promiseless promisingness promonarchicalness promotiveness
    promotress promptness promptress proneness pronounceness
    proofless prooflessly proofness propagableness propagatress
    propenseness properness propertyless propessimism propessimist
    prophetess propheticalness prophetless propinquous propitious
    propitiously propitiousness propless proportionableness
    proportionateness proportionless proprietous proprietress
    prosaicalness prosaicness proscriptiveness prosenchymatous
    prosiness prosogyrous prospectiveness prospectless
    prospectusless prosperous prosperously prosperousness
    protandrous protandrously protanomalous proteaceous
    protectingness protectiveness protectorless protectress
    proteidogenous proteinaceous proteinous protelytropterous
    protemporaneous proteogenous proterandrous proterandrousness
    proteranthous proteroglyphous proterogynous protobasidiomycetous
    protococcaceous protocoleopterous protogonous protogynous
    protohemipterous protohymenopterous protopterous protoreligious
    protorthopterous protosiphonaceous protractedness protrusiveness
    protuberantness protuberous proudness proustite provableness
    providentness provisionalness provisioneress provisionless
    provocativeness provokingness provostess prowess prowessed
    prowessful proximateness prudentialness prudishness pruinous
    prunableness pruniferous pruriginous pruriousness pryingness
    psalmless psaltress psammogenous psammophilous psammous
    pseudaposporous pseudepigraphous pseudobulbous pseudocarpous
    pseudocartilaginous pseudocentrous pseudochylous pseudocorneous
    pseudoerysipelatous pseudofamous pseudofoliaceous pseudogaseous
    pseudogenerous pseudogynous pseudomembranous pseudomiraculous
    pseudomonocotyledonous pseudomorphous pseudoneuropterous
    pseudonymous pseudonymously pseudonymousness pseudoparenchymatous
    pseudopious pseudoprofessional pseudoprofessorial
    pseudoprosperous pseudoreligious pseudosacrilegious
    pseudosessile pseudospermous pseudostomatous pseudostomous
    pseudotetramerous pseudotrimerous pseudotuberculous
    pseudoviscous psilotaceous psittaceous psittaceously psorous
    psychosarcous pterideous pteridophytous pteridospermous
    pterocarpous pterodactylous pteropegous pteropodous
    pterospermous pterygospinous pterygotous puberulous pubigerous
    publicheartedness publicness publisheress pucciniaceous
    puckishness puddinghouse pudendous pudginess puerileness
    puerperous puffiness pugginess pugnacious pugnaciously
    pugnaciousness puissantness pukishness pulchritudinous
    pulicarious pulicous pulleyless pulmocutaneous pulmoniferous
    pulpaceous pulpiness pulpitless pulpless pulpous pulpousness
    pulseless pulselessly pulselessness pultaceous pulveraceous
    pulvereous pulverous pumiceous pumpless punchless punctilious
    punctiliously punctiliousness punctualness punctureless
    punicaceous puniceous puniness punishableness punitiveness
    punless punstress pupiferous pupigenous pupigerous pupilless
    pupiparous pupivorous purblindness pureness puritanicalness
    purlhouse puromucous purpleness purplishness purportless
    purposefulness purposeless purposelessly purposelessness
    purposiveness purpuraceous purpureous purpuriferous
    purpurigenous purpuriparous purpurogenous purseless pursiness
    purveyoress pushfulness pushingness pusillanimous pusillanimously
    pusillanimousness pustulatous pustulous putaminous putidness
    putredinous putrefactiveness putridness putrilaginous
    putrilaginously puzzledness puzzleheadedness puzzlepatedness
    puzzlingness pycnomorphous pygopodous pygostylous pyogenous
    pyramidicalness pyrenematous pyrenocarpous pyrenodeous
    pyrenomycetous pyretogenous pyritaceous pyritiferous pyritous
    pyroarsenious pyrobituminous pyrogenous pyrolaceous
    pyroligneous pyrolignous pyromorphous pyrophanous pyrophilous
    pyrophorous pyrophosphorous pyrrhous pythogenous pythoness
    pythonomorphous ]);

match( '[su].*ess', qw[ 
    sacrilegiousness sacrosanctness saddlesoreness sagaciousness
    sailorless salaciousness sallowness salubriousness
    salutationless sanctimoniousness sanctionless sanguineousness
    saponaceousness satisfactionless satisfactoriness savoriness
    savorless scabrousness scandalousness scholarless scholarliness
    schoolboyishness schoolgirlishness schoolless schoolmasterishness
    scissorlikeness scopeless scopulousness scorchingness
    scoreless scornfulness scouriness scribaciousness scribatiousness
    scrofulousness scrumptiousness scruplesomeness scrupulousness
    scurrilousness scutcheonless seasonableness seasonalness
    seasonless seaworthiness secondariness secondhandedness
    secondness seditiousness sedulousness seldomness semiconsciousness
    semiseriousness semispontaneousness sensationless sensuousness
    sententiousness sequaciousness seriousness sermonless
    serousness sevenfoldness sextoness shadowiness shadowless
    shadowlessness shallowness shoaliness shoalness shockedness
    shockingness shoddiness shoeless shoppishness shoreless
    shorthandedness shortness shortsightedness shotless showeriness
    showerless showiness showless shroudless sightworthiness
    simiousness simultaneousness sinuousness siphonless
    skeletonless slanderousness slipshoddiness slipshodness
    slopeness slopingness sloppiness sloshiness slothfulness
    slouchiness sloughiness slovenliness slowheartedness
    slumberousness smockless smokeless smokelessness smokiness
    smolderingness smoothness smotheriness snobbishness snootiness
    snooziness snoreless snottiness snoutless snowiness snowless
    soapiness soapless soberness sociableness socialness
    societyless socketless sockless socklessness sodaless
    soddenness sodless softheartedness softness sogginess
    soilless solaciousness solderless soldierliness soleless
    solemnness soleness solicitousness solidifiableness solidness
    solitariness solubleness solvableness somberness sombrousness
    somethingness somewhatness songfulness songless songlessness
    sonless sonlikeness sonorousness soothingness soothless
    sootiness sootless sophisticalness soporiferousness soppiness
    sordidness soreheadedness soreness sorriness sorrowfulness
    sorrowless sottishness soulfulness soulless soullessness
    soundheadedness soundingness soundless soundlessness soundness
    soupless sourcefulness sourceless souredness sourishness
    sourness southerliness southernliness southernness southness
    sovereigness sovereignness spaciousness sparrowless
    spasmodicalness speciousness spicousness spinoseness
    spinousness spirituousness splendaciousness splendiferousness
    splotchiness spoilless spokeless spongeless sponginess
    spongiousness spontaneousness spookiness spooneyness
    spooniness spoonless sporadicalness sportfulness sportiness
    sportiveness sportless sportsmanliness spotless spotlessness
    spottedness spottiness spouseless spoutiness spoutless
    spuriousness squamoseness squamousness standoffishness
    stationariness stentoriousness stepmotherless stepmotherliness
    stertoriousness stertorousness stockiness stockingless
    stockishness stockless stodginess stoicalness stokerless
    stolenness stolidness stomachfulness stomachicness stomachless
    stomachlessness stoneless stonelessness stoniness
    stonyheartedness stopless stoplessness stoppableness
    stopperless stormfulness storminess stormless stormlessness
    storyless stourliness stourness stoutheartedness stoutness
    stoveless straightforwardness strenuousness stridulousness
    strongheadedness strongness strumousness stubbornness
    studiousness stupendousness subconsciousness subcutaneousness
    subdeaconess subdolousness subgoverness subordinateness
    subterraneousness successionless succorless succourless
    sudoriferousness sulfureousness sulphureousness sulphurousness
    sumptuousness sunspottedness superciliousness superconsciousness
    superfluousness supergoodness superiorness supernormalness
    superofficiousness supersensuousness supersolemness
    superstitionless superstitiousness supportableness supportless
    supposableness suppositionless supposititiousness
    supraconsciousness surgeoness surgeonless surmountableness
    surreptitiousness suspicionless suspiciousness swollenness
    swordless symbolicalness symptomless synchronousness
    synoeciousness synonymousness uberousness ubiquitousness
    ugsomeness ulcerousness ultroneousness umbraciousness
    umbrageousness umbriferousness unabsolvedness unaccommodatedness
    unaccommodatingness unaccomplishedness unaccountableness
    unaccustomedness unacknowledgedness unadornedness unambiguousness
    unambitiousness unanalogousness unanimousness unanxiousness
    unappointableness unapproachableness unappropriateness
    unapprovableness unassociativeness unauspiciousness
    unauthoritativeness unauthoritiveness unauthorizedness
    unavoidableness unavouchableness unavowableness unbeauteousness
    unbecomingness unbegottenness unbeholdenness unbloodiness
    unbodiliness unboldness unbondableness unboundableness
    unboundedness unboundless unbountifulness unbowingness
    unbrokenness unbrotherliness unburdensomeness unbuxomness
    uncanonicalness uncatholicalness uncautiousness uncensoriousness
    unceremoniousness unchivalrousness unclothedness uncloudedness
    uncoachableness uncoatedness uncoherentness uncollatedness
    uncollectedness uncollectibleness uncoloredness uncolouredness
    uncombinableness uncombiningness uncomeliness uncomfortableness
    uncommandedness uncommendableness uncommensurableness
    uncommercialness uncommodiousness uncommonness uncommunicableness
    uncommunicativeness uncompassionateness uncomplainingness
    uncompleteness uncompliableness uncompoundedness
    uncomprehendingness uncomprehensiveness uncompromisingness
    uncomputableness unconcealableness unconceivableness
    unconcernedness unconcertedness unconciliatedness
    unconcludingness unconclusiveness uncondensableness
    unconditionalness unconditionedness unconduciveness
    unconductiveness unconfidentialness unconfinedness
    unconflictingness unconformableness unconnectedness
    unconquerableness unconscientiousness unconscionableness
    unconsciousness unconsecratedness unconsequentialness
    unconsiderateness unconsideredness unconspicuousness
    unconspiringness unconstantness unconstrainedness
    uncontainableness uncontentedness uncontentingness
    uncontentiousness uncontestableness uncontestedness
    uncontractedness uncontradictableness uncontrollableness
    uncontrolledness uncontrovertableness uncontrovertibleness
    unconversableness unconvertedness unconvincedness
    unconvincingness uncorrectness uncorrigibleness uncorruptedness
    uncorruptibleness uncorruptness uncostliness uncountableness
    uncourteousness uncourtliness uncouthness uncrossableness
    unctionless unctiousness unctuousness uncustomariness
    undangerousness undecorousness undeformedness undemonstrativeness
    underconsciousness undergoverness undesirousness undevoutness
    undiscoverableness undisposedness undivorcedness undocumentedness
    undoingness undoneness undoubtableness undoubtedness
    undoubtfulness undoubtingness uneconomicalness unelaborateness
    unemotionalness unemployableness unenforcedness unequivocalness
    uneuphoniousness unexceptionableness unexceptionalness
    unexorableness unfashionableness unfastidiousness
    unfathomableness unfavorableness unfelicitousness unfondness
    unforbiddenness unforcedness unforcibleness unfordableness
    unforeseeableness unforeseenness unforewarnedness
    unforgettableness unforgivableness unforgiveness unforgivingness
    unforkedness unformalness unfortunateness unfoundedness
    ungenerousness ungeometricalness ungloriousness unglossiness
    ungodliness ungoodliness ungovernableness ungovernedness
    ungraciousness ungroundedness unhallowedness unhandsomeness
    unharmoniousness unhazardousness unhealthsomeness unholiness
    unhomelikeness unhomeliness unhopedness unhopefulness
    unhospitableness unhostileness unhumorousness uniformless
    uniformness unimpassionedness unimprovableness unimprovedness
    uninclosedness unincorporatedness uninfectiousness
    uningeniousness uningenuousness uninjuriousness unintentionalness
    unintoxicatedness unjointedness unjoyfulness unjoyousness
    unjudiciousness unknowableness unknowingness unknownness
    unlaboriousness unlogicalness unlosableness unlovableness
    unloveableness unloveliness unlovingness unmelodiousness
    unmentionableness unmeritoriousness unmethodicalness
    unmoderateness unmodifiableness unmodifiedness unmoralness
    unmortifiedness unmotivatedness unmovableness unmovingness
    unnegotiableness unneighborliness unnobleness unnoticeableness
    unobjectionableness unobligingness unobsequiousness
    unobservantness unobstructedness unobtainableness unobtrusiveness
    unoccupiedness unoffensiveness unofficialness unofficiousness
    unopenness unopportuneness unopposedness unoppressiveness
    unordinariness unordinateness unorganicalness unorganizedness
    unorientalness unoriginalness unoriginatedness unoriginateness
    unoriginativeness unornamentalness unorthodoxness
    unostentatiousness unpardonableness unpardonedness
    unpassionateness unpensionableness unpersonableness
    unphilosophicalness unphoneticness unpiteousness unpoeticalness
    unpolishedness unpoliteness unpopularness unpopulousness
    unpossessedness unpossibleness unpowerfulness unprepossessingness
    unpretentiousness unprocurableness unproduceableness
    unproducedness unproducibleness unproductiveness unprofitableness
    unprofuseness unprogressiveness unprohibitedness unpromisingness
    unproperness unpropitiatedness unpropitiousness
    unproportionableness unproportionateness unproportionedness
    unprosperousness unprotectedness unprovableness unprovedness
    unprovidedness unprovokedness unquestionableness unquestionedness
    unquestioningness unreasonableness unrecognizableness
    unreconcilableness unrecordedness unrecoverableness
    unreformedness unreligiousness unremovableness unrenownedness
    unreportedness unreposefulness unreproachableness
    unreprovableness unreprovedness unresolvedness unresourcefulness
    unresponsibleness unresponsiveness unrevocableness
    unrhetoricalness unrighteousness unromanticalness unroyalness
    unsanctimoniousness unsatisfactoriness unsavoredness
    unsavoriness unschooledness unscornfulness unscrupulousness
    unseasonableness unseaworthiness unsensuousness unseriousness
    unslothfulness unsmoothness unsoberness unsociableness
    unsocialness unsoiledness unsolemness unsolicitousness
    unsolidness unsolvableness unsophisticatedness unsoundableness
    unsoundness unspoilableness unspottedness unstoniness
    unsupportableness unsupportedness unsurmountableness
    unsuspiciousness unsymbolicalness unthoughtfulness
    untolerableness untoothsomeness untouchableness untouchedness
    untowardliness untowardness untroddenness untroubledness
    untroublesomeness untrustworthiness untutoredness ununiformness
    unvirtuousness unvoluntariness unvouchedness unwealsomeness
    unwearisomeness unwelcomeness unwholesomeness unwomanliness
    unwontedness unworkableness unworkedness unworldliness
    unworriedness unworthiness unwoundableness unzealousness
    uprighteousness uproariness uproariousness urinousness
    usuriousness utmostness uxoriousness ]);

