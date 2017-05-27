/****** Object:  Table [dbo].[T_Proteins] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Proteins](
	[Protein_ID] [int] IDENTITY(1,1) NOT NULL,
	[Sequence] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Length] [int] NOT NULL,
	[Molecular_Formula] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass] [float] NULL,
	[Average_Mass] [float] NULL,
	[SHA1_Hash] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DateCreated] [datetime] NULL,
	[DateModified] [datetime] NULL,
	[IsEncrypted] [tinyint] NULL,
	[SEGUID] [char](27) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Proteins] PRIMARY KEY CLUSTERED 
(
	[Protein_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Proteins_DateCreated] ******/
CREATE NONCLUSTERED INDEX [IX_T_Proteins_DateCreated] ON [dbo].[T_Proteins]
(
	[DateCreated] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Proteins_SHA1_Hash] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Proteins_SHA1_Hash] ON [dbo].[T_Proteins]
(
	[SHA1_Hash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Proteins] ADD  CONSTRAINT [DF_T_Proteins_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [dbo].[T_Proteins] ADD  CONSTRAINT [DF_T_Proteins_DateModified]  DEFAULT (getdate()) FOR [DateModified]
GO
/****** Object:  Statistic [Statistic_Sequence] ******/
CREATE STATISTICS [Statistic_Sequence] ON [dbo].[T_Proteins]([Sequence])
GO
