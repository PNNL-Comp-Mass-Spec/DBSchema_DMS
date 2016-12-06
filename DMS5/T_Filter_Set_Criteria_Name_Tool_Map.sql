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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Filter_Set_Criteria_Name_Tool_Map] TO [DDL_Viewer] AS [dbo]
GO
