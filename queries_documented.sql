/***********************************************************************
* System: Burner3D - Zarządzanie Parkiem Drukarek 3D
* Plik: queries_documented.sql
* Opis: Udokumentowana wersja zapytań analitycznych systemu Burner3D
* Autor: Krzysztof87
* Data utworzenia: 2024-12-24
* 
* Zawartość:
*   - Zapytanie 3: Czas postoju urządzenia
*   - Zapytanie 4: Czas postoju bez weekendów
*   - Zapytanie 5: Sumaryczny czas postoju wszystkich urządzeń
*   - Zapytanie 6: Oddział z największą liczbą awarii
*   - Zapytanie 7: Oddział z najdłuższym czasem postoju
*   - Zapytanie 9: Liczba zmian postoju
*   - Zapytanie 11: Przewidywany czas drukowania
*   - Zapytanie 12: Weryfikacja możliwości przyjęcia zamówienia
*   - Zapytanie 13: Wpływ awarii na realizację zamówień
***********************************************************************/

USE Burner3D;
GO

/***********************************************************************
* ZAPYTANIE 3: Czas postoju urządzenia
* 
* Opis:
*   Oblicza całkowity czas postoju wybranej drukarki w zadanym okresie.
*   Uwzględnia cztery scenariusze:
*   1. Awarie w całości mieszczące się w okresie
*   2. Awarie zakończone po okresie
*   3. Awarie rozpoczęte przed okresem
*   4. Awarie trwające (bez daty zakończenia)
*
* Parametry:
*   @ID_DRUKARKI - Identyfikator drukarki (Id_printer)
*   @TimeBegin - Początek okresu analizy (DATETIME)
*   @TimeEnd - Koniec okresu analizy (DATETIME)
*
* Wynik:
*   Drukarka - ID drukarki
*   Czas postoju - Sformatowany czas postoju
*
* Przykład użycia:
*   @ID_DRUKARKI = 1
*   @TimeBegin = '2020-04-01 00:00:00'
*   @TimeEnd = '2020-06-18 08:08:00'
***********************************************************************/

DECLARE @ID_DRUKARKI INT = 1;
DECLARE @TimeBegin DATETIME = '2020-04-01 00:00:00';
DECLARE @TimeEnd DATETIME = '2020-06-18 08:08:00';

DECLARE @S1 INT = 0;  -- Awarie w okresie
DECLARE @S2 INT = 0;  -- Awarie zakończone po okresie
DECLARE @S3 INT = 0;  -- Awarie rozpoczęte przed okresem
DECLARE @S4 INT = 0;  -- Awarie trwające

-- Warunek 1: Wszystkie awarie w całości mieszczące się w okresie
SELECT @S1 = SUM(DATEDIFF(ss, M.status_1_time_st, M.status_0_time_st))
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @ID_DRUKARKI
  AND M.status_0_time_st > @TimeBegin
  AND M.status_1_time_st < @TimeEnd;

