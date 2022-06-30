/****** Object:  View [dbo].[V_Storage_Crosstab_Dataset_Size] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_Crosstab_Dataset_Size]
AS
SELECT PivotData.VolClient,
       IsNull([21T], 0) AS [21T],
       IsNull([Agilent_GC-MS], 0) AS Agilent_GCMS,
       IsNull([Agilent_QQQ], 0) AS Agilent_QQQ,
       IsNull([Agilent_TOF_V2], 0) AS Agilent_TOF_V2,
       IsNull([Bruker_FTMS], 0) AS Bruker_FTMS,
       IsNull([Eclipse], 0) AS Eclipse,
       IsNull([Exactive], 0) AS Exactive,
       IsNull([GC-QExactive], 0) AS GC_QExactive,
       IsNull([IMS], 0) AS IMS,
       IsNull([LCQ], 0) AS LCQ,
       IsNull([LTQ], 0) AS LTQ,
       IsNull([LTQ-ETD], 0) AS LTQ_ETD,
       IsNull([Lumos], 0) AS Lumos,
       IsNull([MALDI-Imaging], 0) AS MALDI_Imaging,
       IsNull([Orbitrap], 0) AS Orbitrap,
       IsNull([QEHFX], 0) AS QEHFX,
       IsNull([QExactive], 0) AS QExactive,
       IsNull([QExactive-Imaging], 0) AS QExactive_Imaging,
       IsNull([SLIM], 0) AS SLIM,
       IsNull([TSQ], 0) AS TSQ,
       IsNull([VelosOrbi], 0) AS VelosOrbi,
       IsNull([Waters_IMS], 0) AS Waters_IMS,
       IsNull([Waters_TOF], 0) as Waters_TOF
FROM (
	SELECT VolClient,
		   InstGroup,
		   File_Size_GB
	FROM V_Storage_Summary
	) AS SourceTable
	PIVOT (SUM(File_Size_GB)
	       FOR InstGroup 
	       IN ( [21T],
                [Agilent_GC-MS],
                [Agilent_QQQ],
                [Agilent_TOF_V2],
                [Bruker_FTMS],
                [Eclipse],
                [Exactive],
                [FT_ZippedSFolders],
                [GC-QExactive],
                [IMS],
                [LCQ],
                [LTQ],
                [LTQ-ETD],
                [Lumos],
                [MALDI-Imaging],
                [Orbitrap],
                [QEHFX],
                [QExactive],
                [QExactive-Imaging],
                [SLIM],
                [TSQ],
                [VelosOrbi],
                [Waters_IMS],
                [Waters_TOF]
				)
	) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Crosstab_Dataset_Size] TO [DDL_Viewer] AS [dbo]
GO
