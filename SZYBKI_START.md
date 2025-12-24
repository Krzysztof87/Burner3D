# Przewodnik Szybkiego Startu - Burner3D

## Wprowadzenie

Ten przewodnik pomoże Ci szybko rozpocząć pracę z systemem Burner3D. System służy do zarządzania parkiem drukarek 3D i monitorowania ich wydajności.

## Wymagania Wstępne

### Oprogramowanie
- **Microsoft SQL Server** 2016 lub nowszy
- **SQL Server Management Studio (SSMS)** 18.0 lub nowszy
- Dostęp do bazy danych z odpowiednimi uprawnieniami

### Minimalne Wymagania Sprzętowe
- Procesor: 2 GHz dual-core
- RAM: 4 GB (zalecane 8 GB)
- Dysk: 10 GB wolnej przestrzeni

## Instalacja

### Krok 1: Sklonuj Repozytorium

```bash
git clone https://github.com/Krzysztof87/Burner3D.git
cd Burner3D
```

### Krok 2: Utwórz Bazę Danych

Otwórz SQL Server Management Studio i wykonaj:

```sql
CREATE DATABASE Burner3D;
GO

USE Burner3D;
GO
```

### Krok 3: Utwórz Strukturę Tabel

*(Uwaga: Skrypty tworzenia tabel nie są dostępne w obecnej wersji repozytorium.  
Należy je utworzyć na podstawie schematu opisanego w pliku `SCHEMAT_BAZY_DANYCH.md`)*

Podstawowa struktura tabel:

```sql
-- Tabela oddziałów
CREATE TABLE Burner3D_Branch_Office (
    Id_branch INT PRIMARY KEY IDENTITY(1,1),
    Branch_name VARCHAR(50) NOT NULL,
    Branch_location VARCHAR(100) NOT NULL
);

-- Tabela drukarek
CREATE TABLE Burner3D_Printers (
    Id_printer INT PRIMARY KEY IDENTITY(1,1),
    Id_branch INT NOT NULL,
    Printer_model VARCHAR(50),
    Installation_date DATETIME,
    Status VARCHAR(20),
    FOREIGN KEY (Id_branch) REFERENCES Burner3D_Branch_Office(Id_branch)
);

-- Tabela incydentów/awarii
CREATE TABLE Burner3D_Printer_Incident (
    Id_incident INT PRIMARY KEY IDENTITY(1,1),
    Id_printer INT NOT NULL,
    Incident_number INT,
    status_1_time_st DATETIME,  -- Data rozpoczęcia awarii
    status_0_time_st DATETIME,  -- Data naprawy
    status_6_time_st DATETIME,  -- Data kasacji
    Id_incident_status INT,
    FOREIGN KEY (Id_printer) REFERENCES Burner3D_Printers(Id_printer)
);

-- Dodaj pozostałe tabele zgodnie ze schematem...
```

### Krok 4: Utwórz Funkcje Pomocnicze

```sql
-- Funkcja konwersji sekund na format czytelny
CREATE FUNCTION [dbo].[udf_b3d_sec2time] (@seconds INT)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @result VARCHAR(50);
    DECLARE @days INT = FLOOR(@seconds / 86400);
    DECLARE @hours INT = FLOOR((@seconds % 86400) / 3600);
    DECLARE @minutes INT = FLOOR(((@seconds % 86400) % 3600) / 60);
    DECLARE @secs INT = (((@seconds % 86400) % 3600) % 60);
    
    SET @result = CAST(@days AS VARCHAR) + 'd ' + 
                  CAST(@hours AS VARCHAR) + 'h ' + 
                  CAST(@minutes AS VARCHAR) + 'm ' + 
                  CAST(@secs AS VARCHAR) + 's';
    
    RETURN @result;
END;
GO

-- Dodaj pozostałe funkcje:
-- - udf_b3d_time_difference
-- - udf_b3d_weekend_days_amount
-- - udf_b3d_bank_holiday
-- - Wyznacz_zmiane
```

### Krok 5: Wczytaj Dane Testowe (Opcjonalnie)

```sql
-- Przykładowe dane dla testów
INSERT INTO Burner3D_Branch_Office (Branch_name, Branch_location) VALUES
('ODZ-01', 'Warszawa'),
('ODZ-02', 'Kraków'),
('ODZ-03', 'Wrocław');

INSERT INTO Burner3D_Printers (Id_branch, Printer_model, Installation_date, Status) VALUES
(1, 'Prusa i3 MK3S+', '2020-01-15', 'aktywna'),
(1, 'Prusa i3 MK3S+', '2020-01-15', 'aktywna'),
(2, 'Creality Ender 3 V2', '2020-02-01', 'aktywna'),
(3, 'Artillery Sidewinder X2', '2020-03-10', 'serwis');
```

## Pierwsze Kroki

