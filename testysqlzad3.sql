
-- 3)	Wskaż jaki był czas postoju danego urządzenia w ciągu zadanego okresu czasu.
-- #################################################################################
DECLARE @ID_DRUKARKI INT = 1                            -- Wybór urządzania (Id_printer)
DECLARE @IimeBegin DATETIME = '2020-04-01 00:00:00'     -- określenie granic okresu czasowego
DECLARE @TimeEnd DATETIME = '2020-06-18 08:08:00'

DECLARE @S1 INT = 0
DECLARE @S2 INT = 0
DECLARE @S3 INT = 0
DECLARE @S4 INT = 0

--warunek 1  Wszystkie awarie jakie objął przedział czasowy
SELECT @S1 = SUM(DATEDIFF(ss, M.status_1_time_st, M.status_0_time_st))
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @ID_DRUKARKI
AND M.status_0_time_st > @IimeBegin
AND M.status_1_time_st < @TimeEnd
-- SELECT @S1

--warunek 2  Awarie, które zakończyły się poza przedziałem czasowym a trwały w jego trakcie
SELECT @S2 = 
(
case 
    when 
        SUM(DATEDIFF(ss,  @TimeEnd, M.status_0_time_st))
        IS NULL then 0 
        ELSE 
        SUM(DATEDIFF(ss, @TimeEnd, M.status_0_time_st))
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @ID_DRUKARKI
AND M.status_0_time_st > @TimeEnd
-- SELECT @S2

--warunek 3 Awarie, które rozpoczęły się przed przedziałem czasowym a trwały w jego trakcie
SELECT @S3 = 
(
case 
    when 
        SUM(DATEDIFF(ss, M.status_1_time_st, @IimeBegin))
        IS NULL then 0
        ELSE
        SUM(DATEDIFF(ss, M.status_1_time_st, @IimeBegin))
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @ID_DRUKARKI
AND M.status_1_time_st < @IimeBegin  
-- SELECT @S3

--warunek 4  Awarie, które objął przedział czasowy ale nie mają daty przywrócenia do pracy (są w trakcie serwisu)
SELECT @S4 = 
(
case 
    when 
        SUM(DATEDIFF(ss, @IimeBegin, @TimeEnd))
        IS NULL then 0
        ELSE
        SUM(DATEDIFF(ss, @IimeBegin, @TimeEnd))
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st  IS NULL AND P.Id_printer = @ID_DRUKARKI
AND M.status_1_time_st < @TimeEnd

-- SELECT @IDP AS 'Printer', @S1 - @S2 - @S3 + @S4 
SELECT @ID_DRUKARKI AS 'Drukarka', [dbo].[udf_b3d_sec2time](@S1 - @S2 - @S3 + @S4) AS '      Czas postoju wybranej drukarki   '


-- -- -- DECLARE @IncidentTimeS1 INT = 0
-- -- -- DECLARE @IncidentTimeS0 INT = 0
-- -- -- DECLARE @IncidentTimeS0_e INT = 0
-- -- -- DECLARE @IncidentTimeSum INT = 0
-- -- -- DECLARE @IncidentCountS0 INT = 0
-- -- -- DECLARE @IncidentCountS1 INT = 0
-- -- -- DECLARE @timestapminc datetime
-- -- -- DECLARE @returntoprod datetime
-- -- -- DECLARE @continousIncident INT = 0
-- -- -- DECLARE @amountStartInc INT = 0
-- -- -- DECLARE @amountCloseInc INT = 0

-- -- -- -- SELECT @amountCloseInc = count(BPI.Id_incident_status)
-- -- -- -- SELECT count(BPI.Id_incident_status) AS 'Zakonczone awarie'
-- -- -- -- SELECT BPI.Id_printer AS "Printer", BPI.Id_incident_status AS 'Status',BPI.Incident_d_time AS 'Time'
-- -- -- -- SELECT BPI.Incident_d_time AS 'Time'
-- -- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- -- WHERE (BPI.Id_incident_status = 0 OR BPI.Id_incident_status = 6) AND BPI.Incident_number IN (
-- -- -- --     SELECT BPI.Incident_number
-- -- -- --     FROM Burner3D_Printer_Incidents AS BPI
-- -- -- --     WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Id_incident_status = 1) AND (BPI.Incident_d_time < @TimeEnd)
-- -- -- -- )



-- -- -- -- sumowanie różnic czasów: powstania awarii i daty początkowej dla awari powstałej pomiędzy datami granicznymi
-- -- -- SELECT  @IncidentTimeS1 = SUM([dbo].[udf_b3d_time_difference](BPI.Incident_d_time, @IimeBegin, 0))
-- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Incident_d_time BETWEEN @IimeBegin AND @TimeEnd) AND BPI.Id_incident_status = 1
-- -- -- --SET @IncidenttimeSum = @IncidenttimeSum + @IncidentTimeS1
-- -- -- -- SELECT @IncidentTimeS1 AS 'I przypadek'

-- -- -- -- sumowanie różnic czasów: końca awarii i daty początkowej dla awarii zakończonych po dacie granicznej
-- -- -- SELECT @IncidentTimeS0 = SUM([dbo].[udf_b3d_time_difference](@IimeBegin, BPI.Incident_d_time, 0))
-- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Incident_d_time >= @IimeBegin ) AND (BPI.Id_incident_status = 0 OR BPI.Id_incident_status = 6)
-- -- -- --SET @IncidenttimeSum = @IncidenttimeSum + @IncidentTimeS0
-- -- -- -- SELECT @IncidentTimeS0 AS 'II przypadek'

