/****** Object:  View [dbo].[V_Bionet_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Bionet_List_Report] 
AS 
SELECT Host,
       IP,
       Alias,
       Entered,
       Last_Online,
       CASE
           WHEN Len(Instruments) > 70 THEN Cast(Instruments AS varchar(66)) + ' ...'
           ELSE Instruments
       END AS Instruments
FROM T_Bionet_Hosts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Bionet_List_Report] TO [PNL\D3M578] AS [dbo]
GO
