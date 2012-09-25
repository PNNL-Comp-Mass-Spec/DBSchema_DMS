/****** Object:  View [dbo].[V_Instrument_Allocation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Instrument_Allocation_List_Report as
SELECT TAL.Fiscal_Year,
       TAL.Proposal_ID,
       CONVERT(varchar(32), T_EUS_Proposals.TITLE) + '...' AS Title,
       T_EUS_Proposal_State_Name.Name AS Status,
       TAL.FT,
       TAL.IMS,
       TAL.ORB,
       TAL.EXA,
       TAL.LTQ,
       TAL.GC,
       TAL.QQQ,
       TAL.Last_Affected AS Last_Updated,
       TAL.FY_Proposal AS [#FY_Proposal]
FROM T_EUS_Proposal_State_Name
     INNER JOIN T_EUS_Proposals
       ON T_EUS_Proposal_State_Name.ID = T_EUS_Proposals.State_ID
     RIGHT OUTER JOIN ( SELECT Fiscal_Year,
                               Proposal_ID,
                               SUM(CASE WHEN Allocation_Tag = 'FT' THEN Allocated_Hours ELSE 0 END) AS FT, 
                               SUM(CASE WHEN Allocation_Tag = 'IMS' THEN Allocated_Hours ELSE 0 END) AS IMS, 
                               SUM(CASE WHEN Allocation_Tag = 'ORB' THEN Allocated_Hours ELSE 0 END) AS ORB, 
                               SUM(CASE WHEN Allocation_Tag = 'EXA' THEN Allocated_Hours ELSE 0 END) AS EXA, 
                               SUM(CASE WHEN Allocation_Tag = 'LTQ' THEN Allocated_Hours ELSE 0 END) AS LTQ, 
                               SUM(CASE WHEN Allocation_Tag = 'GC' THEN Allocated_Hours ELSE 0 END) AS GC, 
                               SUM(CASE WHEN Allocation_Tag = 'QQQ' THEN Allocated_Hours ELSE 0 END) AS QQQ,
                               MAX(Last_Affected) AS Last_Affected,
                               FY_Proposal
                        FROM T_Instrument_Allocation
                        GROUP BY Proposal_ID, Fiscal_Year, FY_Proposal ) AS TAL
       ON T_EUS_Proposals.PROPOSAL_ID = TAL.Proposal_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_List_Report] TO [PNL\D3M580] AS [dbo]
GO