-- -- -- SELECT @IncidentTimeS0_e = SUM([dbo].[udf_b3d_time_difference](BPI.Incident_d_time, @TimeEnd, 0))
-- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Incident_d_time > @TimeEnd ) AND (BPI.Id_incident_status = 0 OR BPI.Id_incident_status = 6)
-- -- -- --SET @IncidenttimeSum = @IncidenttimeSum + @IncidentTimeS0_e
-- -- -- SET @IncidentTimeS0_e = ISNULL(@IncidentTimeS0_e,0)
-- -- -- -- SELECT @IncidentTimeS0_e AS 'III przypadek'

-- -- -- SELECT @amountStartInc = COUNT(BPI.Incident_number)
-- -- -- -- SELECT COUNT(BPI.Incident_number) AS 'Rozpoczete awarie'
-- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Id_incident_status = 1) AND (BPI.Incident_d_time < @TimeEnd)

-- -- -- SELECT @amountCloseInc = count(BPI.Id_incident_status)
-- -- -- -- SELECT count(BPI.Id_incident_status) AS 'Zakonczone awarie'
-- -- -- -- SELECT BPI.Id_printer AS "Printer", BPI.Id_incident_status AS 'Status',BPI.Incident_d_time AS 'Time'
-- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- WHERE (BPI.Id_incident_status = 0 OR BPI.Id_incident_status = 6) AND BPI.Incident_number IN (
-- -- --     SELECT BPI.Incident_number
-- -- --     FROM Burner3D_Printer_Incidents AS BPI
-- -- --     WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Id_incident_status = 1) AND (BPI.Incident_d_time < @TimeEnd)
-- -- -- )
-- -- -- SET @continousIncident = ISNULL((@amountStartInc - @amountCloseInc)* [dbo].[udf_b3d_time_difference](@IimeBegin,@TimeEnd, 0),0)
-- -- -- -- SELECT @continousIncident AS 'Czas awari trwających [s]'
-- -- -- -- SELECT  @IncidentCountS1 = COUNT(BPI.Id_printer_incident)
-- -- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- -- WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Incident_d_time < @TimeEnd ) AND (BPI.Id_incident_status = 1)
-- -- -- -- --SET @IncidenttimeSum = @IncidenttimeSum + @IncidenttimeS1
-- -- -- -- SELECT @IncidentCountS1 AS 'IV przypadek staus 1+'

-- -- -- -- SELECT @IncidentCountS0 = COUNT(BPI.Id_printer_incident)
-- -- -- -- FROM Burner3D_Printer_Incidents AS BPI
-- -- -- -- WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Incident_d_time >= @IimeBegin ) AND (BPI.Id_incident_status = 0 OR BPI.Id_incident_status = 6)
-- -- -- -- --SET @IncidenttimeSum = @IncidenttimeSum + @IncidenttimeS0
-- -- -- -- SELECT @IncidentCountS0 AS 'V przypadek status 0-', @IncidentCountS1 - @IncidentCountS0 AS 'AWARIE W TRAKCIE TRWANIA'

-- -- -- SET @IncidenttimeSum = @IncidentTimeS1 + @IncidenttimeS0 + @IncidentTimeS0_e + @continousIncident
-- -- -- -- SELECT @ID_DRUKARKI, @IncidenttimeSum AS 'SUMARYCZNY CZAS AWARII [s]', @IncidenttimeSum/60 AS 'SUMARYCZNY CZAS AWARII [min]', @IncidenttimeSum/3600 AS 'SUMARYCZNY CZAS AWARII [h]'
-- -- -- select [dbo].[udf_b3d_sec2time](@IncidenttimeSum)





-- 4)	Wskaż jaki był czas postoju danego urządzenia w ciągu zadanego okresu czasu nie wliczając w to
--      czasu kiedy zakład produkcyjny nie pracował (weekendy)
-- #################################################################################
--  Czas sumaryczny dotyczy drukarek przywróconych do pracy lub w trakcie trwania serwisu. 
--  Odjęto czasy awarii sprzed okresu rozliczeniowego oraz czasy awarii zakończonych po okresie rozliczeniowym. 
--  Uwzględniono czasy awarii trwających (brak daty zakończenie serwisu)


DECLARE @IDP INT = 1                                   -- Wybór urządzania (Id_printer)
DECLARE @TB DATETIME = '2020-04-01 00:00'              -- określenie granic okresu czasu rozliczeniowego
DECLARE @TE DATETIME = '2020-04-20 23:59'
DECLARE @SWS1 INT = 0
DECLARE @SWS2 INT = 0
DECLARE @SWS3 INT = 0
DECLARE @SWS4 INT = 0

--warunek 1  Wszystkie awarie jakie objął przedział czasowy
SELECT @SWS1 = SUM(DATEDIFF(ss, M.status_1_time_st, M.status_0_time_st) 
- [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, M.status_0_time_st) * 86400 
- [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, M.status_0_time_st) * 86400)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @IDP
AND M.status_0_time_st > @TB
AND M.status_1_time_st < @TE
-- SELECT @S1

