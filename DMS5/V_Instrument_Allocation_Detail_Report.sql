/****** Object:  View [dbo].[V_Instrument_Allocation_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allocation_Detail_Report]
AS
SELECT PivotQ.FY_Proposal,
       PivotQ.Fiscal_Year AS [Fiscal Year],
       PivotQ.Proposal_ID,
       PivotQ.[FT]  AS [FT Hours],
       CommentQ.FT  AS [FT Comment],
       PivotQ.[IMS] AS [IMS Hours],
       CommentQ.IMS AS [IMS Comment],
       PivotQ.[ORB] AS [Orbitrap Hours],
       CommentQ.ORB AS [Orbi Comment],
       PivotQ.[EXA] AS [Exactive Hours],
       CommentQ.EXA AS [Exactive Comment],
       PivotQ.[LTQ] AS [LTQ Hours],
       CommentQ.LTQ AS [LTQ Comment],
       PivotQ.[GC]  AS [GC Hours],
       CommentQ.GC  AS [GC Comment],
       PivotQ.[QQQ] AS [QQQ Hours],
       CommentQ.QQQ AS [QQQ Comment],
       UpdatedQ.Last_Updated
FROM ( SELECT FY_Proposal,
              Fiscal_Year,
              Proposal_ID,
              IsNull([FT], 0) AS [FT],
              IsNull([IMS], 0) AS [IMS],
              IsNull([ORB], 0) AS [ORB],
              IsNull([EXA], 0) AS [EXA],
              IsNull([LTQ], 0) AS [LTQ],
              IsNull([GC], 0) AS [GC],
              IsNull([QQQ], 0) AS [QQQ]
       FROM ( SELECT FY_Proposal,
                     Fiscal_Year,
                     Proposal_ID,
                     Allocation_Tag,
                     Allocated_Hours
              FROM T_Instrument_Allocation ) AS SourceTable
            PIVOT ( Sum(Allocated_Hours)
                    FOR Allocation_Tag
                    IN ( [FT], [IMS], [ORB], [EXA], [LTQ], [GC], [QQQ] ) ) AS PivotData 
     ) PivotQ
     LEFT OUTER JOIN
     ( SELECT FY_Proposal,
              [FT] ,
              [IMS],
              [ORB],
              [EXA],
              [LTQ],
              [GC] ,
              [QQQ]
       FROM ( SELECT FY_Proposal,
                     Fiscal_Year,
                     Proposal_ID,
                     Allocation_Tag,
                     Comment
              FROM T_Instrument_Allocation ) AS SourceTable
            PIVOT ( MAX(Comment)
                    FOR Allocation_Tag
                    IN ( [FT], [IMS], [ORB], [EXA], [LTQ], [GC], [QQQ] ) ) AS PivotData 
     ) CommentQ
       ON PivotQ.FY_Proposal = CommentQ.FY_Proposal
	LEFT OUTER JOIN ( SELECT FY_Proposal,
                              Max(Last_Affected) as Last_Updated
                       FROM T_Instrument_Allocation
                       GROUP BY FY_Proposal)  UpdatedQ
       ON PivotQ.FY_Proposal = UpdatedQ.FY_Proposal

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
