# Respiro per Garmin Forerunner 245

App Connect IQ per guidare inspirazione ed espirazione con un cerchio animato.

## Funzioni

- durata iniziale di inspirazione: 5,5 secondi;
- durata iniziale di espirazione: 5,5 secondi;
- il tasto fisico **START/ENTER** avvia e arresta la sessione;
- il cerchio cresce durante l'inspirazione e si restringe durante l'espirazione;
- il tempo residuo della fase è mostrato al centro del cerchio;
- un cronometro mostra da quanto tempo è in corso la sessione (`MM:SS`, oppure
  `H:MM:SS` dopo un'ora);
- durante la sessione la retroilluminazione rimane attiva al livello configurato
  sull'orologio;
- ogni sessione viene salvata come attività FIT “Respiro”, con durata e frequenza
  cardiaca quando disponibile, e viene sincronizzata con Garmin Connect;
- durate e colore sono configurabili nelle impostazioni dell'app tramite Garmin
  Connect, Connect IQ Store o Garmin Express;
- compatibilità dichiarata con Forerunner 245 e Forerunner 245 Music.

## Compilazione e prova

1. Installa il [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) e
   l'estensione ufficiale Monkey C per Visual Studio Code.
2. Apri questa cartella in Visual Studio Code.
3. Esegui `Monkey C: Generate a Developer Key` se non ne possiedi già una.
4. Premi `Cmd+F5` su macOS o `Ctrl+F5` su Windows/Linux e scegli `fr245`.

Da terminale, dopo aver configurato SDK e chiave sviluppatore:

```sh
monkeyc -f monkey.jungle -d fr245 -y /percorso/developer_key.der -o bin/Respiro.prg
```

Per installare manualmente sul dispositivo, collega l'orologio via USB e copia
`Respiro.prg` nella cartella `GARMIN/APPS`.

## Impostazioni

Apri il dettaglio dell'app sul telefono e seleziona **Impostazioni**. Le durate
accettano valori da 1 a 30 secondi, inclusi valori decimali come `5,5` (il
separatore visualizzato può dipendere dalla lingua del telefono). Se una durata
viene cambiata mentre l'app è aperta, il ciclo riparte dall'inspirazione.