--warunek 2  Awarie, które zakończyły się poza przedziałem czasowym a trwały w jego trakcie
SELECT @SWS2 = 
(
case 
    when 
        SUM(DATEDIFF(ss,  @TE, M.status_0_time_st) 
        - [dbo].[udf_b3d_weekend_days_amount](@TE, M.status_0_time_st) * 86400      -- odliczenie dni weekendowych
        - [dbo].[udf_b3d_bank_holiday](@TE, M.status_0_time_st) * 86400)            -- odliczenie dni świątecznych jeśli przypadły w dniu roboczym
        IS NULL then 0 
        ELSE 
        SUM(DATEDIFF(ss, @TE, M.status_0_time_st) 
        - [dbo].[udf_b3d_weekend_days_amount](@TE, M.status_0_time_st) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TE, M.status_0_time_st) * 86400)
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @IDP
AND M.status_0_time_st > @TE
-- SELECT @S2

--warunek 3 Awarie, które rozpoczęły się przed przedziałem czasowym a trwały w jego trakcie
SELECT @SWS3 = 
(
case 
    when 
        SUM(DATEDIFF(ss, M.status_1_time_st, @TB) 
        - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, @TB) * 86400 
        - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, @TB) * 86400)
        IS NULL then 0
        ELSE
        SUM(DATEDIFF(ss, M.status_1_time_st, @TB) 
        - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, @TB) * 86400 
        - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, @TB) * 86400)
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE P.Id_printer = @IDP
AND M.status_1_time_st < @TB  
-- SELECT @S3

--warunek 4  Awarie, które objął przedział czasowy ale nie mają daty przywrócenia do pracy (są w trakcie serwisu)
SELECT @SWS4 = 
(
case 
    when 
        SUM(DATEDIFF(ss, @TB, @TE) 
        - [dbo].[udf_b3d_weekend_days_amount](@TB, @TE) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TB, @TE) * 86400)
        IS NULL then 0
        ELSE
        SUM(DATEDIFF(ss, @TB, @TE) 
        - [dbo].[udf_b3d_weekend_days_amount](@TB, @TE) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TB, @TE) * 86400)
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st  IS NULL AND P.Id_printer = @IDP
AND M.status_1_time_st < @TE

-- SELECT @IDP AS 'Printer', @S1 - @S2 - @S3 + @S4 
SELECT @IDP AS 'Printer', [dbo].[udf_b3d_sec2time](@SWS1 - @SWS2 - @SWS3 + @SWS4) AS 'Czas postoju wybranej drukarki bez weekendów i świąt  '
-- SELECT BPI.Id_printer
-- FROM Burner3D_Printer_Incident AS BPI



--5)	Jaki był sumaryczny czas postoju wszystkich urządzeń w ciągu zadanego okresu czasu nie wliczając w to czasu kiedy zakład produkcyjny nie pracował (weekendy)
-- ####################################################################################################################################################################
--  Czas sumaryczny obejmuje drukarki przywrócone do pracy lub w trakcie trwania serwisu. 
--  Odjęto czasy awarii sprzed okresu rozliczeniowego oraz czasy awarii zakończonych po okresie rozliczeniowym. 
--  Uwzględniono czasy awarii trwających (brak daty zakończenie serwisu)
DECLARE @TBW DATETIME = '2020-04-19 00:00'              -- określenie granic czasowych okresu rozliczeniowego
DECLARE @TEW DATETIME = '2020-04-20 23:59'
DECLARE @SWS1A INT = 0
DECLARE @SWS2A INT = 0
DECLARE @SWS3A INT = 0
DECLARE @SWS4A INT = 0

--warunek 1  Dotyczy wszystkich awarii jakie objął okres rozliczeniowy
SELECT @SWS1A = SUM(DATEDIFF(ss, M.status_1_time_st, M.status_0_time_st) 
- [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, M.status_0_time_st) * 86400   -- odliczenie dni weekendowych
- [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, M.status_0_time_st) * 86400)         -- odliczenie dni świątecznych jeśli przypadły w dniu roboczym
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st > @TBW AND M.status_1_time_st < @TEW
--warunek 2  Obejmuje awarie, które zakończyły się po okresie rozliczeniowym a trwały w jego trakcie
SELECT @SWS2A = 
(
case 
    when 
        SUM(DATEDIFF(ss,  @TEW, M.status_0_time_st) 
        - [dbo].[udf_b3d_weekend_days_amount](@TEW, M.status_0_time_st) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TEW, M.status_0_time_st) * 86400)
        IS NULL then 0 
        ELSE 
        SUM(DATEDIFF(ss, @TEW, M.status_0_time_st) 
        - [dbo].[udf_b3d_weekend_days_amount](@TEW, M.status_0_time_st) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TEW, M.status_0_time_st) * 86400)
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st > @TEW
--warunek 3 Obejmuje awarie, które rozpoczęły się przed okresem rozliczeniowym a trwały w jego trakcie
SELECT @SWS3A = 
(
case 
    when 
        SUM(DATEDIFF(ss, M.status_1_time_st, @TBW) 
        - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, @TBW) * 86400 
        - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, @TBW) * 86400)
        IS NULL then 0
        ELSE
        SUM(DATEDIFF(ss, M.status_1_time_st, @TBW) 
        - [dbo].[udf_b3d_weekend_days_amount](M.status_1_time_st, @TBW) * 86400 
        - [dbo].[udf_b3d_bank_holiday](M.status_1_time_st, @TBW) * 86400)
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE M.status_1_time_st < @TBW  
--warunek 4  Dotyczy awarie, które objął okres rozliczeniowy ale nie mają daty przywrócenia do pracy (są w trakcie serwisu)
SELECT @SWS4A = 
(
case 
    when 
        SUM(DATEDIFF(ss, @TBW, @TEW) 
        - [dbo].[udf_b3d_weekend_days_amount](@TBW, @TEW) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TBW, @TEW) * 86400)
        IS NULL then 0
        ELSE
        SUM(DATEDIFF(ss, @TBW, @TEW) 
        - [dbo].[udf_b3d_weekend_days_amount](@TBW, @TEW) * 86400 
        - [dbo].[udf_b3d_bank_holiday](@TBW, @TEW) * 86400)
    END
)
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS M on P.Id_printer = M.Id_printer 
WHERE M.status_0_time_st  IS NULL AND M.status_1_time_st < @TEW
SELECT [dbo].[udf_b3d_sec2time](@SWS1A - @SWS2A - @SWS3A + @SWS4A) AS ' Czas postoju drukarkarek bez weekendów i świąt  '



