/****** Object:  Table [dbo].[T_MyEMSL_MetadataValidation_Part2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MyEMSL_MetadataValidation_Part2](
	[StatusDate] [datetime] NOT NULL,
	[EntryID] [int] NOT NULL,
	[Job] [int] NOT NULL,
	[DatasetID] [int] NOT NULL,
	[Subfolder] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StatusNum] [int] NOT NULL,
	[TransactionID] [int] NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Files] [smallint] NOT NULL,
	[FilesInMyEMSL] [smallint] NOT NULL,
	[Bytes] [bigint] NOT NULL,
	[BytesInMyEMSL] [bigint] NOT NULL,
	[MatchRatio] [real] NOT NULL,
	[Comment] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_MyEMSL_MetadataValidation_Part2] PRIMARY KEY CLUSTERED 
(
	[EntryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
