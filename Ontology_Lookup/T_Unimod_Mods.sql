/****** Object:  Table [dbo].[T_Unimod_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Unimod_Mods](
	[Unimod_ID] [int] NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Full_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Alternate_Names] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Notes] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MonoMass] [real] NOT NULL,
	[AvgMass] [real] NOT NULL,
	[Composition] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Date_Posted] [datetime] NOT NULL,
	[Date_Modified] [datetime] NOT NULL,
	[Approved] [smallint] NOT NULL,
	[Poster_Username] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Poster_Group] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[URL] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Unimod_Mods] PRIMARY KEY CLUSTERED 
(
	[Unimod_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
