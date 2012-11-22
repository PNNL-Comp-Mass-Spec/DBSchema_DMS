/****** Object:  Table [dbo].[T_Protein_Collection_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Collection_Usage](
	[Protein_Collection_ID] [int] NOT NULL,
	[Name] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Job_Usage_Count] [int] NULL,
	[Job_Usage_Count_Last12Months] [int] NULL,
	[Most_Recently_Used] [datetime] NULL,
 CONSTRAINT [PK_T_Protein_Collection_Usage] PRIMARY KEY CLUSTERED 
(
	[Protein_Collection_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Protein_Collection_Usage_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Protein_Collection_Usage_Name] ON [dbo].[T_Protein_Collection_Usage] 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
