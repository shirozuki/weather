#!/bin/bash

# Sprawdzenie, czy na komputerze zainstalowany jest program jq
if [[ ! $(which jq) ]]; then
    echo 'Ten skrypt do prawidłowego działania potrzebuje programu jq, który nie został'
    echo 'znaleziony na komputerze. Aby kontynuować proszę zainstalować program jq.'
    exit 0;
fi

# Początkowe zmienne
url='http://api.apixu.com/v1/current.json?key='$APIXUKEY'&q='
lokalizacja=Poznan
plik=/tmp/pogoda.json
tryb_dynamiczny=0 # 0 = wyłączony, 1 = włączony
jednostki=0 # 0 = celcjusz, 1 = fahrenheit
pomoc=0

`cd /tmp &> /dev/null`

function wyswietl_pomoc
{
echo "Dostępne opcje:"
echo ""
echo "  -l [LOKALIZACJA]    Sprawdzenie pogody dla miasta innego niż domyślne (Poznań)."
echo "                      UWAGA: jeśli wprowadzona lokalizacja nie istnieje w"
echo "                      bazie apixu.com skrypt zwróci błąd, przerwie działanie"
echo "                      oraz usunie plik z danymi pogodowymi nieistniejącej"
echo "                      lokalizacji przed upływem 5 minut."
echo "                      Aby program z argumentem -l działał prawidłowo lokalizacja musi"
echo "                      zostać wpisana zaraz za argumentem -l"
echo ""
echo "          -f          Przedstawia dane pogodowe w jednostkach amerykańskich"
echo ""
echo "          -d          Tryb dynamiczny; program aktualizuje dane pogodowe co"
echo "                      5 minut."

exit 0;
}

function pobierz
{
`wget -P /tmp/ -O /tmp/pogoda.json $url$lokalizacja &> /dev/null`
if [[ `jq -r '.location.localtime' $plik`  == '' ]]; then
    echo "Wystąpił błąd. Czy wprowadzone dane były poprawne?"
    echo "W razie problemów proszę wywołać skrypt z parametrem -h"
    usun_json
    exit 0;
fi
}

function wyswietl_c
{
echo "------------------------------------------"
echo "    Aktualna pogoda dla: "$lokalizacja
echo "                   Czas: "`jq -r '.location.localtime' /tmp/pogoda.json`
echo "            Temperatura: "`jq -r '.current.temp_c' /tmp/pogoda.json`"°C"
echo " Temperatura odczuwalna: "`jq -r '.current.feelslike_c' /tmp/pogoda.json`"°C"
echo "        Prędkość wiatru: "`jq -r '.current.wind_kph' /tmp/pogoda.json`" km/h"
echo "             Widoczność: "`jq -r '.current.vis_km' /tmp/pogoda.json`" km"
echo "Ciśnienie atmosferyczne: "`jq -r '.current.pressure_mb' /tmp/pogoda.json`" mb"
echo "           Zachmurzenie: "`jq -r '.current.cloud' /tmp/pogoda.json`"%"
echo "             Wilgotność: "`jq -r '.current.humidity' /tmp/pogoda.json`"%"
echo "------------------------------------------"
}

function wyswietl_f
{
echo "------------------------------------------"
echo "    Aktualna pogoda dla: "$lokalizacja
echo "                   Czas: "`jq -r '.location.localtime' /tmp/pogoda.json`
echo "            Temperatura: "`jq -r '.current.temp_f' /tmp/pogoda.json`"°F"
echo " Temperatura odczuwalna: "`jq -r '.current.feelslike_f' /tmp/pogoda.json`"°F"
echo "        Prędkość wiatru: "`jq -r '.current.wind_mph' /tmp/pogoda.json`" m/h"
echo "             Widoczność: "`jq -r '.current.vis_miles' /tmp/pogoda.json`" m"
echo "Ciśnienie atmosferyczne: "`jq -r '.current.pressure_mb' /tmp/pogoda.json`" mb"
echo "           Zachmurzenie: "`jq -r '.current.cloud' /tmp/pogoda.json`"%"
echo "             Wilgotność: "`jq -r '.current.humidity' /tmp/pogoda.json`"%"
echo "------------------------------------------"
}

function usun_json
{
    echo "Usuwam plik pogodowy..."
    rm /tmp/pogoda.json &> /dev/null
}

function sprawdz_json
{
    if [[ -f /tmp/pogoda.json ]]; then
        echo "Plik istnieje! Sprawdzam jego datę."
        if test `find "$plik" -mmin -5` ; then
            echo "Ostatni plik pogodowy został pobrany mniej niż 5 minut temu."
            if [[ `jq -r '.location.name' $plik` != $lokalizacja ]]; then
                echo "Jednak zadana lokalizacja różni się od poprzedniej!"
                echo "Muszę usunąć stary plik i nadpisać go nowym."
                usun_json
                pobierz
            else
                echo "Wyświetlam informacje bez pobierania nowych danych."
            fi
        
        else
            echo "Plik pogodowy został pobrany więcej niż 5 minut temu."
            usun_json
            echo "Pobieram nowy..."
            pobierz
        fi
    
    elif [[ ! -f /tmp/pogoda.json ]]; then
        echo "Nie znaleziono pliku pogodowego. Pobieram nowy..."
        pobierz
    fi
}

function dynamic_mode
{
    while [[ true ]]; do
    sprawdz_json
    if [[ jednostki -eq 0 ]]; then
        wyswietl_c
    elif [[ jednostki -eq 1 ]]; then
        wyswietl_f
    fi
        
for i in {300..0}; do 
  printf '\r%2d sekund do kolejnej aktualizacji.' $i
  sleep 1
done

`reset`
    done

}


while getopts ":hdfl:" opt; do
    case ${opt} in
        l)
        lokalizacja=$OPTARG
        ;;
        d)
        tryb_dynamiczny=1
        ;;
        f)
        jednostki=1
        ;;
        h)
        pomoc=1
    esac
done

if [[ pomoc -eq 1 ]]; then
    wyswietl_pomoc
fi

if [[ tryb_dynamiczny -eq 1 ]]; then
    dynamic_mode
fi

if [[ jednostki -eq 0 ]]; then
    sprawdz_json
    wyswietl_c

elif [[ jednostki -eq 1 ]]; then
    sprawdz_json
    wyswietl_f
fi
