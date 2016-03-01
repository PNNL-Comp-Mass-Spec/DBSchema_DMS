/****** Object:  Table [dbo].[T_NCBI_Import] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_NCBI_Import](
	[Tax_ID] [int] NULL,
	[Tax_Name] [varchar](220) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Unique_Name] [varchar](140) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Name_Class] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
