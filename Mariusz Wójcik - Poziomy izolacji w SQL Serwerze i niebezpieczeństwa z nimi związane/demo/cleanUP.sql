USE [DemoDB]
GO
/****** Object:  StoredProcedure [dbo].[ResetDB]    Script Date: 2019-02-11 10:49:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].cleanUP
AS
IF OBJECT_ID('dbo.Skocznie', 'U') IS NOT NULL
	DROP TABLE dbo.Skocznie;

CREATE TABLE Skocznie (
	ID INT
	,miasto NVARCHAR(20)
	,skocznia VARCHAR(20)
	,punkt_K INT
	);

INSERT Skocznie
VALUES (1,'Zakopane','Wielka Krokiew',125)
	,(2,'Planica','Letalnica',200)
	,(3,'Innsbruck','Bergisel',120)
	,(4,'Vikersund','Vikersundbakken',200)
	,(5,'Predazzo','Trampolino dal Ben',120)
