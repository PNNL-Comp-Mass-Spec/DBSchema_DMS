/****** Object:  Table [dbo].[T_Unimod_Specificity_NL] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Unimod_Specificity_NL](
	[Unimod_ID] [int] NOT NULL,
	[Specificity_EntryID] [smallint] NOT NULL,
	[NeutralLoss_EntryID] [smallint] NOT NULL,
	[MonoMass] [real] NOT NULL,
	[AvgMass] [real] NOT NULL,
	[Composition] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Flag] [bit] NOT NULL,
 CONSTRAINT [PK_T_Unimod_Specificity_NL] PRIMARY KEY CLUSTERED 
(
	[Unimod_ID] ASC,
	[Specificity_EntryID] ASC,
	[NeutralLoss_EntryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
