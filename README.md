# Burner3D - System Zarządzania Parkiem Drukarek 3D

## Opis Aplikacji

**Burner3D** to system bazodanowy do zarządzania parkiem drukarek 3D w środowisku produkcyjnym. Aplikacja umożliwia monitorowanie, analizę i optymalizację wykorzystania drukarek 3D w wielu oddziałach firmy.

## Główne Funkcjonalności

### 1. Monitoring Awarii i Czasu Postoju
System umożliwia szczegółową analizę czasu postoju drukarek, w tym:
- Obliczanie całkowitego czasu postoju urządzenia w zadanym okresie
- Analiza czasu postoju z wyłączeniem weekendów i świąt
- Śledzenie awarii rozpoczętych przed okresem rozliczeniowym
- Monitorowanie awarii trwających (bez daty zakończenia serwisu)

### 2. Zarządzanie Zamówieniami
Aplikacja wspiera proces zarządzania zamówieniami poprzez:
- Obliczanie przewidywanego czasu drukowania dla oddziału
- Weryfikację możliwości przyjęcia zamówienia w ciągu 36h roboczych
- Monitorowanie realizacji zamówień w oddziałach

### 3. Analiza Wydajności Oddziałów
System dostarcza raportów pozwalających na:
- Identyfikację oddziału z największą liczbą awarii
- Wskazanie oddziału z najdłuższym czasem postoju urządzeń
- Analizę wykorzystania drukarek w kontekście weekendów i dni świątecznych

### 4. Kalkulacje Czasowe
Zaawansowane funkcje obliczeniowe uwzględniające:
- Dni robocze vs. weekendy
- Święta państwowe
- System zmianowy (3 zmiany)
- Konwersje czasów (sekundy → format czytelny dla człowieka)

## Struktura Bazy Danych

### Główne Tabele
- **Burner3D_Printers** - rejestr drukarek
- **Burner3D_Printer_Incident** - incydenty/awarie drukarek
- **Burner3D_Branch_Office** - oddziały firmy
- **Burner3D_Orders** - zamówienia klientów
- **Burner3D_Works** - prace wykonywane na drukarkach
- **Burner3D_Elements** - elementy do wydruku
- **Burner3D_Sets** - zestawy elementów
- **Burner3DDevices** - urządzenia/produkty
- **Burner3D_Shifts** - definicje zmian roboczych

### Funkcje Pomocnicze
- `udf_b3d_sec2time()` - konwersja sekund na format czytelny
- `udf_b3d_time_difference()` - obliczanie różnicy czasów
- `udf_b3d_weekend_days_amount()` - liczenie dni weekendowych
- `udf_b3d_bank_holiday()` - obsługa świąt państwowych
- `Wyznacz_zmiane()` - określanie zmiany roboczej

## Główne Zapytania i Raporty

### Zapytanie 3: Czas Postoju Urządzenia
Oblicza całkowity czas postoju wybranej drukarki w zadanym okresie.

### Zapytanie 4: Czas Postoju bez Weekendów
Oblicza czas postoju z wyłączeniem dni nieroboczych (weekendy i święta).

### Zapytanie 5: Sumaryczny Czas Postoju Wszystkich Urządzeń
Agregacja czasu postoju dla wszystkich drukarek w zadanym okresie.

### Zapytanie 6: Oddział z Największą Liczbą Awarii
Identyfikuje oddział wymagający uwagi pod kątem niezawodności sprzętu.

### Zapytanie 7: Oddział z Najdłuższym Czasem Postoju
Wskazuje oddział o najgorszej dostępności drukarek.

### Zapytanie 9: Liczba Zmian Postoju
Oblicza liczbę zmian roboczych, podczas których drukarka nie pracowała.

### Zapytanie 11: Przewidywany Czas Drukowania
Oblicza całkowity czas potrzebny na realizację zamówienia dla oddziału.

### Zapytanie 12: Weryfikacja Możliwości Przyjęcia Zamówienia
Sprawdza, czy zamówienie może być zrealizowane w ciągu 36h roboczych.

### Zapytanie 13: Wpływ Awarii na Realizację Zamówień
Monitoruje, czy awaria drukarki zagraża terminowej realizacji zamówień.

## Cechy Techniczne

- **Język**: T-SQL (Microsoft SQL Server)
- **Typ aplikacji**: Zapytania analityczne i procedury biznesowe
- **Złożoność**: Zaawansowane kalkulacje czasowe z uwzględnieniem dni roboczych
- **Podejście**: Deklaratywne zapytania SQL z wykorzystaniem tabeli tymczasowych

## Zastosowanie

System dedykowany dla firm produkcyjnych wykorzystujących farmy drukarek 3D, gdzie kluczowe jest:
- Maksymalizacja czasu pracy urządzeń
- Minimalizacja przestojów
- Optymalne wykorzystanie zasobów
- Terminowa realizacja zamówień
- Identyfikacja problemów w poszczególnych oddziałach

## Autor

Krzysztof87

## Licencja

Projekt dostępny na: https://github.com/Krzysztof87/Burner3D
