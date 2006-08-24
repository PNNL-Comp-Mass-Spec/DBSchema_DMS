/****** Object:  View [dbo].[v_CDRequests_GetWeekly] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO






CREATE VIEW dbo.v_CDRequests_GetWeekly
AS
SELECT v_CDRequests_GetAllNew.*
FROM v_CDRequests_GetAllNew
WHERE (CDB_schedule = 'Weekly')
GO