### Sprawdź Status Drukarek

```sql
USE Burner3D;

-- Lista wszystkich drukarek
SELECT 
    P.Id_printer,
    P.Printer_model,
    B.Branch_name,
    B.Branch_location,
    P.Status
FROM Burner3D_Printers P
JOIN Burner3D_Branch_Office B ON P.Id_branch = B.Id_branch
ORDER BY B.Branch_name, P.Id_printer;
```

### Uruchom Podstawowe Zapytanie

Sprawdź czas postoju drukarki:

```sql
-- Parametry
DECLARE @ID_DRUKARKI INT = 1;
DECLARE @TimeBegin DATETIME = '2020-04-01 00:00:00';
DECLARE @TimeEnd DATETIME = '2020-06-18 08:08:00';

-- Zapytanie (uproszczone dla demonstracji)
SELECT 
    P.Id_printer,
    P.Printer_model,
    COUNT(I.Id_incident) AS Liczba_awarii
FROM Burner3D_Printers P
LEFT JOIN Burner3D_Printer_Incident I ON P.Id_printer = I.Id_printer
    AND I.status_1_time_st BETWEEN @TimeBegin AND @TimeEnd
WHERE P.Id_printer = @ID_DRUKARKI
GROUP BY P.Id_printer, P.Printer_model;
```

## Podstawowe Operacje

### 1. Zarejestruj Awarię Drukarki

```sql
INSERT INTO Burner3D_Printer_Incident 
(Id_printer, Incident_number, status_1_time_st, Id_incident_status)
VALUES 
(1, 1001, GETDATE(), 1);  -- Status 1 = Awaria
```

### 2. Zakończ Awarię (Napraw Drukarkę)

```sql
UPDATE Burner3D_Printer_Incident
SET status_0_time_st = GETDATE(),
    Id_incident_status = 0  -- Status 0 = Naprawiona
WHERE Id_incident = 1;  -- ID konkretnego incydentu
```

### 3. Dodaj Nowe Zamówienie

```sql
INSERT INTO Burner3D_Orders 
(Id_customer, Id_branch, Registration_date, Order_status)
VALUES 
(1, 1, GETDATE(), 'nowe');
```

### 4. Przypisz Pracę do Drukarki

```sql
INSERT INTO Burner3D_Works 
(Id_printer, Id_order, Print_start_d_time, Id_work_status)
VALUES 
(1, 100, GETDATE(), 1);  -- Status 1 = W trakcie
```

## Najważniejsze Zapytania

### Lista Zapytań w Systemie

Wszystkie główne zapytania znajdują się w pliku `testysqlzad3.sql`:

| Zapytanie | Opis | Parametry |
|-----------|------|-----------|
| **Zapytanie 3** | Czas postoju drukarki | @ID_DRUKARKI, @TimeBegin, @TimeEnd |
| **Zapytanie 4** | Czas postoju bez weekendów | @IDP, @TB, @TE |
| **Zapytanie 6** | Oddział z największą liczbą awarii | Rok (w WHERE) |
| **Zapytanie 7** | Oddział z najdłuższym postojem | @Year |
| **Zapytanie 11** | Przewidywany czas drukowania | @branchOffice |
| **Zapytanie 12** | Weryfikacja możliwości zamówienia | @order_no, @branchOffice |

### Przykład Użycia - Zapytanie 3

Skopiuj i uruchom z pliku `queries_documented.sql`:

```sql
USE Burner3D;

DECLARE @ID_DRUKARKI INT = 1;
DECLARE @TimeBegin DATETIME = '2020-04-01 00:00:00';
DECLARE @TimeEnd DATETIME = '2020-06-18 08:08:00';

-- Wykonaj zapytanie z pliku queries_documented.sql
-- Wynik: Czas postoju drukarki w formacie "Xd Xh Xm Xs"
```

## Rozwiązywanie Problemów

### Problem: Funkcja udf_b3d_sec2time nie istnieje

**Rozwiązanie**: Utwórz funkcję przed uruchomieniem zapytań (patrz Krok 4).

### Problem: Brak danych w tabelach

**Rozwiązanie**: Wczytaj dane testowe (patrz Krok 5) lub zaimportuj dane produkcyjne.

### Problem: Błąd "Invalid object name"

**Rozwiązanie**: Upewnij się, że jesteś w kontekście bazy Burner3D:
```sql
USE Burner3D;
GO
```

### Problem: Zapytanie zwraca NULL

**Rozwiązanie**: Sprawdź czy:
- Drukarka o podanym ID istnieje
- Okres czasowy zawiera dane
- Tabela Burner3D_Printer_Incident ma wpisy

## Dokumentacja

### Pliki Dokumentacji

