# Platební terminál

Platební terminál má různé stavy, ve kterých se může nacházet. Stavy jsou následující a jejich názvy samovysvětlující :

* idle
* wait4card
* wait4pin
* pin-accept
* pin-recect
* invalid-card
* proceed-payment
* payment-error
* printing reciept

## Přechody

Přechody mezi stavy terminálu dělím na `automatické` a `event-based` podle toho, zda záleží na terminálu samotném nebo na člověku, který platbu provádí.

### Event-based přechody

Některé akce terminál sám od sebe neprovede, je tedy odkázaný na uživatele. Uživatel musí například při platbě přiložit či zasunout platební kartu do terminálu. V mém modelu má tato akce podobu funkce, která převede terminál `T` a kartu `C` do stavu, ve kterém už `T` dokáže dále pracovat s kartou `C`.

``` maude
rl [card-inserted] :
    card-inserted(terminal(wait4card, Amount), C1 ) =>
    terminal(wait4pin, Amount, C1, 0) . *** 0 is # of tries

```

Přechody závislé na události jsou tyto:

* `new-payment` - `T` ve stavu `idle` dostane informaci o nové platbě. Přejde do stavu, kde čeká na přiložení/vložení karty.
* `card-inserted` - do `T` byla vložena karta. Přejde do stavu, kde čeká na zadání PIN kódu.
* `card-tapped` - podobně jako u předchozího. Pokud je placená částka menší než nějaký limit, na PIN se neptá.
* `pin-entered` - ověří se platnost PIN kódu. Je-li správný, platba se odešle do banky, kde se vyřídí. Je-li chybný, zákazník má další dva pokusy na opravu. Po třetím pokusu se platba zamítne.

### Automatické přechody

Další přechody už může udělat terminál sám. Zde se jedná o přepisovací pravidla, některá jsou podmíněná, jiná nikoliv.

Při zadáni chybného PIN kódu se nedá dělat nic jiného, než že se platba zruší. Vytiskne se účtenka oznamující tuto zprávu a terminál se dostane do stavu `idle`.

Při správném PIN kódu může terminál získat od banky údaje potřebné k převedení částky z účtu příslušícího kartě `C` na svůj účet. Je-li karta validní (není blokovaná a není po datu expirace), může dojít k převodu. V opačném případě se platba zruší. Peníze ze převedou na straně banky, terminál jen pošle oprávněný požadavek.

Tyto přechody již nejsou závislé na událostech (je naznačen přechod mezi stavy, neexistují zde funkce, které jsou za přechody zodpovědné):

* `pin-accept -> { proceed-payment | invalid-card }` - po získání údajů od banky se ověří, zda-li je karta pořád funkční a jestli není blokovaná.
* `proceed-payment -> { printing-reciept | payment-error }` - pokud se podaří peníze převést, vytiskne se doklad o úspěchu. Pokud se stane chyba na straně banky, platba se nepovedla a vytiskne se chybová zpráva.
* `{ payment-error | invalid-card | insufficient-balance | pin-reject } -> printing-reciept` - ve všech vypsaných stavech se vytiskne chybová zpráva.
* `printing-reciept -> idle` - po tisku účtenky terminál nemá žádnou práci.

## Návrh

Ve svém modelu používám následující moduly:

* `account`
* `card`
* `bank`
* `terminal`

### Account

Účet mám jako maude object ve formátu:

 `< AccountId : Account | balance : Amount >`

Každý účet má své `Id[Oid]` a uloženou částku - `balance[Nat]`. Balance jsem se rozhodl reprezentovat jako přirozené číslo pro jednoduchost.

U účtu se můžeme zeptat na jeho zůstatek a můžeme z něj peníze odebrat či na něj peníze připsat.

### Card

`card(Id,Pin,ExpirDate)`

Platební karta má svůj identifikátor - `Id[Nat]`, podle kterého ji banka pozná, pin kód - `Pin[Nat]` a datum expirace - `ExpirDate[Nat]`. U platební karty se ještě máme ověřovací trojčíslí, vlastníka a možná další informace, které jsem se ale z jednoduchosti opět rozhodl vynechat.

### Bank

Banku ve svém modelu reprezenuji jen jako modul, který má funkce příslušící bance.

Banka má u sebe klientské účty, u kterých může kontrolovat zůstatek a převádět mezi nimi peníze.

Dále u karet dokáže ověřit, jestli jsou blokované (má na to databázi řešenou pouze seznamem idček karet), jsou-li propadlé (porovná data).

### Terminal

Zmíněné výše v sekci Přechody.

## Testy

Sepsal jsem pár jednoduchých testů. Jsou v souboru `tests.maude`, po konci modulu `TESTS` jsou zakomentované jednotlivé případy.
