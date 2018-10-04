/****** Object:  View [dbo].[V_Bionet_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_List_Report] 
AS 
SELECT H.Host,
       H.IP,
       H.Alias,
       H.Tag,
       H.Entered,
       H.Last_Online,
       H.Comment,
       CASE
           WHEN Len(H.Instruments) > 70 THEN Cast(H.Instruments AS varchar(66)) + ' ...'
           ELSE H.Instruments
       END AS Instruments,
       T_YesNo.Description AS Active
FROM T_Bionet_Hosts H
     INNER JOIN T_YesNo
       ON H.Active = T_YesNo.Flag


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_List_Report] TO [DDL_Viewer] AS [dbo]
GO
