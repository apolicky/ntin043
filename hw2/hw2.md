# Smart home

Modelováno v systému Alloy, model je definovaný v přiloženém souboru.

Má představa o systému chytrého domova je následující. Chtěl bych, aby za mne systém hlídal bezpečnost objektu, ve kterém ho provozuji, a poskytoval mi i možnost ovládat komfortní prvky.

## Návrh systému

Systém může být nasazen k ovládání jedné či více budov najednou. Uživatel, který ho používá, tak může mít přehled jak o svém rodinném domu tak i o stodole za domem.

Budovu vnímáme jako množinu mítností a v zájmu bezpečnosti předpokládáme, že každá budova bude mít alarm na hlášení požáru a utěku plynu.

Každou mítnost by bylo dobré vybavit detektorem kouře a takovými těmi věci na hašení ohně (_sprinkler_). Navíc v místnostech mohou být i jiné senzory - detektor plynu, detektor vyteklé vody, templotní a vlhkostní senzor. Uživatel si do nich také může nainstalovat své chytré prvky, které se dají skrze systém ovládat.

## Bezpečnostní prvky

Systém přichází s nastavenymi scénářei pro určitá bezpečnostní rizika.

### Požár

Při detekci kouře se spustí požární alarm, zapnou se všechny sprinklery v místnosti a upozorní se uživatelé systému.

### Únik plynu

Při detekci plynu se spustí alarm na plyn, upozorní se uživatelé. Pokud jsou v místnosti, zapne ventilace v místnosti a otevřou se okna.

### Vyteklá voda, pohyb v objektu

Při úniku vody(_vyteklá pračka_) nebo neoprávněném pohybu ivnitř je uživatel systémem upozorněn.

## Komfortní prvky

### Teplota a vlhkost

Uživatel si může nastavit teplotu i vlhkost, kterou by rád měl uvnitř budovy.
V případě nízké teploty v místnosti se zapne topení, při překročení nastavené teploty se topení vypne, popřípadě se otevřou okna nebo spustí ventilace.
Při překročení vlhkosti se zapne ventilace, např. po koupání.

### Přístroje přidané uživatelem

Systém je připraven na rozšíření dalšími chytrými přístroji. Předdefinované interfaces dokáží ovládat zařízení, která se pouze zapínají/vypínají, i zařízení s regulací, u kterých se mění i úroveň nějaké vlastnosti.
