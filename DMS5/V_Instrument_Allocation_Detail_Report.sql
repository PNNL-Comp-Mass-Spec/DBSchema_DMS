/****** Object:  View [dbo].[V_Instrument_Allocation_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Allocation_Detail_Report]
AS
SELECT PivotQ.fy_proposal,
       PivotQ.Fiscal_Year AS fiscal_year,
       PivotQ.proposal_id,
       PivotQ.[FT]  AS ft_hours,
       CommentQ.FT  AS ft_comment,
       PivotQ.[IMS] AS ims_hours,
       CommentQ.IMS AS ims_comment,
       PivotQ.[ORB] AS orbitrap_hours,
       CommentQ.ORB AS orbi_comment,
       PivotQ.[EXA] AS exactive_hours,
       CommentQ.EXA AS exactive_comment,
       PivotQ.[LTQ] AS ltq_hours,
       CommentQ.LTQ AS ltq_comment,
       PivotQ.[GC]  AS gc_hours,
       CommentQ.GC  AS gc_comment,
       PivotQ.[QQQ] AS qqq_hours,
       CommentQ.QQQ AS qqq_comment,
       UpdatedQ.last_updated
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
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
