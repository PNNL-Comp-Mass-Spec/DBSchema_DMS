/****** Object:  Table [dbo].[T_Protein_Names_Revised] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Names_Revised](
	[Reference_ID] [int] NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Annotation_Type_ID] [int] NOT NULL,
	[Reference_Fingerprint] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DateAdded] [datetime] NULL,
	[Protein_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Protein_Names_Revised] PRIMARY KEY CLUSTERED 
(
	[Reference_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Protein_Names_Revised] ******/
CREATE NONCLUSTERED INDEX [IX_T_Protein_Names_Revised] ON [dbo].[T_Protein_Names_Revised] 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