-- 6)	Wskaż oddział w którym w 2020 roku urządzenia psuły się najczęściej
-- **************************************************************	 

SELECT TOP 1
count(Pr.Id_printer) as 'Liczba_awarii', BO.Branch_location
FROM Burner3D_Printers AS Pr
JOIN Burner3D_Printer_Incidents AS BPI on Pr.Id_printer = BPI.Id_printer
JOIN Burner3D_Branch_Office AS BO on Pr.Id_branch = Bo.Id_branch
WHERE YEAR(BPI.Incident_d_time) = CONVERT(nvarchar,2020) AND BPI.Id_incident_status = 1
GROUP BY BO.Branch_location
ORDER BY Liczba_awarii DESC



-- 7)	Wskaż oddział w którym w 2020 roku był najdłuższy czas postoju urządzeń.
-- *****************************************************************************
-- obliczenia czasu trwania awarii przy założeniu, że na poczet roku rozliczeniowego zaliczany jest cały czas trwania awarii
	 
DECLARE @Year date
SET @Year = '2020'              -- określenie roku rozliczeniowego
SELECT TOP 1
[dbo].[udf_b3d_sec2time](
CONVERT( int, DATEDIFF(s,0, DATEADD(s, SUM(
-- CONVERT(time, DATEADD(s, SUM(
case 
when DATEDIFF(wk, INC.status_1_time_st, INC.status_0_time_st) = 0 
then DATEDIFF(s, 0, (INC.status_0_time_st - INC.status_1_time_st))
else 
DATEDIFF(s, 0, dateadd(day, -(DATEDIFF(wk, INC.status_1_time_st, INC.status_0_time_st) * 2), (INC.status_0_time_st - INC.status_1_time_st)))
END
), 0)))) AS 'Najdłuższy_łączny_czas_awarii_drukarek_w_oddziale', BO.Branch_name AS 'Kod Odziału'
-- ), 0)) AS time, BO.Branch_name AS 'Kod Odziału'
FROM Burner3D_Printers AS P 
JOIN Burner3D_Printer_Incident AS INC ON P.Id_printer = INC.Id_printer 
JOIN [Burner3D].[dbo].[Burner3D_Branch_Office] AS BO ON P.Id_branch = BO.Id_branch 
WHERE INC.status_0_time_st  IS NOT NULL 
AND INC.status_0_time_st < DATEADD(yy , DATEDIFF_BIG(yy, 0, @Year)+1, 0)
AND INC.status_1_time_st >= @Year
GROUP BY BO.Branch_name 
ORDER BY Najdłuższy_łączny_czas_awarii_drukarek_w_oddziale DESC 


--9)	Wskaż na ilu zmianach nie pracowała maszyna (wliczając to zmianę na której zgłoszono awarię i na której uruchomiono ja znów produkcyjnie )
-- *****************************************************************************

-- DECLARE @ID_DR INT
-- DECLARE @X1 DATETIME
-- DECLARE @X2 DATETIME
-- DECLARE @Td DATETIME

-- SET @ID_DR = 1

-- SELECT BPI.Id_printer,BPI.Incident_d_time
-- FROM Burner3D_Printer_Incidents AS BPI
-- WHERE BPI.Id_printer =  @ID_DR AND BPI.Id_incident_status = 0

-- SELECT * FROM [dbo].[udf_b3d_satus_time](Id_printer,Burner3D_Printer_Incidents.Id_incident_status)

-- SELECT @X1 = BPIX.Incident_d_time
-- FROM Burner3D_Printer_Incidents AS BPIX 
-- WHERE BPIX.Id_printer =  @ID_DR AND BPIX.Id_incident_status = 0 AND BPIX.Incident_number
-- IN (
--     SELECT BPI.Incident_number
--     FROM Burner3D_Printer_Incidents AS BPI
--     WHERE BPI.Id_printer =  @ID_DR AND BPI.Id_incident_status = 0
-- )
-- SELECT @X1

-- SELECT @X2 = BPIX.Incident_d_time
-- FROM Burner3D_Printer_Incidents AS BPIX 
-- WHERE BPIX.Id_printer =  @ID_DR AND BPIX.Id_incident_status = 1 AND BPIX.Incident_number
-- IN (
--     SELECT BPI.Incident_number
--     FROM Burner3D_Printer_Incidents AS BPI
--     WHERE BPI.Id_printer =  @ID_DR AND BPI.Id_incident_status = 1
-- )

DECLARE @ID_DRUKARKI INT = 1
DECLARE @IimeBegin DATETIME = '2020-04-01 00:00:00' 
DECLARE @TimeEnd DATETIME = '2020-06-18 08:08:00'
DECLARE @X1 INT
DECLARE @X2 INT
DECLARE @Td1 DATETIME
DECLARE @Td2 DATETIME
DECLARE @shiftAmount INT = 0


