# Schemat Bazy Danych Burner3D

## Przegląd

Baza danych **Burner3D** została zaprojektowana do zarządzania parkiem drukarek 3D w środowisku produkcyjnym z wieloma oddziałami. System śledzi zamówienia, przypisanie pracy do drukarek, awarie i serwis urządzeń.

## Diagram Relacji (Konceptualny)

```
Burner3D_Customers ──→ Burner3D_Orders ──→ Burner3DDevices ──→ Burner3D_Sets ──→ Burner3D_Elements
                              │                    │
                              ↓                    ↓
                    Burner3D_Branch_Office   Burner3D_Works
                              │                    │
                              ↓                    ↓
                       Burner3D_Printers ←────────┘
                              │
                              ↓
                  Burner3D_Printer_Incident
```

## Tabele Główne

### 1. Burner3D_Customers
**Opis**: Klienci składający zamówienia na wydruki 3D

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_customer | INT | Klucz główny (PK) |
| customer_name | VARCHAR | Nazwa klienta |
| Customer_email | VARCHAR | Adres email kontaktowy |

**Relacje**:
- → Burner3D_Orders (1:N)

---

### 2. Burner3D_Branch_Office
**Opis**: Oddziały firmy posiadające drukarki 3D

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_branch | INT | Klucz główny (PK) |
| Branch_name | VARCHAR | Kod/nazwa oddziału |
| Branch_location | VARCHAR | Lokalizacja geograficzna |

**Relacje**:
- → Burner3D_Printers (1:N)
- → Burner3D_Orders (1:N)

**Indeksy sugerowane**:
```sql
CREATE INDEX IX_Branch_Name ON Burner3D_Branch_Office(Branch_name);
```

---

### 3. Burner3D_Printers
**Opis**: Rejestr drukarek 3D

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_printer | INT | Klucz główny (PK) |
| Id_branch | INT | Klucz obcy do oddziału (FK) |
| Printer_model | VARCHAR | Model drukarki |
| Installation_date | DATETIME | Data instalacji |
| Status | VARCHAR | Status aktualny (aktywna/serwis/kasacja) |

**Relacje**:
- ← Burner3D_Branch_Office (N:1)
- → Burner3D_Printer_Incident (1:N)
- → Burner3D_Works (1:N)

**Indeksy sugerowane**:
```sql
CREATE INDEX IX_Printers_Branch ON Burner3D_Printers(Id_branch, Id_printer);
CREATE INDEX IX_Printers_Status ON Burner3D_Printers(Status) WHERE Status = 'aktywna';
```

---

### 4. Burner3D_Printer_Incident
**Opis**: Rejestr awarii i incydentów drukarek

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_incident | INT | Klucz główny (PK) |
| Id_printer | INT | Klucz obcy do drukarki (FK) |
| Incident_number | INT | Numer incydentu |
| status_1_time_st | DATETIME | Data rozpoczęcia awarii |
| status_0_time_st | DATETIME | Data przywrócenia do pracy |
| status_6_time_st | DATETIME | Data kasacji (jeśli dotyczy) |
| Id_incident_status | INT | Status: 0=naprawiona, 1=awaria, 6=kasacja |

**Relacje**:
- ← Burner3D_Printers (N:1)

**Indeksy krytyczne**:
```sql
CREATE INDEX IX_Incident_Printer_Dates 
ON Burner3D_Printer_Incident(Id_printer, status_1_time_st, status_0_time_st)
INCLUDE (Id_incident_status);

CREATE INDEX IX_Incident_Status_Dates
ON Burner3D_Printer_Incident(Id_incident_status, status_1_time_st, status_0_time_st);
```

**Ważne uwagi**:
- `status_0_time_st IS NULL` oznacza awarię trwającą
- Różnica między `status_1_time_st` a `status_0_time_st` = czas postoju

---

### 5. Burner3D_Orders
**Opis**: Zamówienia złożone przez klientów

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_order | INT | Klucz główny (PK) |
| Id_customer | INT | Klucz obcy do klienta (FK) |
| Id_branch | INT | Oddział realizujący (FK) |
| Registration_date | DATETIME | Data przyjęcia zamówienia |
| Deadline | DATETIME | Termin realizacji |
| Order_status | VARCHAR | Status zamówienia |

**Relacje**:
- ← Burner3D_Customers (N:1)
- ← Burner3D_Branch_Office (N:1)
- → Burner3DDevices (1:N)
- → Burner3D_Works (1:N)

**Indeksy sugerowane**:
```sql
CREATE INDEX IX_Orders_Branch_Date 
ON Burner3D_Orders(Id_branch, Registration_date);

CREATE INDEX IX_Orders_Status 
ON Burner3D_Orders(Order_status, Registration_date);
```

---

### 6. Burner3DDevices
**Opis**: Urządzenia/produkty zawarte w zamówieniu

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_devices | INT | Klucz główny (PK) |
| Id_order | INT | Klucz obcy do zamówienia (FK) |
| Id_set | INT | Klucz obcy do zestawu (FK) |
| Quantity | INT | Ilość sztuk do wyprodukowania |

