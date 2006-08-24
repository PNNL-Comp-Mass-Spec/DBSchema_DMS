/****** Object:  Table [dbo].[T_DatasetRatingName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DatasetRatingName](
	[DRN_state_ID] [smallint] NOT NULL,
	[DRN_name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_DatasetRatingName] PRIMARY KEY CLUSTERED 
(
	[DRN_state_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