-- Warunek 2: Awarie zakończone po okresie (odejmujemy czas po okresie)
SELECT @S2 = 
(
    CASE 
        WHEN SUM(DATEDIFF(ss, @TimeEnd, M.status_0_time_st)) IS NULL 
        THEN 0 
        ELSE SUM(DATEDIFF(ss, @TimeEnd, M.status_0_time_st))
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @ID_DRUKARKI
  AND M.status_0_time_st > @TimeEnd;

-- Warunek 3: Awarie rozpoczęte przed okresem (odejmujemy czas przed okresem)
SELECT @S3 = 
(
    CASE 
        WHEN SUM(DATEDIFF(ss, M.status_1_time_st, @TimeBegin)) IS NULL 
        THEN 0
        ELSE SUM(DATEDIFF(ss, M.status_1_time_st, @TimeBegin))
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @ID_DRUKARKI
  AND M.status_1_time_st < @TimeBegin;

-- Warunek 4: Awarie trwające (bez daty zakończenia)
SELECT @S4 = 
(
    CASE 
        WHEN SUM(DATEDIFF(ss, @TimeBegin, @TimeEnd)) IS NULL 
        THEN 0
        ELSE SUM(DATEDIFF(ss, @TimeBegin, @TimeEnd))
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st IS NULL 
  AND P.Id_printer = @ID_DRUKARKI
  AND M.status_1_time_st < @TimeEnd;

-- Wynik końcowy
SELECT 
    @ID_DRUKARKI AS 'Drukarka', 
    [dbo].[udf_b3d_sec2time](@S1 - @S2 - @S3 + @S4) AS 'Czas postoju wybranej drukarki';
GO

/***********************************************************************
* ZAPYTANIE 4: Czas postoju urządzenia (bez weekendów i świąt)
* 
* Opis:
*   Oblicza czas postoju drukarki z wyłączeniem:
*   - Weekendów (soboty i niedziele)
*   - Świąt państwowych przypadających w dni robocze
*
* Parametry:
*   @IDP - Identyfikator drukarki
*   @TB - Początek okresu (Time Begin)
*   @TE - Koniec okresu (Time End)
*
* Funkcje pomocnicze:
*   - udf_b3d_weekend_days_amount() - liczy dni weekendowe
*   - udf_b3d_bank_holiday() - liczy święta
***********************************************************************/

DECLARE @IDP INT = 1;
DECLARE @TB DATETIME = '2020-04-01 00:00';
DECLARE @TE DATETIME = '2020-04-20 23:59';

DECLARE @SWS1 INT = 0;
DECLARE @SWS2 INT = 0;
DECLARE @SWS3 INT = 0;
DECLARE @SWS4 INT = 0;

-- Warunek 1: Awarie w okresie (z odliczeniem weekendów i świąt)
SELECT @SWS1 = SUM(
    DATEDIFF(ss, M.status_1_time_st, M.status_0_time_st) 
    - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, M.status_0_time_st) * 86400 
    - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, M.status_0_time_st) * 86400
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @IDP
  AND M.status_0_time_st > @TB
  AND M.status_1_time_st < @TE;

-- Warunek 2: Awarie zakończone po okresie
SELECT @SWS2 = 
(
    CASE 
        WHEN SUM(
            DATEDIFF(ss, @TE, M.status_0_time_st) 
            - [dbo].[udf_b3d_weekend_days_amount](@TE, M.status_0_time_st) * 86400
            - [dbo].[udf_b3d_bank_holiday](@TE, M.status_0_time_st) * 86400
        ) IS NULL 
        THEN 0 
        ELSE SUM(
            DATEDIFF(ss, @TE, M.status_0_time_st) 
            - [dbo].[udf_b3d_weekend_days_amount](@TE, M.status_0_time_st) * 86400 
            - [dbo].[udf_b3d_bank_holiday](@TE, M.status_0_time_st) * 86400
        )
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @IDP
  AND M.status_0_time_st > @TE;

-- Warunek 3: Awarie rozpoczęte przed okresem
SELECT @SWS3 = 
(
    CASE 
        WHEN SUM(
            DATEDIFF(ss, M.status_1_time_st, @TB) 
            - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, @TB) * 86400 
            - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, @TB) * 86400
        ) IS NULL 
        THEN 0
        ELSE SUM(
            DATEDIFF(ss, M.status_1_time_st, @TB) 
            - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, @TB) * 86400 
            - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, @TB) * 86400
        )
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @IDP
  AND M.status_1_time_st < @TB;

