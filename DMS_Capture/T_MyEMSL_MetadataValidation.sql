/****** Object:  Table [dbo].[T_MyEMSL_MetadataValidation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MyEMSL_MetadataValidation](
	[StatusDate] [datetime] NOT NULL,
	[EntryID] [int] NOT NULL,
	[Job] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[Subfolder] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StatusNum] [int] NOT NULL,
	[TransactionID] [int] NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Files] [smallint] NOT NULL,
	[FilesInMyEMSL] [smallint] NOT NULL,
	[Bytes] [bigint] NOT NULL,
	[BytesInMyEMSL] [bigint] NOT NULL,
	[MatchRatio] [real] NOT NULL,
	[Comment] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_MyEMSL_MetadataValidation] PRIMARY KEY CLUSTERED 
(
	[EntryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_MyEMSL_MetadataValidation_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_MetadataValidation_DatasetID] ON [dbo].[T_MyEMSL_MetadataValidation]
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_MetadataValidation_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_MetadataValidation_Job] ON [dbo].[T_MyEMSL_MetadataValidation]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_MetadataValidation_MatchRatio] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_MetadataValidation_MatchRatio] ON [dbo].[T_MyEMSL_MetadataValidation]
(
	[MatchRatio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
