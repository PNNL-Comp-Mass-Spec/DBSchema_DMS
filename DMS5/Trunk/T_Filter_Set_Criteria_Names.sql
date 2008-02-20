/****** Object:  Table [dbo].[T_Filter_Set_Criteria_Names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Filter_Set_Criteria_Names](
	[Criterion_ID] [int] IDENTITY(1,1) NOT NULL,
	[Criterion_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Criterion_Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Filter_Set_Criteria_Names] PRIMARY KEY CLUSTERED 
(
	[Criterion_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
