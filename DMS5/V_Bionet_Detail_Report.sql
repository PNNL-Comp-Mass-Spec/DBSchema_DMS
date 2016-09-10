/****** Object:  View [dbo].[V_Bionet_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_Detail_Report]
AS
SELECT H.Host,
       H.IP,
	   '255.255.254.0' AS [Subnet Mask],
	   '(leave blank)' AS [Default Gateway],
	   '192.168.30.68' AS [DNS Server],
       H.Alias,
	   H.Tag,
       H.Entered,
       H.Last_Online AS [Last Online],
	   H.Instruments,
	   H.Instruments AS [Instrument Datasets],
	   InstName.IN_Room_Number AS [Room],
	   T_YesNo.Description AS Active
FROM T_Bionet_Hosts H
     INNER JOIN T_YesNo
       ON H.Active = T_YesNo.Flag
     LEFT OUTER JOIN T_Instrument_Name InstName
       ON H.Instruments = InstName.IN_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