SELECT @X1 = MAX(BPI.Incident_number)
FROM Burner3D_Printer_Incidents AS BPI
WHERE BPI.Id_incident_status = 1 AND BPI.Incident_number IN 
(
    SELECT BPI.Incident_number
    FROM Burner3D_Printer_Incidents AS BPI
    WHERE (BPI.Id_printer = @ID_DRUKARKI) AND (BPI.Id_incident_status = 0 OR BPI.Id_incident_status = 6)
)

SELECT @X2 = BPIX.Incident_number
FROM Burner3D_Printer_Incidents AS BPIX
WHERE (BPIX.Id_printer = @ID_DRUKARKI) AND (BPIX.Id_incident_status = 0 OR BPIX.Id_incident_status = 6)



SELECT @Td1 = BPIX.Incident_d_time
FROM Burner3D_Printer_Incidents AS BPIX
WHERE (BPIX.Id_printer = @ID_DRUKARKI) AND (BPIX.Incident_number = @X1) AND BPIX.Id_incident_status = 1 

SELECT @Td2 = BPIX.Incident_d_time
FROM Burner3D_Printer_Incidents AS BPIX
WHERE (BPIX.Id_printer = @ID_DRUKARKI) AND (BPIX.Incident_number = @X1) AND (BPIX.Id_incident_status = 0 OR BPIX.Id_incident_status = 6)

SELECT @X1,@X2,@Td1,@Td2



-- SELECT @Td1, @Td2
DECLARE @Td3 DATETIME
DECLARE @Td4 DATETIME
DECLARE @shiftAmount INT = 0
DECLARE @HMS1START TIME
DECLARE @tempB INT = 0
DECLARE @tempE INT = 0
DECLARE @tempT TIME
DECLARE @days INT
SET @Td3 = '2022-04-01 15:00:00' 
SET @Td4 = '2022-04-07 05:00:00'

SELECT @HMS1START = Burner3D_Shifts.Shift_start_time
FROM Burner3D_Shifts
WHERE Burner3D_Shifts.Id_shift = 1
SET @tempT = convert(TIME,@Td3,114)
IF @tempT >= @HMS1START
BEGIN
    SET @tempB = 4 - [dbo].[Wyznacz_zmiane](@Td3)
END
ELSE
BEGIN
    SET @tempB = 0
END
SET @tempT = convert(TIME,@Td4,114)
IF @tempT >= @HMS1START
BEGIN
    SET @tempE = [dbo].[Wyznacz_zmiane](@Td4)
END
ELSE
BEGIN
    SET @tempE = 0
END
-- SET @shiftAmount = 
SET @shiftAmount = (DATEDIFF(day,@Td3,@Td4) - 1) * 3 - [dbo].[udf_b3d_weekend_days_amount](@Td3,@Td4) * 3 + @tempB + @tempE
-- SELECT (DATEDIFF(day,@Td3,@Td4)-1) * 3
-- SELECT [dbo].[udf_b3d_weekend_days_amount](@Td3,@Td4) * 3
SELECT @shiftAmount AS 'liczba zmian'




-- 11) Jaki będzie łączny czas drukowania zleconych oddziałowi elementów
-- *****************************************************************************

DECLARE @branchOffice INT = 1

SELECT [dbo].[udf_b3d_sec2time](SUM(ELM.Production_time * DEV.Quantity * 60) ) AS 'Przewidywany czas drukowania dla oddziału', @branchOffice AS 'Numer oddziału'
FROM Burner3D_Branch_Office AS BO
JOIN Burner3D_Orders   AS ORD ON BO.Id_branch = ORD.Id_branch
JOIN Burner3DDevices   AS DEV ON ORD.Id_order = DEV.Id_order
JOIN Burner3D_Sets     AS ZST ON DEV.Id_set = ZST.Set_number
JOIN Burner3D_Elements AS ELM ON ZST.Id_element = ELM.Id_element
WHERE BO.Id_branch = @branchOffice


-- 12)	Czy jest możliwe przyjęcie zgłoszenia zamówienia w danym oddziale aby było zrealizowane w ciągu 36 h roboczych.
-- *****************************************************************************

DECLARE @Td3 DATETIME    = '2022-04-01 15:00:00' -- zmienne do testów i prób
DECLARE @Td4 DATETIME    = '2022-04-07 05:00:00'
DECLARE @order_no INT = 14
DECLARE @branchOffice INT = 1

DECLARE @shiftAmount INT = 0
DECLARE @HMS1START TIME
DECLARE @tempB INT = 0
DECLARE @tempE INT = 0
DECLARE @tempT TIME
DECLARE @days INT
DECLARE @czas_wydruku INT = 0  -- [s]

-- obliczenie czasu potrzebnego na wydruk zamówienia
SELECT @czas_wydruku = SUM(ELM.Production_time * DEV.Quantity * 60)
--SELECT ELM.Id_element, ZST.Set_number, ELM.Production_time AS 'Przewidywany czas drukowania dla oddziału', @branchOffice AS 'Numer oddziału'
FROM Burner3D_Branch_Office AS BO
JOIN Burner3D_Orders   AS ORD ON BO.Id_branch = ORD.Id_branch
JOIN Burner3DDevices   AS DEV ON ORD.Id_order = DEV.Id_order
JOIN Burner3D_Sets     AS ZST ON DEV.Id_set = ZST.Set_number
JOIN Burner3D_Elements AS ELM ON ZST.Id_element = ELM.Id_element
WHERE BO.Id_branch = @branchOffice  AND DEV.Id_order = @order_no

