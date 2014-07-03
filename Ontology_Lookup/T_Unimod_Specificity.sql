/****** Object:  Table [dbo].[T_Unimod_Specificity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Unimod_Specificity](
	[Unimod_ID] [int] NOT NULL,
	[Specificity_EntryID] [smallint] NOT NULL,
	[Specificity_Group_ID] [smallint] NOT NULL,
	[Site] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Position] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Classification] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Notes] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Hidden] [smallint] NOT NULL,
 CONSTRAINT [PK_T_Unimod_Specificity] PRIMARY KEY CLUSTERED 
(
	[Unimod_ID] ASC,
	[Specificity_EntryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
