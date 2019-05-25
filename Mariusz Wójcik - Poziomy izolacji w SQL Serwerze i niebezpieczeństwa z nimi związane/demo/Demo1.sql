USE DemoDB;
GO

cleanUP;


-- tabela testowa wygl¹da tak:
SELECT * FROM [dbo].[Skocznie];

--------------------------------------
-- Demo - Read committed 
--------------------------------------

-- krok 01 - rozpoczynamy transakcjê i zmieniamy jeden wiersz
BEGIN TRANSACTION;

UPDATE [dbo].[Skocznie]
SET punkt_K = 250
WHERE ID = 2;

-- aktualne blokady
SELECT * FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;


-- krok 02 w drugiej sesji

-- sprawdzamy wszystkie blokady 
SELECT * FROM sys.dm_tran_locks
WHERE request_session_id IN (@@SPID,xx);

-- kolejki na bazie...
SELECT OSW.session_id,
       OSW.wait_duration_ms,
       OSW.wait_type,
       DB_NAME(EXR.database_id) AS DatabaseName
FROM sys.dm_os_waiting_tasks OSW
INNER JOIN sys.dm_exec_sessions EXS ON OSW.session_id = EXS.session_id
INNER JOIN sys.dm_exec_requests EXR ON EXR.session_id = OSW.session_id
WHERE EXS.session_id IN (@@SPID,xx);


-- krok 03 - cofamy zmiany
ROLLBACK


--------------------------------------
-- Demo - Read uncommitted 
--------------------------------------

-- krok 04
BEGIN TRANSACTION;

UPDATE [dbo].[Skocznie]
SET punkt_K = 250
WHERE ID = 2;

-- sprawdŸmy ponownie blokady
SELECT * FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;


-- krok 05 w drugiej sesji

-- 06
ROLLBACK;

-- krok 07 w drugiej sesji

--------------------------------------
-- Demo - Read commited
-- niepowtarzalny odczyt (non-repeteable read)
--------------------------------------


-- krok 08 - startujemy z now¹ transakcj¹ w trybie read commited
BEGIN TRANSACTION;

-- odczytujemy dane 
SELECT max(punkt_K) FROM [dbo].[Skocznie];

-- krok 09 w drugiej sesji
-- krok 10 - drugi odczyt
SELECT max(punkt_K) FROM [dbo].[Skocznie];


-- mamy inny wynik tego samego zapytania - 
-- wyst¹pi³ niepowtarzalny odczyt

COMMIT;

cleanUP;


--------------------------------------
-- Demo - Repeatable read
--------------------------------------

-- krok 11 - zabezpieczenie przez niepowtarzalnym odczytem 
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;


-- krok 12
BEGIN TRANSACTION;

-- pierwszy odczyt
SELECT max(punkt_K) FROM [dbo].[Skocznie];

-- sprawd¿my blokady
-- blokada nie zakoñczy³a siê po odczycie - jest ca³y czas aktywna
SELECT * FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;

-- krok 13 - powtórzyc krok 09 w drugiej sesji 

-- drugi odczyt daje ten sam rezultat
SELECT max(punkt_K)
FROM [dbo].[Skocznie];

COMMIT;

cleanUP;
go


--------------------------------------
-- Demo - Repeatable read
-- phantoms
--------------------------------------


-- krok 14 - ponownie ustawiamy tryb izolacji repeatable read
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRANSACTION;

SELECT * FROM [dbo].[Skocznie]
WHERE punkt_k > 180;

-- sprawdŸmy blokady
SELECT * FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;

-- krok 15 w drugiej sesji
  

-- krok 16 ponownie odczytujemy dane z tabeli
SELECT * FROM [dbo].[Skocznie]
WHERE punkt_k > 180;

-- pojawi³y siê dodatkowe wiersze spe³niaj¹ce warunki filtrowania
-- phantom rows


--krok 17 wycofujemy transakcjê
ROLLBACK;



cleanUP;

--------------------------------------
-- Demo - Serializable
--------------------------------------

-- krok 18 - ustawiamy poziom izolacji Serializable
-- i powtarzamy poprzedni scenariusz
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRANSACTION;

SELECT * FROM [dbo].[Skocznie]
WHERE punkt_k > 180;

SELECT *
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;


-- krok 19 w drugiej sesji 

-- krok 20 ponowny odczyt
SELECT * FROM [dbo].[Skocznie]
WHERE punkt_k > 180;


-- krok 21  wycofujemy transakcjê - insert z kroku 19 wykona³ siê 
-- po zwolnieniu blokady na tabeli
ROLLBACK;
GO


cleanUP;


-- krok 22 - ustawiamy poziom izolacji Serializable
-- i powtarzamy poprzedni scenariusz
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRANSACTION;

SELECT * FROM [dbo].[Skocznie]
WHERE punkt_k > 180;

SELECT *
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;


-- krok 23 w drugiej sesji 

-- krok 24 ponowny odczyt - zero zmian
SELECT * FROM [dbo].[Skocznie]
WHERE punkt_k > 180;


-- krok 25  wycofujemy transakcjê - insert z kroku 23 wykona³ siê 
-- po zwolnieniu blokady na tabeli
ROLLBACK;
GO

cleanUP;




------------------------------------------
-- Demo Read Committed Snapshot (RCSI)
-- w³¹czenie RCSI wymaga zamkniêcia pozosta³ych sesji na bazie
------------------------------------------

-- krok 26 - w³¹czamy optymistyczne poziomy izolacji
ALTER DATABASE DemoDB


-- RCSI
SET read_committed_snapshot ON 
WITH no_wait;


-- snapshot
ALTER DATABASE DemoDB
SET allow_snapshot_isolation ON;

-- krok 27 - testujemy RCSI
SELECT * FROM [dbo].[Skocznie];

BEGIN TRANSACTION;

UPDATE Skocznie 
SET punkt_K = 250
WHERE ID = 2;


-- krok 29 zapisujemy zmiany i przechodzimy do kroku 30 w drugiej sesji
COMMIT;


cleanUP;


------------------------------------------
-- Demo Snapshot 
------------------------------------------

-- krok 30 odczytujemy i zmieniamy wiersz 
BEGIN TRANSACTION;

SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;
	
UPDATE Skocznie 
SET punkt_K = 250
WHERE ID = 2;

-- krok 31 w drugiej sesji

-- krok 32 zapisujemy zmiany
COMMIT;
-- krok 33 w drugiej sesji

 
cleanUP;

------------------------------------------
-- Demo Snapshot - Update conflict
------------------------------------------

-- krok 35 zmieniamy wiersz w tabeli
BEGIN TRANSACTION;

UPDATE Skocznie 
SET punkt_K = 250
WHERE ID = 2;

SELECT * FROM [dbo].[Skocznie]
WHERE ID = 2;


commit;
-- krok 36 w drugiej sesji





------------------------------------------
-- Demo Snapshot - Update conflict - rozwi¹zanie 
------------------------------------------
cleanUP;

-- krok 38 - próbujemy zmieniæ wiersz
BEGIN TRANSACTION;

UPDATE Skocznie 
SET punkt_K = 300
WHERE ID = 2;

-- mamy blokadê na obiekcie....
-- krok 39 w drugiej sesji

--krok 40 odczytujemy ponownie dane
--odczytujemy zmiany wprowadzone w drugiej sesji
SELECT * FROM [dbo].[Skocznie] 
WHERE ID = 2;
	
-- krok 41 zapisujemy wynik transakcji
COMMIT;


SELECT * FROM [dbo].[Skocznie] 
WHERE ID = 2;


