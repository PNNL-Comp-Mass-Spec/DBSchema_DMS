/****** Object:  View [dbo].[V_Bionet_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_Detail_Report]
AS
SELECT H.host,
       H.ip,
       '255.255.254.0' AS subnet_mask,
       '(leave blank)' AS default_gateway,
       '192.168.30.68' AS dns_server,
       H.alias,
       H.tag,
       H.entered,
       H.Last_Online AS last_online,
       H.comment,
       H.instruments,
       H.Instruments AS instrument_datasets,
       InstName.IN_Room_Number AS room,
       T_YesNo.Description AS active
FROM T_Bionet_Hosts H
     INNER JOIN T_YesNo
       ON H.Active = T_YesNo.Flag
     LEFT OUTER JOIN T_Instrument_Name InstName
       ON H.Instruments = InstName.IN_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
