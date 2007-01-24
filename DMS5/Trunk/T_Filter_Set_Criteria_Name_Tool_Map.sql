/****** Object:  Table [dbo].[T_Filter_Set_Criteria_Name_Tool_Map] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Filter_Set_Criteria_Name_Tool_Map](
	[Criterion_ID] [int] NOT NULL,
	[Analysis_Tool_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Filter_Set_Criteria_Name_Tool_Map] PRIMARY KEY CLUSTERED 
(
	[Criterion_ID] ASC,
	[Analysis_Tool_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
