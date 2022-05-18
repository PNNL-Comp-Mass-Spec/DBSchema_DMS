/****** Object:  View [dbo].[V_Instrument_Allocation_Detail_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allocation_Detail_Entry]
AS
SELECT PivotQ.fy_proposal,
       PivotQ.fiscal_year,
       PivotQ.proposal_id,
       PivotQ.[ft],
       CommentQ.FT  AS ft_comment,
       PivotQ.[ims],
       CommentQ.IMS AS ims_comment,
       PivotQ.[orb],
       CommentQ.ORB AS orb_comment,
       PivotQ.[exa],
       CommentQ.EXA AS exa_comment,
       PivotQ.[ltq],
       CommentQ.LTQ AS ltq_comment,
       PivotQ.[gc],
       CommentQ.GC  AS gc_comment,
       PivotQ.[qqq],
       CommentQ.QQQ AS qqq_comment
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


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_Detail_Entry] TO [DDL_Viewer] AS [dbo]
GO
