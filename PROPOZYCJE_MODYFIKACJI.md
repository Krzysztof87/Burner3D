# Propozycje Modyfikacji i Ulepszeń Systemu Burner3D

## 1. Modularyzacja Kodu

### Problem
Obecnie wszystkie zapytania znajdują się w jednym pliku `testysqlzad3.sql`, co utrudnia:
- Zarządzanie kodem
- Wersjonowanie poszczególnych funkcjonalności
- Debugowanie
- Współpracę zespołową

### Rozwiązanie
Rozdzielić kod na logiczne moduły:
```
/sql
  /queries
    - query_03_device_downtime.sql
    - query_04_downtime_without_weekends.sql
    - query_05_total_downtime_all_devices.sql
    - query_06_branch_most_failures.sql
    - query_07_branch_longest_downtime.sql
    - query_09_shift_count.sql
    - query_11_predicted_print_time.sql
    - query_12_order_feasibility.sql
    - query_13_failure_impact.sql
  /functions
    - udf_sec2time.sql
    - udf_time_difference.sql
    - udf_weekend_days_amount.sql
    - udf_bank_holiday.sql
  /procedures
    - sp_analyze_device_downtime.sql
    - sp_verify_order_capacity.sql
  /views
    - vw_active_printers.sql
    - vw_branch_statistics.sql
```

## 2. Utworzenie Procedur Składowanych

### Zalety
- Enkapsulacja logiki biznesowej
- Lepsza wydajność (plany wykonania)
- Łatwiejsze parametryzowanie
- Większe bezpieczeństwo

### Przykładowa Implementacja
```sql
CREATE PROCEDURE sp_GetDeviceDowntime
    @ID_DRUKARKI INT,
    @TimeBegin DATETIME,
    @TimeEnd DATETIME,
    @ExcludeWeekends BIT = 0
AS
BEGIN
    -- Logika obliczania czasu postoju
    -- z zapytania 3 lub 4
END
```

## 3. Optymalizacja Zapytań

### Sugestie Optymalizacji

#### a) Użycie Common Table Expressions (CTE)
Zastąpić zagnieżdżone podzapytania przez CTE dla lepszej czytelności:
```sql
WITH IncidentData AS (
    SELECT 
        P.Id_printer,
        M.status_1_time_st,
        M.status_0_time_st
    FROM Burner3D_Printers AS P 
    JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
    WHERE P.Id_printer = @ID_DRUKARKI
)
SELECT ...
FROM IncidentData
```

#### b) Indeksowanie
Dodać indeksy na często używanych kolumnach:
```sql
CREATE INDEX IX_Printer_Incident_Dates 
ON Burner3D_Printer_Incident(Id_printer, status_1_time_st, status_0_time_st);

CREATE INDEX IX_Printers_Branch 
ON Burner3D_Printers(Id_branch, Id_printer);

CREATE INDEX IX_Orders_Date 
ON Burner3D_Orders(Id_branch, Registration_date);
```

#### c) Unikanie SELECT DISTINCT
Użyć GROUP BY zamiast DISTINCT gdzie to możliwe dla lepszej wydajności.

## 4. Obsługa Błędów

### Problem
Brak obsługi błędów w zapytaniach.

### Rozwiązanie
```sql
BEGIN TRY
    -- Kod zapytania
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState;
END CATCH
```

## 5. Logowanie i Audyt

### Propozycja
Utworzyć tabelę do logowania operacji:
```sql
CREATE TABLE Burner3D_Query_Log (
    Id_log INT IDENTITY PRIMARY KEY,
    Query_name VARCHAR(100),
    Execution_date DATETIME DEFAULT GETDATE(),
    Parameters VARCHAR(500),
    Execution_time_ms INT,
    User_name VARCHAR(100),
    Result_status VARCHAR(20)
);
```

## 6. Warstwowa Architektura Aplikacji

### Warstwa Prezentacji
- **Opcja A**: Dashboard w Power BI
  - Wizualizacja KPI
  - Interaktywne raporty
  - Automatyczne odświeżanie

- **Opcja B**: Aplikacja webowa (ASP.NET Core / Node.js)
  - Panel administratora
  - System powiadomień
  - Zarządzanie drukarkami

### Warstwa Logiki Biznesowej
- API RESTful dla dostępu do danych
- Serwisy do obsługi logiki domenowej
- Walidacja danych wejściowych

### Warstwa Danych
- Bieżąca baza danych SQL Server
- Ewentualnie: cache (Redis) dla często używanych danych

## 7. System Powiadomień

### Implementacja Triggerów
```sql
CREATE TRIGGER TR_Alert_Critical_Downtime
ON Burner3D_Printer_Incident
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @DowntimeHours INT;
    
    -- Obliczenie czasu postoju
    SELECT @DowntimeHours = DATEDIFF(HOUR, i.status_1_time_st, GETDATE())
    FROM inserted i
    WHERE i.status_0_time_st IS NULL;
    
    -- Alert jeśli postój > 24h
    IF @DowntimeHours > 24
    BEGIN
        INSERT INTO Burner3D_Alerts (Alert_type, Message, Created_date)
        VALUES ('CRITICAL', 'Drukarka niepracująca przez >24h', GETDATE());
    END
END
```

## 8. Dokumentacja Kodu

### Dodać Komentarze w Standardzie
```sql
/***********************************************************************
* Zapytanie: Czas postoju urządzenia
* Opis: Oblicza całkowity czas postoju wybranej drukarki w zadanym okresie
* Parametry:
*   @ID_DRUKARKI - Identyfikator drukarki
*   @TimeBegin - Początek okresu analizy
*   @TimeEnd - Koniec okresu analizy
* Autor: Krzysztof87
* Data utworzenia: 2020-04-01
* Ostatnia modyfikacja: 2024-12-24
***********************************************************************/
```

