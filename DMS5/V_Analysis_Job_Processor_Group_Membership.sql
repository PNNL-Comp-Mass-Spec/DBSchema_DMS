/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Membership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Analysis_Job_Processor_Group_Membership]
AS
SELECT AJPGM.Group_ID,
       AJPG.Group_Name,
       AJPG.Group_Description,
       AJPG.Group_Enabled,
	   'Y' AS Available_For_General_Processing,
		-- Deprecated in February 2015; now always "Y"
		-- AJPG.Available_For_General_Processing,       
       AJPGM.Processor_ID,
       AJP.Processor_Name,
       AJP.State,
       AJP.Machine,
       AJP.Notes,
       AJPGM.Membership_Enabled,
       AJPGM.Last_Affected
FROM T_Analysis_Job_Processor_Group_Membership AJPGM
     INNER JOIN T_Analysis_Job_Processors AJP
       ON AJPGM.Processor_ID = AJP.ID
     INNER JOIN T_Analysis_Job_Processor_Group AJPG
       ON AJPGM.Group_ID = AJPG.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Membership] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Membership] TO [PNL\D3M580] AS [dbo]
GO
