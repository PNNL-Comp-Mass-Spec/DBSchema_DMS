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
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_Entry] TO [PNL\D3M578] AS [dbo]
GO