## 9. Testy Jednostkowe

### Framework tSQLt
Utworzyć testy dla funkcji:
```sql
EXEC tSQLt.NewTestClass 'Burner3DTests';
GO

CREATE PROCEDURE Burner3DTests.[test udf_b3d_sec2time converts correctly]
AS
BEGIN
    DECLARE @actual VARCHAR(50);
    DECLARE @expected VARCHAR(50) = '1d 4h 47m 0s';
    
    SELECT @actual = [dbo].[udf_b3d_sec2time](103620);
    
    EXEC tSQLt.AssertEquals @expected, @actual;
END;
```

## 10. Konfiguracja i Zarządzanie Parametrami

### Tabela Konfiguracyjna
```sql
CREATE TABLE Burner3D_Config (
    Config_key VARCHAR(50) PRIMARY KEY,
    Config_value VARCHAR(200),
    Description VARCHAR(500),
    Modified_date DATETIME DEFAULT GETDATE()
);

INSERT INTO Burner3D_Config VALUES 
('MaxOrderProcessingHours', '36', 'Maksymalny czas realizacji zamówienia w godzinach'),
('WorkdayStartHour', '6', 'Godzina rozpoczęcia dnia roboczego'),
('AlertDowntimeThresholdHours', '24', 'Próg czasu postoju dla alertu');
```

## 11. Raportowanie i Analityka

### Proponowane Nowe Raporty
1. **Dashboard KPI**
   - Średni czas postoju w miesiącu
   - Wskaźnik wykorzystania drukarek (%)
   - Top 10 najczęściej psujących się drukarek
   - Trend awarii w czasie

2. **Raport Predykcyjny**
   - Przewidywanie awarii na podstawie historycznych danych
   - Sugerowane terminy przeglądów

3. **Raport Efektywności Oddziałów**
   - Porównanie wydajności między oddziałami
   - Ranking oddziałów wg różnych metryk

## 12. Integracje

### Potencjalne Integracje
- **System ERP** - synchronizacja zamówień
- **System ticketowy** - automatyczne zgłaszanie awarii
- **Monitoring sprzętu** - połączenie z sensorami IoT drukarek
- **E-mail/SMS** - powiadomienia o krytycznych zdarzeniach

## 13. Zabezpieczenia

### Rekomendacje
```sql
-- Role i uprawnienia
CREATE ROLE Burner3D_Analyst;
CREATE ROLE Burner3D_Manager;
CREATE ROLE Burner3D_Admin;

-- Uprawnienia dla analityków (tylko odczyt)
GRANT SELECT ON Burner3D_Printers TO Burner3D_Analyst;
GRANT SELECT ON Burner3D_Printer_Incident TO Burner3D_Analyst;
GRANT EXECUTE ON udf_b3d_sec2time TO Burner3D_Analyst;

-- Szyfrowanie wrażliwych danych
ALTER TABLE Burner3D_Customers
ADD Customer_email_encrypted VARBINARY(256);
```

## 14. Archiwizacja i Partycjonowanie

### Strategia Archiwizacji
```sql
-- Tabela archiwum dla starych danych
CREATE TABLE Burner3D_Printer_Incident_Archive (
    /* struktura taka sama jak Burner3D_Printer_Incident */
);

-- Partycjonowanie według roku
CREATE PARTITION FUNCTION PF_Year(DATETIME)
AS RANGE RIGHT FOR VALUES 
('2020-01-01', '2021-01-01', '2022-01-01', '2023-01-01', '2024-01-01');
```

## 15. Dokumentacja Deploymentu

### Skrypty Wdrożeniowe
Utworzyć:
- `01_create_database.sql`
- `02_create_tables.sql`
- `03_create_functions.sql`
- `04_create_procedures.sql`
- `05_create_triggers.sql`
- `06_create_indexes.sql`
- `07_insert_initial_data.sql`
- `08_create_users_and_roles.sql`

## Priorytety Wdrożenia

### Faza 1 (Natychmiastowa)
1. Modularyzacja kodu
2. Dokumentacja kodu
3. Optymalizacja zapytań (indeksy)

### Faza 2 (Krótkoterminowa)
4. Procedury składowane
5. Obsługa błędów
6. System logowania

### Faza 3 (Średnioterminowa)
7. Warstwa aplikacyjna
8. System powiadomień
9. Nowe raporty

### Faza 4 (Długoterminowa)
10. Testy jednostkowe
11. Integracje
12. Analityka predykcyjna

## Szacowane Korzyści

- **Wydajność**: ↑ 30-50% dzięki optymalizacji zapytań
- **Utrzymanie**: ↓ 60% czasu dzięki modularyzacji
- **Niezawodność**: ↑ 40% dzięki monitoringowi i alertom
- **Bezpieczeństwo**: ↑ 80% dzięki rolom i szyfrowaniu
- **Produktywność zespołu**: ↑ 50% dzięki automatyzacji

## Podsumowanie

Proponowane modyfikacje przekształcą system Burner3D z zestawu zapytań SQL w pełnowartościową aplikację enterprise z:
- Lepszą architekturą
- Większą wydajnością
- Łatwiejszym utrzymaniem
- Rozszerzoną funkcjonalnością
- Wyższym poziomem bezpieczeństwa

Wdrożenie powyższych zmian pozwoli na skalowanie systemu i przygotuje go na przyszłe wymagania biznesowe.