SELECT @branchOffice AS 'Id odziału', @order_no AS 'numer zamówienia'


-- Tabela wszystkich drukarek pracujących w oddziale
CREATE TABLE #T1 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime 
);


-- Tabela drukarek nie pracujących (naprawa lub kasacja)
CREATE TABLE #T2 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime
);

--wpisanie wartości do tabel #T1 i #T2
INSERT INTO #T1
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
--                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3

INSERT INTO #T2
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3 AND (inc.status_0_time_st IS NOT NULL OR inc.status_6_time_st > 0)

DECLARE @cidp int -- liczba drukarek sprawnych
DECLARE @stime int -- suma czasów pracy drukarek zajętych w momencie złozenia zamówienia w sekundach (czas na dokończenie poprzednich wydruków)

SELECT @cidp = COUNT(dbo.udf_b3d_time_difference(t1.Registration_date, t1.Print_finish_d_time,0)) FROM #T1 AS t1
LEFT OUTER JOIN #T2 AS t2 ON t2.id_printer = t1.id_printer
WHERE t2.id_printer IS NULL

SELECT @stime = SUM(dbo.udf_b3d_time_difference(t1.Registration_date, t1.Print_finish_d_time,0)) FROM #T1 AS t1
LEFT OUTER JOIN #T2 AS t2 ON t2.id_printer = t1.id_printer
WHERE t2.id_printer IS NULL

DROP TABLE #T1
DROP TABLE #T2

IF @cidp * 36 * 3600 - @stime - @czas_wydruku > 0
SELECT 'Zamówienie przyjmujemy do realizacji' AS '               DECYZJA               '
ELSE
SELECT '!!! Nie realizujemy tego zamowienia !!!' AS '             DECYZJA                '



-- 13)	Czy awaria danego urządzenia zagraża czasom poprawnej realizacji zleceń już zgłoszonych w danym oddziale.(TRIGGER)	
-- *****************************************************************************


DECLARE @Td3 DATETIME    = '2022-04-01 15:00:00' -- zmienne do testów i prób
DECLARE @Td4 DATETIME    = GETDATE()

DECLARE @order_no INT = 14
DECLARE @branchOffice INT = 1

DECLARE @shiftAmount INT = 0
DECLARE @HMS1START TIME
DECLARE @tempB INT = 0
DECLARE @tempE INT = 0
DECLARE @tempT TIME
DECLARE @days INT
DECLARE @czas_wydruku INT = 0  -- [s]

-- obliczenie czasu potrzebnego na wydruk zamówienia
SELECT @czas_wydruku = SUM(ELM.Production_time * DEV.Quantity * 60)
--SELECT ELM.Id_element, ZST.Set_number, ELM.Production_time AS 'Przewidywany czas drukowania dla oddziału', @branchOffice AS 'Numer oddziału'
FROM Burner3D_Branch_Office AS BO
JOIN Burner3D_Orders   AS ORD ON BO.Id_branch = ORD.Id_branch
JOIN Burner3DDevices   AS DEV ON ORD.Id_order = DEV.Id_order
JOIN Burner3D_Sets     AS ZST ON DEV.Id_set = ZST.Set_number
JOIN Burner3D_Elements AS ELM ON ZST.Id_element = ELM.Id_element
WHERE BO.Id_branch = @branchOffice  AND DEV.Id_order = @order_no

SELECT @branchOffice AS 'Id odziału', @order_no AS 'numer zamówienia'


-- Tabela wszystkich drukarek pracujących w oddziale
CREATE TABLE #T1 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime 
);


-- Tabela drukarek nie pracujących (naprawa lub kasacja)
CREATE TABLE #T2 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime
);

--wpisanie wartości do tabel #T1 i #T2
INSERT INTO #T1
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
--                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3

INSERT INTO #T2
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3 AND (inc.status_0_time_st IS NOT NULL OR inc.status_6_time_st > 0)

DECLARE @cidp int -- liczba drukarek sprawnych
DECLARE @stime int -- suma czasów pracy drukarek zajętych w momencie złozenia zamówienia w sekundach (czas na dokończenie poprzednich wydruków)

SELECT @cidp = COUNT(dbo.udf_b3d_time_difference(t1.Registration_date, t1.Print_finish_d_time,0)) FROM #T1 AS t1
LEFT OUTER JOIN #T2 AS t2 ON t2.id_printer = t1.id_printer
WHERE t2.id_printer IS NULL

SELECT @stime = SUM(dbo.udf_b3d_time_difference(t1.Registration_date, t1.Print_finish_d_time,0)) FROM #T1 AS t1
LEFT OUTER JOIN #T2 AS t2 ON t2.id_printer = t1.id_printer
WHERE t2.id_printer IS NULL

DROP TABLE #T1
DROP TABLE #T2

IF @cidp * 36 * 3600 - @stime - @czas_wydruku > 0
SELECT 'Zamówienie przyjmujemy do realizacji' AS '               DECYZJA               '
ELSE
SELECT '!!! Nie realizujemy tego zamowienia !!!' AS '             DECYZJA                '


-- tworzenie trigera wyzwalanego zapytaniem do bazy
-- CREATE TRIGGER TR_UPD_Locations ON Burner3D_Printer_Incident 
-- FOR UPDATE 
-- as
-- BEGIN

