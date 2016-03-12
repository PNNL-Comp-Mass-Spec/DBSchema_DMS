/****** Object:  View [dbo].[V_Instrument_Allocation_Detail_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allocation_Detail_Entry]
AS
SELECT PivotQ.FY_Proposal,
       PivotQ.Fiscal_Year,
       PivotQ.Proposal_ID,
       PivotQ.[FT],
       CommentQ.FT  AS FTComment,
       PivotQ.[IMS],
       CommentQ.IMS AS IMSComment,
       PivotQ.[ORB],
       CommentQ.ORB AS ORBComment,
       PivotQ.[EXA],
       CommentQ.EXA AS EXAComment,
       PivotQ.[LTQ],
       CommentQ.LTQ AS LTQComment,
       PivotQ.[GC],
       CommentQ.GC  AS GCComment,
       PivotQ.[QQQ],
       CommentQ.QQQ AS QQQComment
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
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allocation_Detail_Entry] TO [PNL\D3M578] AS [dbo]
GO
