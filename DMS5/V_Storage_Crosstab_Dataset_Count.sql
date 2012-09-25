/****** Object:  View [dbo].[V_Storage_Crosstab_Dataset_Count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Storage_Crosstab_Dataset_Count
AS
SELECT PivotData.VolClient,
		IsNull([LTQ], 0) AS [LTQ],
		IsNull([Micromass_TOF], 0) AS [Micromass_TOF],
		IsNull([VelosOrbi], 0) AS [VelosOrbi],
		IsNull([FT_ZippedSFolders], 0) AS [FT_ZippedSFolders],
		IsNull([LTQ-ETD], 0) AS [LTQ-ETD],
		IsNull([TSQ], 0) AS [TSQ],
		IsNull([Orbitrap-HCD], 0) AS [Orbitrap-HCD],
		IsNull([LTQ-FT], 0) AS [LTQ-FT],
		IsNull([Agilent_TOF], 0) AS [Agilent_TOF],
		IsNull([Orbitrap], 0) AS [Orbitrap],
		IsNull([Other], 0) AS [Other],
		IsNull([IMS], 0) AS [IMS],
		IsNull([Agilent_Ion_Trap], 0) AS [Agilent_Ion_Trap],
		IsNull([LCQ], 0) AS [LCQ],
		IsNull([Exactive], 0) AS [Exactive]
FROM (
	SELECT VolClient,
		   InstGroup,
		   Datasets
	FROM V_Storage_Summary
	) AS SourceTable
	PIVOT (SUM(Datasets)
	       FOR InstGroup
	       IN ( [LTQ],
				[Orbitrap],
				[TSQ],
				[LCQ],
				[Other],
				[Exactive],
				[VelosOrbi],
				[Agilent_Ion_Trap],
				[IMS],
				[LTQ-FT],
				[Orbitrap-HCD],
				[LTQ-ETD],
				[Agilent_TOF],
				[FT_ZippedSFolders],
				[Micromass_TOF]
				)
	) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Crosstab_Dataset_Count] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Crosstab_Dataset_Count] TO [PNL\D3M580] AS [dbo]
GO
