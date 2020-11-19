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

## Automatické přechody
