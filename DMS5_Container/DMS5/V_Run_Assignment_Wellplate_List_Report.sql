/****** Object:  View [dbo].[V_Run_Assignment_Wellplate_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW dbo.V_Run_Assignment_Wellplate_List_Report
AS
Select 
M.[Well Plate], 
W.WP_Description AS Description,
M.Scheduled, 
M.Requested
FROM
(
SELECT
	RDS_Well_Plate_Num AS [Well Plate], 
	SUM(CASE WHEN RDS_priority > 0 THEN 1 ELSE 0 END) AS Scheduled, 
	SUM(CASE WHEN RDS_priority = 0 THEN 1 ELSE 0 END) AS Requested
FROM T_Requested_Run
GROUP BY RDS_Well_Plate_Num
) M 
LEFT OUTER JOIN
T_Wellplates W ON M.[Well Plate] = W.WP_Well_Plate_Num



GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Assignment_Wellplate_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Assignment_Wellplate_List_Report] TO [PNL\D3M580] AS [dbo]
GO