-- zapytanie wyzwalajace trigger
--SELECT 'Zlecenie może nie zostać wykonane w przeciągu 36 h roboczych' as [Message] 
--FROM 
--(
--SELECT BBO.Branch_location  as [location], (
--case when SUM() is null 
--then 0 
--else SUM() end
--+ 
--cast(SUM() as int) 
--) as [time]
--FROM Burner3D_Printers AS BPR 
--JOIN Burner3D_Printer_Incident AS BIN on BIN.Id_printer = BPR.Id_printer 
--JOIN Burner3D_Branch_Office AS BBO on BBO.Id_branch = BPR.Id_branch 
--LEFT JOIN Burner3D_Orders AS BOS ON BOS.Id_branch = BBO.Id_branch
--LEFT JOIN Burner3D_Works AS BWS on BWS.Id_printer = BPR.Id_printer
--LEFT JOIN Burner3DDevices AS BDS ON  BDS.Id_order = BOS.Id_order
--LEFT JOIN Burner3D_Sets AS BSE ON BSE.Id_set = BDS.Id_set
--LEFT JOIN Burner3D_Elements AS BEL on BEL.Id_element = BSE.Id_element
--WHERE BWS.Print_finish_d_time is not null
--GROUP BY BBO.Branch_location
--HAVING  sum() + 60 > 2160
--END





-- USE Burner3D
--tworzenie trigera wyzwalanego zapytaniem do bazy
-- CREATE TRIGGER UDT_Burner3D_Insert 
-- ON Burner3D_Works 
-- FOR UPDATE
-- AS
-- PRINT GETDATE()
-- GO
-- BEGIN TRANSACTION
--     SELECT BWS.Id_order, BWS.Id_printer, BWS.Print_finish_d_time, BWS.Id_work_status 
--     FROM Burner3D_Works AS BWS
--     LEFT JOIN Burner3D_Orders AS BOR ON BOR.Id_order = BWS.Id_order
--     LEFT JOIN Burner3D_Printers AS BPR  ON BPR.Id_printer = BWS.Id_printer
--     LEFT JOIN Burner3D_Branch_Office AS BBO ON BBO.Id_branch = BPR.Id_branch
--     WHERE BWS.Print_finish_d_time IS NOT NULL AND BBO.Id_branch = 14
--     GO
-- --END





















-- CREATE TABLE #T  
--     (
--         B datetime,
--         E datetime
--     ); 
--ALTER TABLE #T ADD B datetime, E datetime
-- INSERT INTO #T  VALUES (
--     @X2,@X1
-- );
-- DROP TABLE #T
-- SELECT * FROM #T



-- DECLARE @IimeBegin DATETIME = '2022-04-01 00:00:00' 
-- DECLARE @TimeEnd DATETIME = '2022-06-18 08:08:00'
-- SET @IimeBegin  = '2020-06-01 23:59:59' 
-- SET @TimeEnd  = '2020-06-3 08:08:00'


-- SELECT DATEDIFF(d,@IimeBegin , @TimeEnd)

-- -- szkic do funkcji     sec2time
-- declare @T int
-- set @T = 103620
-- --set @T = 421151
-- select [dbo].[udf_b3d_sec2time](@T)  -- testy

-- select FLOOR(@T / 86400) as day,
--        FLOOR((@T % 86400) / 3600) as hour,
--        FLOOR(((@T % 86400) % 3600) / 60) as minute,
--        (((@T % 86400) % 3600) % 60) as second
--     --    (@T % 100) * 10 as millisecond





-- -- bzdury z internetu
-- select (@T / 1000000) % 100 as hour,
--        (@T / 10000) % 100 as minute,
--        (@T / 100) % 100 as second,
--        (@T % 100) * 10 as millisecond

-- select dateadd(hour, (@T / 1000000) % 100,
--        dateadd(minute, (@T / 10000) % 100,
--        dateadd(second, (@T / 100) % 100,
--        dateadd(millisecond, (@T % 100) * 10, cast('00:00:00' as time(2))))))  














--DML event TRIGGER
-- CREATE TABLE Locations (LocationID int, LocName varchar(100))
 
-- CREATE TABLE LocationHist (LocationID int, ModifiedDate DATETIME)


-- CREATE TRIGGER TR_UPD_Locations ON Locations
-- FOR UPDATE 
-- NOT FOR REPLICATION 
-- AS
 
-- BEGIN
--   INSERT INTO LocationHist
--   SELECT LocationID
--     ,getdate()
--   FROM inserted
-- END


-- *********************************************************************
-- REKURENCJA Z TABELAMI CTE
-- *********************************************************************

CREATE TABLE #Employees
(
	EmployeeID INT PRIMARY KEY NOT NULL,
	ManagerID INT NULL,
	Name VARCHAR(50) NOT NULL,
	SurName VARCHAR(50) NOT NULL, 
	BirthDate DATETIME NULL
)

INSERT INTO #Employees (EmployeeID,ManagerID ,Name,SurName,BirthDate)
VALUES
(1,NULL,'Adam','Akadenicki','1954-12-12'),
(2,1,'Alicja','Kazikowska','1974-02-26'),
(3,2,'Denis','Kolokowski','1974-04-16'),
(4,3,'Marcin','Zdziłowski','1974-06-11'),
(5,3,'Zdzislaw','BohaterGalaktyki','1988-11-12'),
(6,2,'Sandra', 'Jorge', '1968-05-08'),
(7,1,'Kamila','Krukowska','1973-02-23')

