/****** Object:  View [dbo].[V_Bionet_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_List_Report]
AS
SELECT H.host,
       H.ip,
       H.alias,
       H.tag,
       H.entered,
       H.last_online,
       H.comment,
       CASE
           WHEN Len(H.Instruments) > 70 THEN Cast(H.Instruments AS varchar(66)) + ' ...'
           ELSE H.instruments
       END AS instruments,
       T_YesNo.Description AS active
FROM T_Bionet_Hosts H
     INNER JOIN T_YesNo
       ON H.Active = T_YesNo.Flag


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_List_Report] TO [DDL_Viewer] AS [dbo]
GO
