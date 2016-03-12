/****** Object:  View [dbo].[V_Instrument_Usage_Report_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* */
CREATE VIEW dbo.V_Instrument_Usage_Report_List_Report
AS
SELECT        Seq, EMSL_Inst_ID AS [EMSL Inst ID], Instrument, Type, Start, Minutes, Proposal, Usage, Users, Operator, Comment, Year, Month, ID, 
                         dbo.CheckEMSLUsageItemValidity(Seq) AS Validation
FROM            dbo.T_EMSL_Instrument_Usage_Report

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Usage_Report_List_Report] TO [PNL\D3M578] AS [dbo]
GO