;WITH Emp_CTE AS (
		SELECT EmployeeID,ManagerID,Name,SurName, BirthDate
		FROM #Employees
		WHERE ManagerID IS NULL
		UNION ALL
		SELECT e.EmployeeID,e.ManagerID, e.Name,e.SurName,  e.BirthDate
		FROM #Employees e
		INNER JOIN Emp_CTE ecte ON ecte.EmployeeID = e.ManagerID
)

SELECT *
FROM Emp_CTE

DROP TABLE #Employees


-- *********************************************************************
-- REKURENCJA Z TABELAMI CTE
-- *********************************************************************

--?
-- CREATE TABLE #haro_products (
--     Id_customer int IDENTITY PRIMARY KEY,
--     Registration datetime,
--     customer_name varchar(50),
--     Castomer_email varchar(50)

-- );

-- INSERT INTO #haro_products(Id_customer)
-- SELECT
--     Id_customer = o.Id_customer,
--     Registration = o.Registration_date,
--     customer_name = c.customer_name,
--     Castomer_email = c.Castomer_email
--     --id_device = d.Id_devices
-- FROM 
--     Burner3D_Orders o, Burner3D_Customers c --ON c.Id_customer = o.Id_customer --,Burner3DDevices d


-- utworzenie tabeli z podana iloscia kolumn
-- Tabela drukarek nie pracujących naprawa lub kasacja
CREATE TABLE #T2 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime
  
);
-- wpisanie danych do tabeli (UWAGA dane są appendowane)
INSERT INTO #T2
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3 AND (inc.status_0_time_st IS NOT NULL OR inc.status_6_time_st > 0)

--wyswietlenie tabeli
SELECT
    *
FROM
    #T2;








-- Tabela wszystkich drukarek pracujących w oddziale
CREATE TABLE #T1 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime
  
);

INSERT INTO #T1
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
--                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3

SELECT
    *
FROM
    #T1;


USE Burner3D
UPDATE #T1
SET Registration_date = GETDATE()
-- Print_finish_d_time = '2023-04-29 20:50:43.000'
-- Id_order = 14
WHERE Id_printer = 4


-- SELECT t1.Name AS Country,t2.Name AS Region FROM dbo.Country AS t1
-- LEFT OUTER JOIN dbo.Region AS t2 ON t2.RegionId = t1.RegionId
-- WHERE t2.RegionId IS NULL

DECLARE @cidp int
DECLARE @stime int

SELECT @cidp = COUNT(dbo.udf_b3d_time_difference(t1.Registration_date, t1.Print_finish_d_time,0)) FROM #T1 AS t1
LEFT OUTER JOIN #T2 AS t2 ON t2.id_printer = t1.id_printer
WHERE t2.id_printer IS NULL


SELECT @stime = SUM(dbo.udf_b3d_time_difference(t1.Registration_date, t1.Print_finish_d_time,0)) FROM #T1 AS t1
LEFT OUTER JOIN #T2 AS t2 ON t2.id_printer = t1.id_printer
WHERE t2.id_printer IS NULL

USE Burner3D

SELECT DEV.Quantity, DEV.Id_set, BTS.Id_element    
					FROM Burner3DDevices	AS DEV  
                    LEFT OUTER JOIN Burner3D_Sets		AS BTS  ON DEV.Id_set = BTS.Set_number  
                    LEFT OUTER JOIN Burner3D_Elements AS BEL ON BEL.Id_element = BTS.Id_element
--WHERE DEV.Id_order = 14                   



select 36 * 3600 - @stime



--utworzenie tabeli z podana iloscia kolumn
CREATE TABLE #T1 (
    id_printer int,
    Id_branch int,
    id_order int,
    Registration_date datetime,
    Print_finish_d_time datetime
  
);

-- wpisanie danych do tabeli (UWAGA dane są appendowane)
INSERT INTO #T1
SELECT
    DISTINCT id_printer = p.Id_printer,
    Id_branch = bo.Id_branch,
    id_order = o.Id_order,
    Registration_date = o.Registration_date,
    Print_finish_d_time = w.Print_finish_d_time
    -- Castomer_email = c.Castomer_email,
    -- id_device = d.Id_devices
FROM 
    Burner3D_Branch_Office bo  JOIN Burner3D_Printers p ON bo.Id_branch = p.Id_branch
                               JOIN Burner3D_Orders o ON o.Id_branch = bo.Id_branch
                               JOIN Burner3D_Works w ON  w.Id_printer = p.Id_printer
                               JOIN Burner3D_Printer_Incident inc ON inc.Id_printer = p.Id_printer
WHERE bo.Id_branch = 1 AND o.Id_order = 3 AND (inc.status_0_time_st IS NOT NULL OR inc.status_6_time_st > 0)

--wyswietlenie tabeli
SELECT
    *
FROM
    #T1;

--usuwanie jednego wiersza tabeli 
--DELETE FROM #temp_time WHERE id_device = 1

--Usuwanie tabeli jeżeli mamy tabelę zapełniona to nalezy ja usunac żeby odnowa wpisać wartości
DROP TABLE #T1
DROP TABLE #T2

-- Zmiana ilosci kolumn przy pustej tabeli
ALTER TABLE #haro_products 
ADD
   -- Id_customer int IDENTITY PRIMARY KEY,
   --  Registration datetime,
   -- customer_name varchar(50),
    Castomer_email varchar(50), 
    id_device int
