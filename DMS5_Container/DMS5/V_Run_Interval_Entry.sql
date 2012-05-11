/****** Object:  View [dbo].[V_Run_Interval_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Interval_Entry]
AS
SELECT ID,
       Instrument,
       Entered,
       Start,
       [Interval],
       [Comment]
FROM dbo.T_Run_Interval


GO
