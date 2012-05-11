/****** Object:  View [dbo].[V_Stalled_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Stalled_Processors]
AS
SELECT ID,
       Processor_Name,
       State,
       Groups,
       GP_Groups,
       Machine,
       Latest_Request
FROM dbo.T_Local_Processors
WHERE (Latest_Request >= '12/1/2008') AND
      (Latest_Request < DATEADD(hour, -12, GETDATE()))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Stalled_Processors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Stalled_Processors] TO [PNL\D3M580] AS [dbo]
GO
