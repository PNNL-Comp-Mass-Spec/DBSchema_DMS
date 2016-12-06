/****** Object:  View [dbo].[V_EMSL_Allocated_Usage_By_Category] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EMSL_Allocated_Usage_By_Category as
SELECT        TX.Category, TIA.FY, TIA.Proposal_ID, SUM(TIA.Allocated_Hours) AS Total_Allocated_Hours
FROM            T_EMSL_Instrument_Allocation AS TIA INNER JOIN
                             (SELECT        EUS_Instrument_ID, CASE WHEN TEI.Local_Category_Name IS NULL 
                                                         THEN TEI.EUS_Display_Name ELSE TEI.Local_Category_Name END AS Category
                               FROM            T_EMSL_Instruments AS TEI) AS TX ON TX.EUS_Instrument_ID = TIA.EUS_Instrument_ID
GROUP BY TX.Category, TIA.Proposal_ID, TIA.FY

GO
GRANT VIEW DEFINITION ON [dbo].[V_EMSL_Allocated_Usage_By_Category] TO [DDL_Viewer] AS [dbo]
GO
