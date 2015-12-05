/****** Object:  View [dbo].[V_Bionet_Hosts_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Bionet_Hosts_Export
AS
SELECT 	Host,
		IP,
		Alias,
		Entered,
		Last_Online,
		Instruments
FROM T_Bionet_Hosts
WHERE Active > 0

GO
