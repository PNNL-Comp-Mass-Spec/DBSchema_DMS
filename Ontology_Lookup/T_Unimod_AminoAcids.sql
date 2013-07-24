/****** Object:  Table [dbo].[T_Unimod_AminoAcids] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Unimod_AminoAcids](
	[Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Full_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MonoMass] [real] NOT NULL,
	[AvgMass] [real] NOT NULL,
	[Composition] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Three_Letter] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Unimod_AminoAcids] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
