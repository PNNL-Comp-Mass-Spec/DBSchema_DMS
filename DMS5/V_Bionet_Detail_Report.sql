/****** Object:  View [dbo].[V_Bionet_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_Detail_Report]
AS
SELECT Host,
       IP,
	   '255.255.254.0' AS [Subnet Mask],
	   '(leave blank)' AS [Default Gateway],
	   '192.168.30.68' AS [DNS Server],
       Alias,
       Entered,
       Last_Online AS [Last Online],
	   Instruments,
	   Instruments AS [Instrument Datasets]
FROM T_Bionet_Hosts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