**Relacje**:
- ← Burner3D_Orders (N:1)
- ← Burner3D_Sets (N:1)

---

### 7. Burner3D_Sets
**Opis**: Zestawy elementów (bill of materials)

| Kolumna | Typ | Opis |
|---------|-----|------|
| Set_number | INT | Klucz główny (PK) |
| Id_element | INT | Klucz obcy do elementu (FK) |
| Set_name | VARCHAR | Nazwa zestawu |

**Relacje**:
- → Burner3DDevices (1:N)
- ← Burner3D_Elements (N:1)

---

### 8. Burner3D_Elements
**Opis**: Elementy do wydruku (części)

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_element | INT | Klucz główny (PK) |
| Element_name | VARCHAR | Nazwa elementu |
| Production_time | INT | Czas produkcji w minutach |
| Material | VARCHAR | Materiał (PLA, ABS, etc.) |
| Weight | DECIMAL | Waga w gramach |

**Relacje**:
- → Burner3D_Sets (1:N)

**Indeksy sugerowane**:
```sql
CREATE INDEX IX_Elements_Name ON Burner3D_Elements(Element_name);
CREATE INDEX IX_Elements_Time ON Burner3D_Elements(Production_time);
```

---

### 9. Burner3D_Works
**Opis**: Przypisanie pracy do drukarek (harmonogram produkcji)

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_work | INT | Klucz główny (PK) |
| Id_printer | INT | Drukarka wykonująca (FK) |
| Id_order | INT | Zamówienie (FK) |
| Print_start_d_time | DATETIME | Data rozpoczęcia druku |
| Print_finish_d_time | DATETIME | Data zakończenia druku |
| Id_work_status | INT | Status pracy |

**Relacje**:
- ← Burner3D_Printers (N:1)
- ← Burner3D_Orders (N:1)

**Indeksy krytyczne**:
```sql
CREATE INDEX IX_Works_Printer_Dates 
ON Burner3D_Works(Id_printer, Print_finish_d_time)
WHERE Print_finish_d_time IS NOT NULL;

CREATE INDEX IX_Works_Order 
ON Burner3D_Works(Id_order, Id_work_status);
```

---

### 10. Burner3D_Shifts
**Opis**: Definicje zmian roboczych

| Kolumna | Typ | Opis |
|---------|-----|------|
| Id_shift | INT | Klucz główny (PK) |
| Shift_name | VARCHAR | Nazwa zmiany (I, II, III) |
| Shift_start_time | TIME | Godzina rozpoczęcia |
| Shift_end_time | TIME | Godzina zakończenia |

**Przykładowe dane**:
```sql
INSERT INTO Burner3D_Shifts VALUES 
(1, 'Zmiana I', '06:00:00', '14:00:00'),
(2, 'Zmiana II', '14:00:00', '22:00:00'),
(3, 'Zmiana III', '22:00:00', '06:00:00');
```

---

## Funkcje Pomocnicze (UDF)

### udf_b3d_sec2time
**Sygnatura**: `udf_b3d_sec2time(@seconds INT) RETURNS VARCHAR(50)`

**Opis**: Konwertuje sekundy na format czytelny: "Xd Xh Xm Xs"

**Przykład**:
```sql
SELECT [dbo].[udf_b3d_sec2time](103620);
-- Wynik: '1d 4h 47m 0s'
```

---

### udf_b3d_time_difference
**Sygnatura**: `udf_b3d_time_difference(@time1 DATETIME, @time2 DATETIME, @mode INT) RETURNS INT`

**Opis**: Oblicza różnicę czasu w sekundach między dwiema datami

**Parametry**:
- `@mode = 0`: zwraca wartość bezwzględną
- `@mode = 1`: zwraca wartość ze znakiem

---

### udf_b3d_weekend_days_amount
**Sygnatura**: `udf_b3d_weekend_days_amount(@startDate DATETIME, @endDate DATETIME) RETURNS INT`

**Opis**: Liczy pełne dni weekendowe (soboty + niedziele) między datami

**Zastosowanie**: Wykluczanie weekendów z obliczeń czasu postoju

---

### udf_b3d_bank_holiday
**Sygnatura**: `udf_b3d_bank_holiday(@startDate DATETIME, @endDate DATETIME) RETURNS INT`

**Opis**: Liczy święta państwowe przypadające w dni robocze między datami

**Wymagania**: Tabela z kalendarzem świąt

---

### Wyznacz_zmiane
**Sygnatura**: `Wyznacz_zmiane(@dateTime DATETIME) RETURNS INT`

**Opis**: Określa, która zmiana robocza (1, 2 lub 3) przypada na daną datę/godzinę

**Zwraca**: 1, 2 lub 3 (numer zmiany)

---

## Widoki Proponowane

