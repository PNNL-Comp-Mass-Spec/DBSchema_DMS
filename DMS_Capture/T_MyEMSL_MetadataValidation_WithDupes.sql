/****** Object:  Table [dbo].[T_MyEMSL_MetadataValidation_WithDupes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MyEMSL_MetadataValidation_WithDupes](
	[StatusDate] [datetime] NULL,
	[EntryID] [int] NULL,
	[Job] [int] NULL,
	[DatasetID] [int] NULL,
	[Subfolder] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StatusNum] [int] NULL,
	[TransactionID] [int] NULL,
	[Entered] [datetime] NULL,
	[Files] [smallint] NULL,
	[FilesInMyEMSL] [smallint] NULL,
	[Bytes] [bigint] NULL,
	[BytesInMyEMSL] [bigint] NULL,
	[MatchRatio] [real] NULL,
	[Comment] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
