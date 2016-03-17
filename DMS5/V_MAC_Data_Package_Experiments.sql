/****** Object:  View [dbo].[V_MAC_Data_Package_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MAC_Data_Package_Experiments]
AS
SELECT Data_Package_ID,
       Experiment_ID,
       Experiment,
       Created,
       [Item Added],
       [Package Comment]
FROM S_V_Data_Package_Experiments_Export


GO
GRANT VIEW DEFINITION ON [dbo].[V_MAC_Data_Package_Experiments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MAC_Data_Package_Experiments] TO [PNL\D3M580] AS [dbo]
GO