-- Warunek 4: Awarie trwające
SELECT @SWS4 = 
(
    CASE 
        WHEN SUM(
            DATEDIFF(ss, @TB, @TE) 
            - [dbo].[udf_b3d_weekend_days_amount](@TB, @TE) * 86400 
            - [dbo].[udf_b3d_bank_holiday](@TB, @TE) * 86400
        ) IS NULL 
        THEN 0
        ELSE SUM(
            DATEDIFF(ss, @TB, @TE) 
            - [dbo].[udf_b3d_weekend_days_amount](@TB, @TE) * 86400 
            - [dbo].[udf_b3d_bank_holiday](@TB, @TE) * 86400
        )
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M ON P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st IS NULL 
  AND P.Id_printer = @IDP
  AND M.status_1_time_st < @TE;

-- Wynik
SELECT 
    @IDP AS 'Printer', 
    [dbo].[udf_b3d_sec2time](@SWS1 - @SWS2 - @SWS3 + @SWS4) AS 'Czas postoju bez weekendów i świąt';
GO

/***********************************************************************
* ZAPYTANIE 6: Oddział z największą liczbą awarii
* 
* Opis:
*   Identyfikuje oddział, w którym w danym roku urządzenia psuły się
*   najczęściej. Pomocne w identyfikacji problemów operacyjnych.
*
* Parametry:
*   Rok: 2020 (zakodowany w zapytaniu)
*
* Wynik:
*   Liczba_awarii - liczba zgłoszonych awarii
*   Branch_location - lokalizacja oddziału
***********************************************************************/

SELECT TOP 1
    COUNT(Pr.Id_printer) AS 'Liczba_awarii', 
    BO.Branch_location
FROM Burner3D_Printers AS Pr
JOIN Burner3D_Printer_Incidents AS BPI ON Pr.Id_printer = BPI.Id_printer
JOIN Burner3D_Branch_Office AS BO ON Pr.Id_branch = BO.Id_branch
WHERE YEAR(BPI.Incident_d_time) = 2020 
  AND BPI.Id_incident_status = 1
GROUP BY BO.Branch_location
ORDER BY Liczba_awarii DESC;
GO

/***********************************************************************
* ZAPYTANIE 7: Oddział z najdłuższym czasem postoju
* 
* Opis:
*   Wskazuje oddział o najdłuższym łącznym czasie postoju drukarek
*   w danym roku. Uwzględnia weekendy (odejmuje czas weekendów).
*
* Parametry:
*   @Year - rok rozliczeniowy (DATE)
*
* Funkcjonalność:
*   - Agreguje czas awarii dla każdego oddziału
*   - Uwzględnia weekendy w obliczeniach
*   - Konwertuje wynik na format czytelny
***********************************************************************/

DECLARE @Year DATE;
SET @Year = '2020-01-01';

SELECT TOP 1
    [dbo].[udf_b3d_sec2time](
        CONVERT(INT, DATEDIFF(s, 0, DATEADD(s, SUM(
            CASE 
                WHEN DATEDIFF(wk, INC.status_1_time_st, INC.status_0_time_st) = 0 
                THEN DATEDIFF(s, 0, (INC.status_0_time_st - INC.status_1_time_st))
                ELSE DATEDIFF(s, 0, DATEADD(day, 
                    -(DATEDIFF(wk, INC.status_1_time_st, INC.status_0_time_st) * 2), 
                    (INC.status_0_time_st - INC.status_1_time_st)
                ))
            END
        ), 0)))
    ) AS 'Najdłuższy_łączny_czas_awarii', 
    BO.Branch_name AS 'Kod_Oddziału'
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS INC ON P.Id_printer = INC.Id_printer 
JOIN Burner3D_Branch_Office AS BO ON P.Id_branch = BO.Id_branch 
WHERE INC.status_0_time_st IS NOT NULL 
  AND INC.status_0_time_st < DATEADD(yy, DATEDIFF_BIG(yy, 0, @Year) + 1, 0)
  AND INC.status_1_time_st >= @Year
GROUP BY BO.Branch_name 
ORDER BY Najdłuższy_łączny_czas_awarii DESC;
GO

/***********************************************************************
* ZAPYTANIE 11: Przewidywany czas drukowania dla oddziału
* 
* Opis:
*   Oblicza łączny przewidywany czas drukowania wszystkich elementów
*   zleconych danemu oddziałowi.
*
* Parametry:
*   @branchOffice - ID oddziału
*
* Kalkulacja:
*   Czas = SUM(Czas_produkcji_elementu × Ilość × 60 sekund)
***********************************************************************/

DECLARE @branchOffice INT = 1;

SELECT 
    [dbo].[udf_b3d_sec2time](SUM(ELM.Production_time * DEV.Quantity * 60)) AS 'Przewidywany_czas_drukowania', 
    @branchOffice AS 'Numer_oddziału'
FROM Burner3D_Branch_Office AS BO
JOIN Burner3D_Orders AS ORD ON BO.Id_branch = ORD.Id_branch
JOIN Burner3DDevices AS DEV ON ORD.Id_order = DEV.Id_order
JOIN Burner3D_Sets AS ZST ON DEV.Id_set = ZST.Set_number
JOIN Burner3D_Elements AS ELM ON ZST.Id_element = ELM.Id_element
WHERE BO.Id_branch = @branchOffice;
GO

/***********************************************************************
* KONIEC PLIKU queries_documented.sql
***********************************************************************/