- **README.md** - Ogólny opis aplikacji
- **SCHEMAT_BAZY_DANYCH.md** - Szczegółowy schemat bazy danych
- **PROPOZYCJE_MODYFIKACJI.md** - Sugerowane ulepszenia
- **ARCHITEKTURA.md** - Diagramy architektury systemu
- **queries_documented.sql** - Udokumentowane zapytania SQL

### Kolejne Kroki

1. **Zapoznaj się z dokumentacją** - przeczytaj pliki wymienione powyżej
2. **Eksperymentuj z danymi testowymi** - uruchom różne zapytania
3. **Dostosuj parametry** - zmień daty, ID drukarek, oddziały
4. **Rozważ ulepszenia** - przejrzyj plik PROPOZYCJE_MODYFIKACJI.md

## Wsparcie i Kontakt

### Zgłaszanie Problemów

Jeśli napotkasz problemy:
1. Sprawdź sekcję "Rozwiązywanie Problemów" powyżej
2. Przejrzyj dokumentację w plikach .md
3. Utwórz Issue na GitHubie: https://github.com/Krzysztof87/Burner3D/issues

### Wkład w Projekt

Zapraszamy do współtworzenia projektu:
1. Fork repozytorium
2. Utwórz branch dla swojej funkcjonalności
3. Wyślij Pull Request

## Najlepsze Praktyki

### Podczas Pracy z Bazą

✅ **Zawsze twórz backup** przed znaczącymi zmianami
✅ **Używaj transakcji** dla operacji modyfikujących dane
✅ **Testuj zapytania** na danych testowych przed uruchomieniem w produkcji
✅ **Dodawaj komentarze** do własnych zapytań
✅ **Monitoruj wydajność** - używaj planu wykonania (Ctrl+L w SSMS)

### Bezpieczeństwo

🔒 **Nie przechowuj haseł** w skryptach SQL
🔒 **Używaj ról i uprawnień** - przydziel minimalne wymagane uprawnienia
🔒 **Loguj operacje** - śledź kto i kiedy wykonał modyfikacje
🔒 **Regularnie aktualizuj** SQL Server do najnowszych wersji

## Przykładowy Workflow

### Typowy Dzień Pracy z Systemem

**Rano (8:00)**
```sql
-- 1. Sprawdź status wszystkich drukarek
SELECT * FROM vw_Active_Printers;  -- (jeśli widok został utworzony)

-- 2. Lista awarii z ostatnich 24h
SELECT * FROM Burner3D_Printer_Incident 
WHERE status_1_time_st >= DATEADD(hour, -24, GETDATE())
  AND status_0_time_st IS NULL;
```

**W ciągu dnia**
```sql
-- 3. Monitoruj zamówienia
SELECT * FROM Burner3D_Orders 
WHERE Order_status = 'w_trakcie';

-- 4. Sprawdź obciążenie oddziałów
-- (Uruchom Zapytanie 11 dla każdego oddziału)
```

**Wieczorem (18:00)**
```sql
-- 5. Raport dzienny
-- Uruchom Zapytanie 3 dla każdej drukarki
-- Zapisz wyniki do raportu
```

## Zasoby Dodatkowe

### Linki

- **Repository GitHub**: https://github.com/Krzysztof87/Burner3D
- **SQL Server Docs**: https://docs.microsoft.com/sql/
- **T-SQL Tutorial**: https://www.sqlservertutorial.net/

### Polecane Narzędzia

- **SQL Server Management Studio** - główne IDE
- **Azure Data Studio** - lżejsza alternatywa
- **DBeaver** - darmowe narzędzie wieloplatformowe
- **dbForge Studio** - zaawansowane narzędzie komercyjne

## FAQ - Często Zadawane Pytania

**Q: Jak często należy uruchamiać raporty?**
A: Zależy od potrzeb biznesowych. Sugerujemy: codziennie dla statusu, tygodniowo dla trendów.

**Q: Czy system obsługuje automatyczne powiadomienia?**
A: Nie w obecnej wersji. Zobacz plik PROPOZYCJE_MODYFIKACJI.md dla planów.

**Q: Jak długo przechowywać historyczne dane?**
A: Zalecamy minimum 2 lata dla analiz trendów. Starsze dane można archiwizować.

**Q: Czy można zintegrować z Power BI?**
A: Tak! Zobacz sekcję "Raportowanie i Analityka" w PROPOZYCJE_MODYFIKACJI.md.

**Q: Jakie są wymagania licencyjne SQL Server?**
A: Możesz użyć SQL Server Express (darmowy) dla małych instalacji lub SQL Server Standard/Enterprise dla produkcji.

---

**Powodzenia z Burner3D!** 🚀

Jeśli ten przewodnik był pomocny, rozważ zostawienie gwiazdki ⭐ na GitHubie!

---

**Wersja**: 1.0  
**Ostatnia aktualizacja**: 2024-12-24  
**Autor**: Krzysztof87
