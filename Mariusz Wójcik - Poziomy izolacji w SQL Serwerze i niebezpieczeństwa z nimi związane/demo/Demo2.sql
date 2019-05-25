USE DemoDB;
GO

-- krok 02 - spróbujmy odczytaæ dane
SELECT * FROM [dbo].[Skocznie];

-- transakcja czeka na dostêp do tabeli....
-- wracamy do pierwszej sesji 
  

-- po wykonaniu kroku 03 - zapytanie zwraca wynik

--------------------------------------
-- Demo - Read uncommitted 
--------------------------------------

-- krok 05 - brudny odczyt
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT * FROM [dbo].[Skocznie];

-- wracamy do pierwszej sesji, wycofujemy transakcjê w kroku 06
-- krok 07 ponownie raz sprawdzamy tabelê - inny wynik 

SELECT * FROM [dbo].[Skocznie];
-- dane siê zmieni³y - nast¹pi³ brudny odczyt


-- wracamy  do domyœlnej izolacji 
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--
--inne sposoby uruchomienia Read Uncommited
SELECT * FROM [dbo].[Skocznie](NOLOCK);
SELECT * FROM [dbo].[Skocznie](READUNCOMMITTED);


-- krok 08 w pierwszej sesji



--------------------------------------
-- Demo - Read commited
-- niepowtarzalny odczyt (non-repeteable read)
--------------------------------------

-- krok 09 -  zmieniamy wartoœæ wierwsza 
-- pierwsza sesja, odczytujac dane nie blokuje zapisu 
UPDATE [dbo].[Skocznie]
SET punkt_K = 250
WHERE ID = 2;


--w trybie izolacji repeatable read powy¿szy update czeka....
-- wracamy do sesji pierwszej

--------------------------------------
-- Demo - Repeatable read
-- phantoms
--------------------------------------

-- krok 15 - wrzucamy nowe dane do tabeli 
INSERT INTO [dbo].[Skocznie]
VALUES (6,'Tauplitz','Kulm',200)
	,(7,'Harrachov','Certak',185);

--  krok 16 w sesji pierwszej


--------------------------------------
-- Demo - Serializable
--------------------------------------

-- krok 19 - próbujemy wrzuciæ dane do tabeli 
INSERT INTO [dbo].[Skocznie]
VALUES (6,'Tauplitz','Kulm',200)
	,(7,'Harrachov','Certak',185);

-- zapytanie czeka na zwolnienie tabeli
-- krok 20 w sesji pierwszej


--------------------------------------
-- Demo - Serializable
--------------------------------------

-- krok 23 - próbujemy wrzuciæ dane do tabeli 
INSERT INTO [dbo].[Skocznie]
VALUES (6,'Tauplitz','Kulm',200)
	,(7,'Harrachov','Certak',185);

-- zapytanie czeka na zwolnienie tabeli
-- krok 24 w sesji pierwszej


------------------------------------------
-- Demo Snapshot, Read Committed Snapshot (RCSI)
------------------------------------------

-- krok 28 - odczytujemy dane z tabeli
BEGIN TRANSACTION;

SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;

-- krok 29 w pierwszej sesji

-- krok 30 - sprawdzamy ponownie dane

SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;
-- zwraca 250 - aktualna wersja po zatwierdzeniu pierwszej sesji

COMMIT;


------------------------------------------
-- Demo Snapshot
------------------------------------------

-- 31 próbujemy odczytac dane i 
-- zmieniæ ten sam wiersz w trybie snapshot
SET TRANSACTION ISOLATION LEVEL snapshot;

BEGIN TRANSACTION;
SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;
-- zwraca wartoœæ sprzed rozpoczêcia transakcji w pierwszej sesji



-- krok 32 w pierwszej sesji

-- krok 33 - sprawdzamy ponownie dane
SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;
-- transakcja nie widzi zmian  wprowadzonych w pierwszej transakcji

COMMIT; 

SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;

-- tutaj zmiany juz s¹ widoczne



------------------------------------------
-- Demo Snapshot - Update conflict
------------------------------------------


-- krok 34 - startujemy now¹ transakcjê i odczytujemy zmieniæ wiersz
SET TRANSACTION ISOLATION LEVEL snapshot;

BEGIN TRANSACTION;
SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;

-- krok 35 w pierwszej sesji

-- krok 36 - probujemy zapisaæ zmiany
UPDATE Skocznie 
SET punkt_K = 300
WHERE ID = 2;
-- Error 3960 update conflict 
-- transakcja próbuje zmieniæ wartoœæ która zosta³a juz zmieniona


------------------------------------------
-- Demo Snapshot - Update conflict - rozwi¹zanie 
------------------------------------------

-- krok 37
SET TRANSACTION ISOLATION LEVEL snapshot;

BEGIN TRANSACTION;

SELECT * FROM [dbo].[Skocznie] (UPDLOCK)
WHERE ID = 2;
--krok 38 w pierwszej sesji 



-- krok 39 - wykonujemy update, zwalniamy blokadê w sesji pierwszej
UPDATE Skocznie 
SET punkt_K = 250
WHERE ID = 2;

COMMIT;

-- krok 40 w pierwszej sesji

