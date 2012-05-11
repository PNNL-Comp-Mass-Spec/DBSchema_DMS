/****** Object:  Table [dbo].[T_protein_descriptions_new] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_protein_descriptions_new](
	[Description] [varchar](8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DateAdded] [datetime] NULL,
	[Reference_ID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

GO