### vw_Active_Printers
```sql
CREATE VIEW vw_Active_Printers AS
SELECT 
    P.Id_printer,
    P.Printer_model,
    BO.Branch_name,
    BO.Branch_location
FROM Burner3D_Printers P
JOIN Burner3D_Branch_Office BO ON P.Id_branch = BO.Id_branch
WHERE P.Status = 'aktywna'
  AND P.Id_printer NOT IN (
      SELECT Id_printer 
      FROM Burner3D_Printer_Incident 
      WHERE status_0_time_st IS NULL
  );
```

### vw_Branch_Statistics
```sql
CREATE VIEW vw_Branch_Statistics AS
SELECT 
    BO.Id_branch,
    BO.Branch_name,
    COUNT(DISTINCT P.Id_printer) AS Total_Printers,
    COUNT(DISTINCT CASE WHEN I.status_0_time_st IS NULL THEN P.Id_printer END) AS Printers_Down,
    COUNT(DISTINCT O.Id_order) AS Active_Orders
FROM Burner3D_Branch_Office BO
LEFT JOIN Burner3D_Printers P ON BO.Id_branch = P.Id_branch
LEFT JOIN Burner3D_Printer_Incident I ON P.Id_printer = I.Id_printer
LEFT JOIN Burner3D_Orders O ON BO.Id_branch = O.Id_branch
GROUP BY BO.Id_branch, BO.Branch_name;
```

---

## Procedury Składowane Proponowane

### sp_GetDeviceDowntime
```sql
CREATE PROCEDURE sp_GetDeviceDowntime
    @PrinterId INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @ExcludeWeekends BIT = 0
AS
BEGIN
    -- Implementacja zapytania 3 lub 4
END;
```

### sp_CheckOrderFeasibility
```sql
CREATE PROCEDURE sp_CheckOrderFeasibility
    @OrderId INT,
    @BranchId INT,
    @MaxHours INT = 36
AS
BEGIN
    -- Implementacja zapytania 12
END;
```

---

## Triggery Proponowane

### TR_Alert_Long_Downtime
```sql
CREATE TRIGGER TR_Alert_Long_Downtime
ON Burner3D_Printer_Incident
AFTER INSERT, UPDATE
AS
BEGIN
    -- Wysłanie alertu gdy postój > 24h
END;
```

### TR_Order_Capacity_Check
```sql
CREATE TRIGGER TR_Order_Capacity_Check
ON Burner3D_Orders
AFTER INSERT
AS
BEGIN
    -- Sprawdzenie czy oddział ma kapacitet
END;
```

---

## Optymalizacja i Konserwacja

### Statystyki
```sql
-- Aktualizacja statystyk dla kluczowych tabel
UPDATE STATISTICS Burner3D_Printer_Incident WITH FULLSCAN;
UPDATE STATISTICS Burner3D_Works WITH FULLSCAN;
UPDATE STATISTICS Burner3D_Orders WITH FULLSCAN;
```

### Partycjonowanie (dla dużych wolumenów)
```sql
-- Partycjonowanie Burner3D_Printer_Incident według roku
CREATE PARTITION FUNCTION PF_IncidentYear(DATETIME)
AS RANGE RIGHT FOR VALUES 
('2020-01-01', '2021-01-01', '2022-01-01', '2023-01-01', '2024-01-01');
```

### Archiwizacja
```sql
-- Przeniesienie danych starszych niż 2 lata do archiwum
-- Zalecane wykonywanie kwartalnie
```

---

## Kluczowe Metryki i KPI

| Metryka | Zapytanie | Częstotliwość |
|---------|-----------|---------------|
| Średni czas postoju | Zapytanie 3/4 | Dzienna |
| Liczba awarii | Zapytanie 6 | Tygodniowa |
| Wykorzystanie drukarek | Custom query | Dzienna |
| Terminowość zamówień | Custom query | Dzienna |
| MTBF (Mean Time Between Failures) | Custom query | Miesięczna |
| MTTR (Mean Time To Repair) | Custom query | Miesięczna |

---

## Bezpieczeństwo i Uprawnienia

### Role
```sql
CREATE ROLE Burner3D_ReadOnly;
CREATE ROLE Burner3D_Operator;
CREATE ROLE Burner3D_Manager;
CREATE ROLE Burner3D_Admin;
```

### Uprawnienia
```sql
-- Analityk (tylko odczyt)
GRANT SELECT ON SCHEMA::dbo TO Burner3D_ReadOnly;

-- Operator (odczyt + modyfikacja prac)
GRANT SELECT, INSERT, UPDATE ON Burner3D_Works TO Burner3D_Operator;

-- Manager (wszystko oprócz struktury)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO Burner3D_Manager;
```

---

## Backup i Recovery

### Strategia Backup
- **Full Backup**: Codziennie o 02:00
- **Differential Backup**: Co 6 godzin
- **Transaction Log Backup**: Co godzinę

### RPO/RTO
- **RPO** (Recovery Point Objective): 1 godzina
- **RTO** (Recovery Time Objective): 4 godziny

---

## Kontakt i Wsparcie

**Autor**: Krzysztof87  
**Repository**: https://github.com/Krzysztof87/Burner3D  
**Wersja dokumentacji**: 1.0  
**Data**: 2024-12-24
