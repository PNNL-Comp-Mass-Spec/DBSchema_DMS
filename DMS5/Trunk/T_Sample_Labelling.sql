/****** Object:  Table [dbo].[T_Sample_Labelling] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Labelling](
	[Label] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Sample_Labelling] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Sample_Labelling] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Sample_Labelling] ON [dbo].[T_Sample_Labelling] 
(
	[Label] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
