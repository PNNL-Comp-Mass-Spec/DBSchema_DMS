/****** Object:  View [dbo].[V_Instrument_Allocation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allocation_List_Report]
AS
SELECT  TAL.fiscal_year,
        TAL.proposal_id,
        CONVERT(VARCHAR(32), T_EUS_Proposals.TITLE) + '...' AS title,
        T_EUS_Proposal_State_Name.Name AS status,
        TZ.general,
        TAL.ft,
        TAL.ims,
        TAL.orb,
        TAL.exa,
        TAL.ltq,
        TAL.gc,
        TAL.qqq,
        TAL.Last_Affected AS last_updated,
        TAL.FY_Proposal AS fy_proposal
FROM    ( SELECT    Fiscal_Year ,
                    Proposal_ID ,
                    SUM(CASE WHEN Allocation_Tag = 'FT' THEN Allocated_Hours
                             ELSE 0
                        END) AS FT ,
                    SUM(CASE WHEN Allocation_Tag = 'IMS' THEN Allocated_Hours
                             ELSE 0
                        END) AS IMS ,
                    SUM(CASE WHEN Allocation_Tag = 'ORB' THEN Allocated_Hours
                             ELSE 0
                        END) AS ORB ,
                    SUM(CASE WHEN Allocation_Tag = 'EXA' THEN Allocated_Hours
                             ELSE 0
                        END) AS EXA ,
                    SUM(CASE WHEN Allocation_Tag = 'LTQ' THEN Allocated_Hours
                             ELSE 0
                        END) AS LTQ ,
                    SUM(CASE WHEN Allocation_Tag = 'GC' THEN Allocated_Hours
                             ELSE 0
                        END) AS GC ,
                    SUM(CASE WHEN Allocation_Tag = 'QQQ' THEN Allocated_Hours
                             ELSE 0
                        END) AS QQQ ,
                    MAX(Last_Affected) AS Last_Affected ,
                    FY_Proposal
          FROM      T_Instrument_Allocation
          GROUP BY  Proposal_ID ,
                    Fiscal_Year ,
                    FY_Proposal
        ) AS TAL
        LEFT OUTER JOIN T_EUS_Proposal_State_Name
        INNER JOIN T_EUS_Proposals ON T_EUS_Proposal_State_Name.ID = T_EUS_Proposals.State_ID ON TAL.Proposal_ID = T_EUS_Proposals.PROPOSAL_ID
        LEFT OUTER JOIN ( SELECT Comment AS General,
                                 Fiscal_Year ,
                                 Proposal_ID
                          FROM T_Instrument_Allocation AS TIA
                          WHERE Allocation_Tag = 'General'
                        ) AS TZ ON TZ.Fiscal_Year = TAL.Fiscal_Year AND
                                   TZ.Proposal_ID = TAL.Proposal_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_List_Report] TO [DDL_Viewer] AS [dbo]
GO
